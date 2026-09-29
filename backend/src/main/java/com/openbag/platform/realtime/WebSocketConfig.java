package com.openbag.platform.realtime;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.ChannelRegistration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketTransportRegistration;

/**
 * WebSocket STOMP em /api/ws. Tópicos:
 * - /topic/restaurants/{id}/orders: pedidos do restaurante (gestor e cozinha)
 * - /topic/orders/{id}: acompanhamento de um pedido pelo cliente
 * A autenticação é pelo JWT no frame CONNECT (ver {@link StompAuthInterceptor}).
 */
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Autowired
    private StompAuthInterceptor stompAuthInterceptor;

    @Autowired
    private StompSessionRegistry sessionRegistry;

    /** As mesmas origens do CORS (app.cors.allowed-origins) */
    @Value("${app.cors.allowed-origins}")
    private String[] allowedOrigins;

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws").setAllowedOriginPatterns(allowedOrigins);
    }

    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        registry.enableSimpleBroker("/topic")
                // Heartbeat para detectar conexões mortas (tablet da cozinha que perdeu a rede)
                .setHeartbeatValue(new long[]{10000, 10000})
                .setTaskScheduler(heartbeatScheduler());
        registry.setApplicationDestinationPrefixes("/app");
    }

    @Override
    public void configureClientInboundChannel(ChannelRegistration registration) {
        registration.interceptors(stompAuthInterceptor);
        // Os clientes só conectam e se inscrevem: poucas threads bastam, e uma enxurrada de frames não cresce sem fim
        registration.taskExecutor().corePoolSize(2).maxPoolSize(8).queueCapacity(1000);
    }

    @Override
    public void configureClientOutboundChannel(ChannelRegistration registration) {
        registration.taskExecutor().corePoolSize(4).maxPoolSize(16).queueCapacity(10_000);
    }

    /**
     * Limites por sessão. O cliente só manda CONNECT e SUBSCRIBE (frames pequenos). Um cliente lento que não lê as
     * mensagens é desconectado quando o buffer enche ou o envio demora, em vez de segurar memória do servidor.
     */
    @Override
    public void configureWebSocketTransport(WebSocketTransportRegistration registration) {
        registration.setMessageSizeLimit(8 * 1024)
                .setSendBufferSizeLimit(512 * 1024)
                .setSendTimeLimit(15_000)
                .addDecoratorFactory(sessionRegistry);
    }

    private org.springframework.scheduling.concurrent.ThreadPoolTaskScheduler heartbeatScheduler() {
        var scheduler = new org.springframework.scheduling.concurrent.ThreadPoolTaskScheduler();
        scheduler.setPoolSize(1);
        scheduler.setThreadNamePrefix("ws-heartbeat-");
        scheduler.initialize();
        return scheduler;
    }
}
