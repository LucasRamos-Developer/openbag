package com.openbag.restaurant.cash.service;

import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.platform.web.exception.ResourceNotFoundException;
import com.openbag.delivery.dispatch.service.ReassignPolicy.CourierKind;
import com.openbag.restaurant.cash.dto.CashReportDTO;
import com.openbag.restaurant.cash.dto.SettleCourierRequest;
import com.openbag.restaurant.cash.dto.SettlementDTO;
import com.openbag.restaurant.cash.entity.CourierSettlement;
import com.openbag.delivery.courier.entity.DeliveryPerson;
import com.openbag.delivery.link.entity.StaffCourier;
import com.openbag.restaurant.cash.repository.CourierSettlementRepository;
import com.openbag.order.core.entity.Order;
import com.openbag.order.core.repository.OrderRepository;
import com.openbag.association.core.entity.Organization;
import com.openbag.restaurant.store.repository.RestaurantRepository;
import com.openbag.account.entity.User;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Clock;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.function.Function;

/**
 * Caixa da loja: vendas pelo OpenBag no período e acerto com cada entregador.
 *
 * Pagamento na entrega: o entregador recebe do cliente. Pedidos em dinheiro ficam com ele (precisa devolver);
 * cartão e Pix caem na maquininha/Pix da loja. Ele recebe o valor das entregas (courierFee).
 */
@Service
@Transactional
public class CashReportService {

    private static final BigDecimal ZERO = BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private CourierSettlementRepository settlementRepository;

    @Autowired
    private RestaurantRepository restaurantRepository;

    @Autowired
    private Clock clock;

    @Transactional(readOnly = true)
    public CashReportDTO report(Long restaurantId, LocalDate from, LocalDate to) {
        LocalDate today = LocalDate.now(clock);
        LocalDate start = from != null ? from : today;
        LocalDate end = to != null ? to : start;
        if (end.isBefore(start)) {
            throw new BadRequestException("A data final não pode ser antes da inicial");
        }
        LocalDateTime startAt = start.atStartOfDay();
        LocalDateTime endAt = end.plusDays(1).atStartOfDay();

        List<Order> delivered = orderRepository.findDeliveredByRestaurantBetween(restaurantId, startAt, endAt);
        long cancelled = orderRepository.countCancelledByRestaurantBetween(restaurantId, startAt, endAt);
        List<Order> unsettled = orderRepository.findUnsettledByRestaurant(restaurantId);
        List<SettlementDTO> settlements = settlementRepository
                .findByRestaurantIdAndSettledAtBetweenOrderBySettledAtDesc(restaurantId, startAt, endAt).stream()
                .map(SettlementDTO::from)
                .toList();

        return new CashReportDTO(start, end, summary(delivered, cancelled), payments(delivered),
                couriers(delivered, unsettled), settlements, subsidy(delivered));
    }

    /**
     * Fecha as entregas ainda não acertadas do entregador (de qualquer data)
     */
    public SettlementDTO settle(Long restaurantId, SettleCourierRequest request, User settledBy) {
        if ((request.deliveryPersonId() == null) == (request.staffCourierId() == null)) {
            throw new BadRequestException("Escolha o entregador");
        }
        List<Order> orders = request.deliveryPersonId() != null
                ? orderRepository.findUnsettledForAppCourierForUpdate(restaurantId, request.deliveryPersonId())
                : orderRepository.findUnsettledForStaffForUpdate(restaurantId, request.staffCourierId());
        if (orders.isEmpty()) {
            throw new BadRequestException("Não há entregas para acertar com este entregador");
        }

        Order first = orders.get(0);
        CourierSettlement settlement = new CourierSettlement();
        settlement.setRestaurant(restaurantRepository.findById(restaurantId)
                .orElseThrow(() -> new ResourceNotFoundException("Restaurante não encontrado")));
        settlement.setDeliveryPerson(first.getDeliveryPerson());
        settlement.setStaffCourier(first.getStaffCourier());
        settlement.setOrdersCount(orders.size());
        settlement.setCashCollected(sum(orders.stream().filter(CashReportService::paidInCash).toList(), Order::getTotalAmount));
        settlement.setCourierEarnings(sum(orders, Order::getCourierFee));
        settlement.setBalance(settlement.getCashCollected().subtract(settlement.getCourierEarnings()));
        settlement.setSettledAt(LocalDateTime.now(clock));
        settlement.setSettledBy(settledBy);
        CourierSettlement saved = settlementRepository.save(settlement);

        for (Order order : orders) {
            order.setSettlement(saved);
        }
        orderRepository.saveAll(orders);
        return SettlementDTO.from(saved);
    }

