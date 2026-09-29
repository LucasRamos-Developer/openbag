package com.openbag.modules.admin.service;

import com.openbag.enums.CourierWorkStatus;
import com.openbag.enums.OrderStatus;
import com.openbag.enums.OrganizationStatus;
import com.openbag.modules.admin.dto.AdminDTOs.CourierRow;
import com.openbag.modules.admin.dto.AdminDTOs.OrderRow;
import com.openbag.modules.admin.dto.AdminDTOs.Overview;
import com.openbag.modules.admin.dto.AdminDTOs.RestaurantRow;
import com.openbag.modules.admin.dto.AdminDTOs.UserRow;
import com.openbag.modules.delivery.repository.DeliveryPersonRepository;
import com.openbag.modules.order.repository.OrderRepository;
import com.openbag.modules.organization.repository.OrganizationRepository;
import com.openbag.restaurant.store.repository.RestaurantRepository;
import com.openbag.modules.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.EnumSet;
import java.util.Locale;

/**
 * Painel do super admin: números e listas somente leitura de toda a plataforma
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AdminOverviewService {

    private final RestaurantRepository restaurantRepository;
    private final OrganizationRepository organizationRepository;
    private final DeliveryPersonRepository deliveryPersonRepository;
    private final UserRepository userRepository;
    private final OrderRepository orderRepository;
    private final Clock clock;

    public Overview overview() {
        LocalDateTime now = LocalDateTime.now(clock);
        // "Aberto agora" depende dos horários de cada loja; a quantidade de lojas ainda é pequena
        long openNow = restaurantRepository.findAll().stream().filter(r -> r.isOpenNow(now)).count();
        return new Overview(
                restaurantRepository.count(),
                openNow,
                organizationRepository.count(),
                organizationRepository.countByStatus(OrganizationStatus.PENDING_APPROVAL),
                deliveryPersonRepository.count(),
                deliveryPersonRepository.countByWorkStatusIn(EnumSet.of(CourierWorkStatus.ONLINE, CourierWorkStatus.BUSY)),
                userRepository.count(),
                orderRepository.countByCreatedAtGreaterThanEqual(LocalDate.now(clock).atStartOfDay()));
    }

    public Page<RestaurantRow> restaurants(String query, Pageable pageable) {
        LocalDateTime now = LocalDateTime.now(clock);
        return restaurantRepository.searchForAdmin(like(query), pageable).map(r -> RestaurantRow.from(r, now));
    }

    public Page<CourierRow> couriers(String query, Pageable pageable) {
        return deliveryPersonRepository.searchForAdmin(like(query), pageable).map(CourierRow::from);
    }

    public Page<UserRow> users(String query, Pageable pageable) {
        return userRepository.searchForAdmin(like(query), pageable).map(UserRow::from);
    }

    public Page<OrderRow> orders(OrderStatus status, Pageable pageable) {
        return (status == null ? orderRepository.findAll(pageable) : orderRepository.findByStatus(status, pageable))
                .map(OrderRow::from);
    }

    /** Termo de busca para "like" (vazio = tudo) */
    static String like(String query) {
        return query == null || query.isBlank() ? "%" : "%" + query.trim().toLowerCase(Locale.ROOT) + "%";
    }
}
