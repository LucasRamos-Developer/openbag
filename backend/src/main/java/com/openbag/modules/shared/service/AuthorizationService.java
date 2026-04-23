package com.openbag.modules.shared.service;

import com.openbag.modules.user.entity.User;
import com.openbag.modules.restaurant.entity.Restaurant;
import com.openbag.modules.order.entity.Order;
import com.openbag.modules.organization.entity.Organization;
import com.openbag.modules.delivery.entity.DeliveryPerson;
import com.openbag.modules.user.repository.UserRepository;
import com.openbag.modules.restaurant.repository.RestaurantRepository;
import com.openbag.modules.order.repository.OrderRepository;
import com.openbag.modules.organization.repository.OrganizationRepository;
import com.openbag.modules.delivery.repository.DeliveryPersonRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Optional;

/**
 * Serviço de autorização contextual
 * Verifica permissões baseadas no contexto (ex: usuário é dono de um restaurante ESPECÍFICO)
 */
@Service("authorizationService")
@Slf4j
public class AuthorizationService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RestaurantRepository restaurantRepository;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private OrganizationRepository organizationRepository;

    @Autowired
    private DeliveryPersonRepository deliveryPersonRepository;

    /**
     * Verifica se o usuário pode gerenciar um restaurante específico
     * @param userId ID do usuário
     * @param restaurantId ID do restaurante
     * @return true se o usuário é dono do restaurante OU é ADMIN
     */
    public boolean canManageRestaurant(Long userId, Long restaurantId) {
        if (userId == null || restaurantId == null) {
            log.debug("userId ou restaurantId é null");
            return false;
        }

        try {
            Optional<User> userOpt = userRepository.findById(userId);
            if (userOpt.isEmpty()) {
                log.debug("Usuário {} não encontrado", userId);
                return false;
            }

            User user = userOpt.get();

            // ADMIN pode gerenciar qualquer restaurante
            if (user.hasRole("ADMIN")) {
                log.debug("Usuário {} é ADMIN, pode gerenciar restaurante {}", userId, restaurantId);
                return true;
            }

            // Verifica se o usuário é dono do restaurante
            Optional<Restaurant> restaurantOpt = restaurantRepository.findById(restaurantId);
            if (restaurantOpt.isEmpty()) {
                log.debug("Restaurante {} não encontrado", restaurantId);
                return false;
            }

            Restaurant restaurant = restaurantOpt.get();
            boolean isOwner = restaurant.getOwner() != null && restaurant.getOwner().getId().equals(userId);

            log.debug("Usuário {} {} dono do restaurante {}", 
                    userId, isOwner ? "é" : "não é", restaurantId);

            return isOwner;

        } catch (Exception e) {
            log.error("Erro ao verificar permissão de gerenciamento de restaurante", e);
            return false;
        }
    }

    /**
     * Verifica se o usuário pode visualizar/gerenciar um pedido específico
     * @param userId ID do usuário
     * @param orderId ID do pedido
     * @return true se o usuário é dono do pedido, dono do restaurante do pedido OU é ADMIN
     */
    public boolean canViewOrder(Long userId, Long orderId) {
        if (userId == null || orderId == null) {
            log.debug("userId ou orderId é null");
            return false;
        }

        try {
            Optional<User> userOpt = userRepository.findById(userId);
            if (userOpt.isEmpty()) {
                log.debug("Usuário {} não encontrado", userId);
                return false;
            }

            User user = userOpt.get();

            // ADMIN pode visualizar qualquer pedido
            if (user.hasRole("ADMIN")) {
                log.debug("Usuário {} é ADMIN, pode visualizar pedido {}", userId, orderId);
                return true;
            }

            Optional<Order> orderOpt = orderRepository.findById(orderId);
            if (orderOpt.isEmpty()) {
                log.debug("Pedido {} não encontrado", orderId);
                return false;
            }

            Order order = orderOpt.get();

            // Verifica se é o cliente que fez o pedido
            boolean isCustomer = order.getUser() != null && order.getUser().getId().equals(userId);
            if (isCustomer) {
                log.debug("Usuário {} é o cliente do pedido {}", userId, orderId);
                return true;
            }

            // Verifica se é o dono do restaurante do pedido
            if (order.getRestaurant() != null && order.getRestaurant().getOwner() != null) {
                boolean isRestaurantOwner = order.getRestaurant().getOwner().getId().equals(userId);
                if (isRestaurantOwner) {
                    log.debug("Usuário {} é dono do restaurante do pedido {}", userId, orderId);
                    return true;
                }
            }

            log.debug("Usuário {} não tem permissão para visualizar pedido {}", userId, orderId);
            return false;

        } catch (Exception e) {
            log.error("Erro ao verificar permissão de visualização de pedido", e);
            return false;
        }
    }

    /**
     * Verifica se o usuário pode atribuir entregador a um pedido
     * @param userId ID do usuário
     * @param orderId ID do pedido
     * @return true se o usuário é dono do restaurante do pedido OU é ADMIN
     */
    public boolean canAssignDelivery(Long userId, Long orderId) {
        if (userId == null || orderId == null) {
            log.debug("userId ou orderId é null");
            return false;
        }

        try {
            Optional<User> userOpt = userRepository.findById(userId);
            if (userOpt.isEmpty()) {
                log.debug("Usuário {} não encontrado", userId);
                return false;
            }

            User user = userOpt.get();

            // ADMIN pode atribuir qualquer entrega
            if (user.hasRole("ADMIN")) {
                log.debug("Usuário {} é ADMIN, pode atribuir entrega do pedido {}", userId, orderId);
                return true;
            }

            Optional<Order> orderOpt = orderRepository.findById(orderId);
            if (orderOpt.isEmpty()) {
                log.debug("Pedido {} não encontrado", orderId);
                return false;
            }

            Order order = orderOpt.get();

            // Verifica se é o dono do restaurante do pedido
            if (order.getRestaurant() != null && order.getRestaurant().getOwner() != null) {
                boolean isRestaurantOwner = order.getRestaurant().getOwner().getId().equals(userId);
                log.debug("Usuário {} {} dono do restaurante do pedido {}", 
                        userId, isRestaurantOwner ? "é" : "não é", orderId);
                return isRestaurantOwner;
            }

            return false;

        } catch (Exception e) {
            log.error("Erro ao verificar permissão de atribuição de entrega", e);
            return false;
        }
    }

    /**
     * Verifica se o usuário pode gerenciar uma organização específica
     * @param userId ID do usuário
     * @param organizationId ID da organização
     * @return true se o usuário é administrador da organização OU é ADMIN do sistema
     */
    public boolean canManageOrganization(Long userId, Long organizationId) {
        if (userId == null || organizationId == null) {
            log.debug("userId ou organizationId é null");
            return false;
        }

        try {
            Optional<User> userOpt = userRepository.findById(userId);
            if (userOpt.isEmpty()) {
                log.debug("Usuário {} não encontrado", userId);
                return false;
            }

            User user = userOpt.get();

            // ADMIN pode gerenciar qualquer organização
            if (user.hasRole("ADMIN")) {
                log.debug("Usuário {} é ADMIN, pode gerenciar organização {}", userId, organizationId);
                return true;
            }

            Optional<Organization> orgOpt = organizationRepository.findById(organizationId);
            if (orgOpt.isEmpty()) {
                log.debug("Organização {} não encontrada", organizationId);
                return false;
            }

            Organization organization = orgOpt.get();
            boolean isAdmin = organization.getAdminUser() != null && 
                             organization.getAdminUser().getId().equals(userId);

            log.debug("Usuário {} {} administrador da organização {}", 
                    userId, isAdmin ? "é" : "não é", organizationId);

            return isAdmin;

        } catch (Exception e) {
            log.error("Erro ao verificar permissão de gerenciamento de organização", e);
            return false;
        }
    }

    /**
     * Verifica se o usuário pode gerenciar um entregador específico
     * @param userId ID do usuário
     * @param deliveryPersonId ID do entregador
     * @return true se o usuário é administrador da organização do entregador OU é ADMIN do sistema
     */
    public boolean canManageDeliveryPerson(Long userId, Long deliveryPersonId) {
        if (userId == null || deliveryPersonId == null) {
            log.debug("userId ou deliveryPersonId é null");
            return false;
        }

        try {
            Optional<User> userOpt = userRepository.findById(userId);
            if (userOpt.isEmpty()) {
                log.debug("Usuário {} não encontrado", userId);
                return false;
            }

            User user = userOpt.get();

            // ADMIN pode gerenciar qualquer entregador
            if (user.hasRole("ADMIN")) {
                log.debug("Usuário {} é ADMIN, pode gerenciar entregador {}", userId, deliveryPersonId);
                return true;
            }

            Optional<DeliveryPerson> deliveryPersonOpt = deliveryPersonRepository.findById(deliveryPersonId);
            if (deliveryPersonOpt.isEmpty()) {
                log.debug("Entregador {} não encontrado", deliveryPersonId);
                return false;
            }

            DeliveryPerson deliveryPerson = deliveryPersonOpt.get();

            // Verifica se o usuário é administrador da organização do entregador
            if (deliveryPerson.getOrganization() != null && 
                deliveryPerson.getOrganization().getAdminUser() != null) {
                boolean isOrgAdmin = deliveryPerson.getOrganization().getAdminUser().getId().equals(userId);
                log.debug("Usuário {} {} administrador da organização do entregador {}", 
                        userId, isOrgAdmin ? "é" : "não é", deliveryPersonId);
                return isOrgAdmin;
            }

            return false;

        } catch (Exception e) {
            log.error("Erro ao verificar permissão de gerenciamento de entregador", e);
            return false;
        }
    }
}