    // ============= Montagem do relatório =============

    private static CashReportDTO.Summary summary(List<Order> delivered, long cancelled) {
        BigDecimal received = sum(delivered, Order::getTotalAmount);
        BigDecimal paidToCouriers = sum(delivered.stream().filter(CashReportService::hasCourier).toList(), Order::getCourierFee);
        BigDecimal average = delivered.isEmpty() ? ZERO
                : received.divide(BigDecimal.valueOf(delivered.size()), 2, RoundingMode.HALF_UP);
        return new CashReportDTO.Summary(
                delivered.size(),
                cancelled,
                sum(delivered, Order::getSubtotal),
                sum(delivered, Order::getDeliveryFee),
                received,
                paidToCouriers,
                sum(delivered, Order::getRestaurantDeliverySubsidy),
                received.subtract(paidToCouriers),
                average,
                (int) delivered.stream().filter(o -> !hasCourier(o)).count());
    }

    /**
     * Pedidos em que a loja assumiu a diferença, por associação e um a um (mais recentes primeiro)
     */
    private static CashReportDTO.Subsidy subsidy(List<Order> delivered) {
        List<Order> subsidized = delivered.stream()
                .filter(o -> o.getRestaurantDeliverySubsidy() != null && o.getRestaurantDeliverySubsidy().signum() > 0)
                .sorted(Comparator.comparing(Order::getDeliveredAt, Comparator.nullsLast(Comparator.reverseOrder())))
                .toList();

        Map<Long, List<Order>> byOrganization = new LinkedHashMap<>();
        for (Order order : subsidized) {
            Organization organization = organizationOf(order);
            byOrganization.computeIfAbsent(organization != null ? organization.getId() : null, id -> new ArrayList<>())
                    .add(order);
        }
        List<CashReportDTO.SubsidyByAssociation> associations = byOrganization.values().stream()
                .map(orders -> {
                    Organization organization = organizationOf(orders.get(0));
                    return new CashReportDTO.SubsidyByAssociation(
                            organization != null ? organization.getId() : null,
                            organization != null ? organization.getTradingName() : "Sem associação",
                            orders.size(), sum(orders, Order::getRestaurantDeliverySubsidy));
                })
                .sorted(Comparator.comparing(CashReportDTO.SubsidyByAssociation::total).reversed())
                .toList();

        List<CashReportDTO.SubsidyLine> lines = subsidized.stream()
                .map(o -> {
                    Organization organization = organizationOf(o);
                    return new CashReportDTO.SubsidyLine(o.getId(), o.getDisplayCode(), o.getDeliveredAt(),
                            o.getDeliveryPerson() != null ? o.getDeliveryPerson().getUser().getFullName() : null,
                            organization != null ? organization.getTradingName() : null,
                            o.getDeliveryDistanceKm(), o.getDeliveryFee(), o.getCourierFee(),
                            o.getRestaurantDeliverySubsidy());
                })
                .toList();
        return new CashReportDTO.Subsidy(sum(subsidized, Order::getRestaurantDeliverySubsidy), subsidized.size(),
                associations, lines);
    }

    /** Associação do entregador no momento da entrega (pedidos antigos, sem o registro, usam a atual) */
    private static Organization organizationOf(Order order) {
        if (order.getCourierOrganization() != null) {
            return order.getCourierOrganization();
        }
        return order.getDeliveryPerson() != null ? order.getDeliveryPerson().getOrganization() : null;
    }

