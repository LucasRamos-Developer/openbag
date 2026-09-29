package com.openbag.restaurant.cash.service;

import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.modules.delivery.dispatch.ReassignPolicy.CourierKind;
import com.openbag.restaurant.cash.dto.CashReportDTO;
import com.openbag.restaurant.cash.dto.SettleCourierRequest;
import com.openbag.restaurant.cash.dto.SettlementDTO;
import com.openbag.restaurant.cash.entity.CourierSettlement;
import com.openbag.modules.delivery.entity.DeliveryPerson;
import com.openbag.modules.delivery.entity.StaffCourier;
import com.openbag.restaurant.cash.repository.CourierSettlementRepository;
import com.openbag.order.core.entity.Order;
import com.openbag.order.core.repository.OrderRepository;
import com.openbag.modules.organization.entity.Organization;
import com.openbag.restaurant.store.entity.Restaurant;
import com.openbag.restaurant.store.repository.RestaurantRepository;
import com.openbag.modules.user.entity.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.*;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CashReportServiceTest {

    private static final ZoneId ZONE = ZoneId.of("America/Sao_Paulo");

    @Mock private OrderRepository orderRepository;
    @Mock private CourierSettlementRepository settlementRepository;
    @Mock private RestaurantRepository restaurantRepository;
    @Spy private Clock clock = Clock.fixed(LocalDateTime.of(2026, 9, 27, 22, 0).atZone(ZONE).toInstant(), ZONE);

    @InjectMocks
    private CashReportService service;

    private DeliveryPerson courier;
    private StaffCourier staff;

    @BeforeEach
    void setUp() {
        User user = new User();
        user.setFullName("José da Silva");
        courier = new DeliveryPerson();
        courier.setId(5L);
        courier.setUser(user);
        staff = new StaffCourier();
        staff.setId(3L);
        staff.setName("Zé da Loja");
    }

    private static Order order(String subtotal, String fee, String courierFee, Order.PaymentMethod method) {
        Order order = new Order();
        order.setSubtotal(new BigDecimal(subtotal));
        order.setDeliveryFee(new BigDecimal(fee));
        order.setTotalAmount(new BigDecimal(subtotal).add(new BigDecimal(fee)));
        order.setCourierFee(courierFee != null ? new BigDecimal(courierFee) : null);
        order.setPaymentMethod(method);
        return order;
    }

    private Order byCourier(Order order) {
        order.setDeliveryPerson(courier);
        return order;
    }

    private Order byStaff(Order order) {
        order.setStaffCourier(staff);
        return order;
    }

    @Test
    void summarizesSalesPaymentsAndCourierBalances() {
        Order cash = byCourier(order("45.00", "5.00", "7.00", Order.PaymentMethod.CASH));
        Order pix = byCourier(order("30.00", "5.00", "7.00", Order.PaymentMethod.PIX));
        Order staffCash = byStaff(order("20.00", "5.00", "6.00", Order.PaymentMethod.CASH));
        Order selfDelivered = order("10.00", "0.00", null, Order.PaymentMethod.CREDIT_CARD);
        List<Order> delivered = List.of(cash, pix, staffCash, selfDelivered);
        when(orderRepository.findDeliveredByRestaurantBetween(eq(1L), any(), any())).thenReturn(delivered);
        when(orderRepository.countCancelledByRestaurantBetween(eq(1L), any(), any())).thenReturn(2L);
        when(orderRepository.findUnsettledByRestaurant(1L)).thenReturn(List.of(cash, pix, staffCash));

        CashReportDTO report = service.report(1L, null, null);

        assertThat(report.from()).isEqualTo(LocalDate.of(2026, 9, 27));
        CashReportDTO.Summary summary = report.summary();
        assertThat(summary.deliveredOrders()).isEqualTo(4);
        assertThat(summary.cancelledOrders()).isEqualTo(2);
        assertThat(summary.productSales()).isEqualByComparingTo("105.00");
        assertThat(summary.totalReceived()).isEqualByComparingTo("120.00");
        assertThat(summary.paidToCouriers()).isEqualByComparingTo("20.00");
        assertThat(summary.storeBalance()).isEqualByComparingTo("100.00");
        assertThat(summary.averageTicket()).isEqualByComparingTo("30.00");
        assertThat(summary.withoutCourier()).isEqualTo(1);

        assertThat(report.payments()).extracting(CashReportDTO.PaymentLine::method)
                .containsExactly(Order.PaymentMethod.CASH, Order.PaymentMethod.PIX, Order.PaymentMethod.CREDIT_CARD);

        CashReportDTO.CourierLine app = report.couriers().stream().filter(l -> l.deliveryPersonId() != null).findFirst().orElseThrow();
        assertThat(app.deliveries()).isEqualTo(2);
        assertThat(app.earnings()).isEqualByComparingTo("14.00");
        assertThat(app.cashCollected()).isEqualByComparingTo("50.00");
        assertThat(app.otherCollected()).isEqualByComparingTo("35.00");
        // Ficou com R$ 50 em dinheiro e ganhou R$ 14: devolve R$ 36
        assertThat(app.pendingBalance()).isEqualByComparingTo("36.00");

        CashReportDTO.CourierLine team = report.couriers().stream().filter(l -> l.kind() == CourierKind.STAFF).findFirst().orElseThrow();
        assertThat(team.name()).isEqualTo("Zé da Loja");
        assertThat(team.pendingBalance()).isEqualByComparingTo("19.00");
    }

    @Test
    void storePaysTheCourierWhenNoCashWasCollected() {
        Order pix = byCourier(order("30.00", "5.00", "7.00", Order.PaymentMethod.PIX));
        when(orderRepository.findDeliveredByRestaurantBetween(eq(1L), any(), any())).thenReturn(List.of(pix));
        when(orderRepository.findUnsettledByRestaurant(1L)).thenReturn(List.of(pix));

        CashReportDTO.CourierLine line = service.report(1L, null, null).couriers().get(0);

        assertThat(line.pendingBalance()).isEqualByComparingTo("-7.00");
    }

    @Test
    void pendingSettlementIncludesEarlierDays() {
        Order yesterday = byCourier(order("45.00", "5.00", "7.00", Order.PaymentMethod.CASH));
        when(orderRepository.findDeliveredByRestaurantBetween(eq(1L), any(), any())).thenReturn(List.of());
        when(orderRepository.findUnsettledByRestaurant(1L)).thenReturn(List.of(yesterday));

        CashReportDTO.CourierLine line = service.report(1L, null, null).couriers().get(0);

        assertThat(line.deliveries()).isZero();
        assertThat(line.pendingOrders()).isEqualTo(1);
        assertThat(line.pendingBalance()).isEqualByComparingTo("43.00");
    }

    @Test
    void settleClosesAllOpenDeliveriesOfTheCourier() {
        Order cash = byCourier(order("45.00", "5.00", "7.00", Order.PaymentMethod.CASH));
        Order pix = byCourier(order("30.00", "5.00", "7.00", Order.PaymentMethod.PIX));
        when(orderRepository.findUnsettledForAppCourierForUpdate(1L, 5L)).thenReturn(List.of(cash, pix));
        when(restaurantRepository.findById(1L)).thenReturn(Optional.of(new Restaurant()));
        when(settlementRepository.save(any(CourierSettlement.class))).thenAnswer(inv -> inv.getArgument(0));

        SettlementDTO settlement = service.settle(1L, new SettleCourierRequest(5L, null), new User());

        assertThat(settlement.ordersCount()).isEqualTo(2);
        assertThat(settlement.cashCollected()).isEqualByComparingTo("50.00");
        assertThat(settlement.courierEarnings()).isEqualByComparingTo("14.00");
        assertThat(settlement.balance()).isEqualByComparingTo("36.00");
        assertThat(cash.getSettlement()).isNotNull().isSameAs(pix.getSettlement());
    }

    @Test
    void settlingTwiceFindsNothingToSettle() {
        when(orderRepository.findUnsettledForStaffForUpdate(1L, 3L)).thenReturn(List.of());

        assertThatThrownBy(() -> service.settle(1L, new SettleCourierRequest(null, 3L), new User()))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("Não há entregas");
        verify(settlementRepository, never()).save(any());
    }

    @Test
    void subsidyListsTheDifferenceByAssociationAndByOrder() {
        Organization coop = new Organization();
        coop.setId(9L);
        coop.setTradingName("Coop Centro");
        courier.setOrganization(coop);
        Order early = byCourier(order("30.00", "5.00", "8.00", Order.PaymentMethod.PIX));
        early.setRestaurantDeliverySubsidy(new BigDecimal("3.00"));
        early.setDeliveredAt(LocalDateTime.of(2026, 9, 27, 19, 0));
        early.setDeliveryDistanceKm(4.2);
        Order late = byCourier(order("30.00", "5.00", "6.50", Order.PaymentMethod.CASH));
        late.setRestaurantDeliverySubsidy(new BigDecimal("1.50"));
        late.setDeliveredAt(LocalDateTime.of(2026, 9, 27, 21, 0));
        Order covered = byCourier(order("30.00", "8.00", "7.00", Order.PaymentMethod.CASH));
        covered.setRestaurantDeliverySubsidy(BigDecimal.ZERO);
        when(orderRepository.findDeliveredByRestaurantBetween(eq(1L), any(), any())).thenReturn(List.of(early, late, covered));
        when(orderRepository.findUnsettledByRestaurant(1L)).thenReturn(List.of());

        CashReportDTO.Subsidy subsidy = service.report(1L, null, null).subsidy();

        assertThat(subsidy.total()).isEqualByComparingTo("4.50");
        assertThat(subsidy.orders()).isEqualTo(2);
        assertThat(subsidy.byAssociation()).singleElement().satisfies(line -> {
            assertThat(line.name()).isEqualTo("Coop Centro");
            assertThat(line.orders()).isEqualTo(2);
            assertThat(line.total()).isEqualByComparingTo("4.50");
        });
        // Mais recentes primeiro
        assertThat(subsidy.lines()).extracting(CashReportDTO.SubsidyLine::subsidy)
                .containsExactly(new BigDecimal("1.50"), new BigDecimal("3.00"));
        assertThat(subsidy.lines().get(1).customerFee()).isEqualByComparingTo("5.00");
        assertThat(subsidy.lines().get(1).courierFee()).isEqualByComparingTo("8.00");
        assertThat(subsidy.lines().get(1).distanceKm()).isEqualTo(4.2);
    }

    @Test
    void subsidyStaysWithTheAssociationOfTheDeliveryEvenAfterTheCourierMoves() {
        Organization before = new Organization();
        before.setId(9L);
        before.setTradingName("Coop Centro");
        Organization now = new Organization();
        now.setId(11L);
        now.setTradingName("Coop Norte");
        courier.setOrganization(now);
        Order order = byCourier(order("30.00", "5.00", "8.00", Order.PaymentMethod.PIX));
        order.setCourierOrganization(before);
        order.setRestaurantDeliverySubsidy(new BigDecimal("3.00"));
        order.setDeliveredAt(LocalDateTime.of(2026, 9, 27, 19, 0));
        when(orderRepository.findDeliveredByRestaurantBetween(eq(1L), any(), any())).thenReturn(List.of(order));
        when(orderRepository.findUnsettledByRestaurant(1L)).thenReturn(List.of());

        CashReportDTO.Subsidy subsidy = service.report(1L, null, null).subsidy();

        assertThat(subsidy.byAssociation()).singleElement()
                .satisfies(line -> assertThat(line.name()).isEqualTo("Coop Centro"));
        assertThat(subsidy.lines().get(0).organizationName()).isEqualTo("Coop Centro");
    }
}
