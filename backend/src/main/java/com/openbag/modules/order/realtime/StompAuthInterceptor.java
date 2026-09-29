package com.openbag.modules.order.realtime;

import com.openbag.modules.shared.service.AuthorizationService;
import com.openbag.security.CustomUserDetailsService;
import com.openbag.security.JwtTokenProvider;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.MessagingException;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;

import java.security.Principal;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Autentica a sessão STOMP pelo JWT enviado no CONNECT (header Authorization)
 * e autoriza cada SUBSCRIBE: só o dono do restaurante (ou ADMIN) ouve os pedidos do restaurante,
 * e só quem pode ver o pedido ouve as atualizações dele.
 */
@Component
@Slf4j
public class StompAuthInterceptor implements ChannelInterceptor {

    private static final Pattern RESTAURANT_TOPIC = Pattern.compile("^/topic/restaurants/(\\d+)/orders$");
    private static final Pattern ORDER_TOPIC = Pattern.compile("^/topic/orders/(\\d+)$");
    private static final Pattern COURIER_TOPIC = Pattern.compile("^/topic/couriers/(\\d+)$");

    @Autowired
    private JwtTokenProvider tokenProvider;

    @Autowired
    private CustomUserDetailsService userDetailsService;

    @Autowired
    private AuthorizationService authorizationService;

    @Autowired
    private StompSessionRegistry sessions;

    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
        if (accessor == null || accessor.getCommand() == null) {
            return message;
        }

        if (StompCommand.CONNECT.equals(accessor.getCommand())) {
            String header = accessor.getFirstNativeHeader("Authorization");
            accessor.setUser(authenticate(header));
            // A sessão vale até o token vencer; depois disso ela é fechada e o app reconecta com o token atual
            sessions.expireAt(accessor.getSessionId(), tokenProvider.getExpirationFromJWT(header.substring(7)));
        } else if (StompCommand.SUBSCRIBE.equals(accessor.getCommand())) {
            authorizeSubscription(accessor.getUser(), accessor.getDestination());
        } else if (StompCommand.SEND.equals(accessor.getCommand())) {
            // Os clientes só escutam; nada é enviado pelo socket
            throw new MessagingException("Envio de mensagens não permitido");
        }
        return message;
    }

    private Principal authenticate(String header) {
        if (header == null || !header.startsWith("Bearer ")) {
            throw new MessagingException("Token ausente");
        }
        String token = header.substring(7);
        if (!tokenProvider.validateToken(token)) {
            throw new MessagingException("Token inválido");
        }
        UserDetails user = userDetailsService.loadUserById(tokenProvider.getUserIdFromJWT(token));
        if (!user.isEnabled()) {
            throw new MessagingException("Conta desativada");
        }
        return new UsernamePasswordAuthenticationToken(user, null, user.getAuthorities());
    }

    private void authorizeSubscription(Principal principal, String destination) {
        Long userId = userIdOf(principal);
        if (userId == null || destination == null) {
            throw new MessagingException("Não autenticado");
        }

        Matcher restaurant = RESTAURANT_TOPIC.matcher(destination);
        if (restaurant.matches() && authorizationService.canManageRestaurant(userId, Long.parseLong(restaurant.group(1)))) {
            return;
        }
        Matcher order = ORDER_TOPIC.matcher(destination);
        if (order.matches() && authorizationService.canViewOrder(userId, Long.parseLong(order.group(1)))) {
            return;
        }
        Matcher courier = COURIER_TOPIC.matcher(destination);
        if (courier.matches() && authorizationService.isDeliveryPersonUser(userId, Long.parseLong(courier.group(1)))) {
            return;
        }
        log.warn("Assinatura negada: usuário {} em {}", userId, destination);
        throw new MessagingException("Acesso negado a " + destination);
    }

    private Long userIdOf(Principal principal) {
        if (principal instanceof UsernamePasswordAuthenticationToken auth
                && auth.getPrincipal() instanceof CustomUserDetailsService.CustomUserPrincipal user) {
            return user.getId();
        }
        return null;
    }
}
