package com.openbag.modules.order.realtime;

import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.WebSocketHandlerDecorator;
import org.springframework.web.socket.handler.WebSocketHandlerDecoratorFactory;

import java.io.IOException;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Sessões abertas do WebSocket e até quando cada uma vale (a validade do token usado no CONNECT). A permissão do
 * SUBSCRIBE é conferida na inscrição; sem isso, uma sessão aberta continuaria recebendo atualizações depois de o
 * token vencer (ou de a conta ser desativada e o token deixar de ser renovado).
 */
@Component
@Slf4j
public class StompSessionRegistry implements WebSocketHandlerDecoratorFactory {

    private final Map<String, WebSocketSession> open = new ConcurrentHashMap<>();
    private final Map<String, Instant> expiresAt = new ConcurrentHashMap<>();

    @Override
    public WebSocketHandler decorate(WebSocketHandler handler) {
        return new WebSocketHandlerDecorator(handler) {
            @Override
            public void afterConnectionEstablished(WebSocketSession session) throws Exception {
                open.put(session.getId(), session);
                super.afterConnectionEstablished(session);
            }

            @Override
            public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
                open.remove(session.getId());
                expiresAt.remove(session.getId());
                super.afterConnectionClosed(session, status);
            }
        };
    }

    void expireAt(String sessionId, Instant when) {
        if (sessionId != null && when != null) {
            expiresAt.put(sessionId, when);
        }
    }

    int openSessions() {
        return open.size();
    }

    /** Fecha as sessões cujo token venceu; o app reconecta e, sem token válido, o CONNECT é recusado */
    @Scheduled(fixedDelayString = "${app.websocket.expiry-check-ms:60000}")
    void closeExpired() {
        Instant now = Instant.now();
        expiresAt.forEach((sessionId, when) -> {
            if (when.isBefore(now)) {
                WebSocketSession session = open.get(sessionId);
                expiresAt.remove(sessionId);
                if (session != null && session.isOpen()) {
                    try {
                        session.close(CloseStatus.POLICY_VIOLATION.withReason("Token vencido"));
                        log.info("WebSocket: sessão {} fechada (token vencido)", sessionId);
                    } catch (IOException e) {
                        log.debug("WebSocket: falha ao fechar a sessão {}", sessionId, e);
                    }
                }
            }
        });
    }
}