    private static List<CashReportDTO.PaymentLine> payments(List<Order> delivered) {
        Map<Order.PaymentMethod, List<Order>> byMethod = new EnumMap<>(Order.PaymentMethod.class);
        for (Order order : delivered) {
            if (order.getPaymentMethod() != null) {
                byMethod.computeIfAbsent(order.getPaymentMethod(), m -> new ArrayList<>()).add(order);
            }
        }
        return byMethod.entrySet().stream()
                .map(e -> new CashReportDTO.PaymentLine(e.getKey(), e.getValue().size(), sum(e.getValue(), Order::getTotalAmount)))
                .sorted(Comparator.comparing(CashReportDTO.PaymentLine::amount).reversed())
                .toList();
    }

    /** Entregadores com entregas no período ou com acerto pendente */
    private static List<CashReportDTO.CourierLine> couriers(List<Order> delivered, List<Order> unsettled) {
        Map<String, List<Order>> inPeriod = groupByCourier(delivered);
        Map<String, List<Order>> pending = groupByCourier(unsettled);
        Set<String> keys = new LinkedHashSet<>(inPeriod.keySet());
        keys.addAll(pending.keySet());

        List<CashReportDTO.CourierLine> lines = new ArrayList<>();
        for (String key : keys) {
            List<Order> period = inPeriod.getOrDefault(key, List.of());
            List<Order> open = pending.getOrDefault(key, List.of());
            Order sample = !period.isEmpty() ? period.get(0) : open.get(0);
            DeliveryPerson courier = sample.getDeliveryPerson();
            StaffCourier staff = sample.getStaffCourier();

            BigDecimal pendingCash = sum(open.stream().filter(CashReportService::paidInCash).toList(), Order::getTotalAmount);
            BigDecimal pendingEarnings = sum(open, Order::getCourierFee);
            lines.add(new CashReportDTO.CourierLine(
                    staff != null ? CourierKind.STAFF : CourierKind.FREE,
                    courier != null ? courier.getId() : null,
                    staff != null ? staff.getId() : null,
                    staff != null ? staff.getName() : courier.getUser().getFullName(),
                    courier != null ? courier.getPhotoUrl() : null,
                    period.size(),
                    sum(period, Order::getCourierFee),
                    sum(period.stream().filter(CashReportService::paidInCash).toList(), Order::getTotalAmount),
                    sum(period.stream().filter(o -> !paidInCash(o)).toList(), Order::getTotalAmount),
                    open.size(),
                    pendingCash,
                    pendingEarnings,
                    pendingCash.subtract(pendingEarnings)));
        }
        // Quem tem acerto pendente primeiro, depois quem entregou mais
        lines.sort(Comparator.comparing((CashReportDTO.CourierLine l) -> l.pendingOrders() == 0)
                .thenComparing(CashReportDTO.CourierLine::deliveries, Comparator.reverseOrder())
                .thenComparing(CashReportDTO.CourierLine::name));
        return lines;
    }

    private static Map<String, List<Order>> groupByCourier(List<Order> orders) {
        Map<String, List<Order>> groups = new LinkedHashMap<>();
        for (Order order : orders) {
            if (order.getStaffCourier() != null) {
                groups.computeIfAbsent("staff-" + order.getStaffCourier().getId(), k -> new ArrayList<>()).add(order);
            } else if (order.getDeliveryPerson() != null) {
                groups.computeIfAbsent("app-" + order.getDeliveryPerson().getId(), k -> new ArrayList<>()).add(order);
            }
        }
        return groups;
    }

    private static boolean hasCourier(Order order) {
        return order.getDeliveryPerson() != null || order.getStaffCourier() != null;
    }

    private static boolean paidInCash(Order order) {
        return order.getPaymentMethod() == Order.PaymentMethod.CASH;
    }

    private static BigDecimal sum(List<Order> orders, Function<Order, BigDecimal> value) {
        return orders.stream()
                .map(value)
                .filter(Objects::nonNull)
                .reduce(ZERO, BigDecimal::add)
                .setScale(2, RoundingMode.HALF_UP);
    }
}
