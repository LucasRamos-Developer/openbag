package com.openbag.platform.realtime;

import org.junit.jupiter.api.Test;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.WebSocketSession;

import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class StompSessionRegistryTest {

    private static WebSocketSession session(String id) {
        WebSocketSession session = mock(WebSocketSession.class);
        when(session.getId()).thenReturn(id);
        when(session.isOpen()).thenReturn(true);
        return session;
    }

    @Test
    void sessionsAreClosedWhenTheTokenExpires() throws Exception {
        StompSessionRegistry registry = new StompSessionRegistry();
        WebSocketHandler handler = registry.decorate(mock(WebSocketHandler.class));
        WebSocketSession expired = session("a");
        WebSocketSession valid = session("b");
        handler.afterConnectionEstablished(expired);
        handler.afterConnectionEstablished(valid);
        registry.expireAt("a", Instant.now().minusSeconds(1));
        registry.expireAt("b", Instant.now().plusSeconds(3600));

        registry.closeExpired();

        verify(expired).close(any(CloseStatus.class));
        verify(valid, never()).close(any(CloseStatus.class));
    }

    @Test
    void closedSessionsLeaveTheRegistry() throws Exception {
        StompSessionRegistry registry = new StompSessionRegistry();
        WebSocketHandler handler = registry.decorate(mock(WebSocketHandler.class));
        WebSocketSession session = session("a");
        handler.afterConnectionEstablished(session);

        handler.afterConnectionClosed(session, CloseStatus.NORMAL);

        assertThat(registry.openSessions()).isZero();
    }
}
