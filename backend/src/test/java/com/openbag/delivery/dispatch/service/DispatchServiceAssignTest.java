package com.openbag.delivery.dispatch.service;

import com.openbag.enums.CourierWorkStatus;
import com.openbag.enums.DeliveryFeeMode;
import com.openbag.enums.DeliveryOfferStatus;
import com.openbag.enums.OrderStatus;
import com.openbag.enums.OrganizationStatus;
import com.openbag.enums.PartnershipStatus;
import com.openbag.enums.ShiftMode;
import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.delivery.dispatch.dto.AssignCourierRequest;
import com.openbag.delivery.dispatch.dto.CourierMessage;
import com.openbag.delivery.courier.entity.CourierShift;
import com.openbag.delivery.dispatch.entity.DeliveryOffer;
import com.openbag.delivery.courier.entity.DeliveryPerson;
import com.openbag.association.partnership.entity.RestaurantPartnership;
import com.openbag.delivery.link.entity.StaffCourier;
import com.openbag.delivery.courier.repository.CourierShiftRepository;
import com.openbag.delivery.dispatch.repository.DeliveryOfferRepository;
import com.openbag.delivery.courier.repository.DeliveryPersonRepository;
import com.openbag.association.partnership.repository.RestaurantPartnershipRepository;
import com.openbag.delivery.link.repository.StaffCourierRepository;
import com.openbag.order.core.entity.Order;
import com.openbag.order.core.repository.OrderRepository;
import com.openbag.order.core.service.OrderService;
import com.openbag.modules.organization.entity.DeliveryRate;
import com.openbag.modules.organization.entity.Organization;
import com.openbag.restaurant.store.entity.Restaurant;
import com.openbag.modules.user.entity.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.transaction.PlatformTransactionManager;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

class DispatchServiceAssignTest {

    private static final ZoneId ZONE = ZoneId.of("America/Sao_Paulo");
    private static final LocalDateTime NOW = LocalDateTime.of(2026, 9, 27, 19, 0);

    private final OrderRepository orderRepository = mock(OrderRepository.class);
    private final DeliveryPersonRepository courierRepository = mock(DeliveryPersonRepository.class);
    private final DeliveryOfferRepository offerRepository = mock(DeliveryOfferRepository.class);
    private final CourierShiftRepository shiftRepository = mock(CourierShiftRepository.class);
    private final StaffCourierRepository staffRepository = mock(StaffCourierRepository.class);
    private final RestaurantPartnershipRepository partnershipRepository = mock(RestaurantPartnershipRepository.class);
    private final CourierNotifier notifier = mock(CourierNotifier.class);
    private final DispatchProperties properties = mock(DispatchProperties.class);

    private DispatchService service;
    private Restaurant restaurant;
    private Order order;
    private Organization organization;

    @BeforeEach
    void setUp() {
        service = new DispatchService(mock(PlatformTransactionManager.class));
        ReflectionTestUtils.setField(service, "orderRepository", orderRepository);
        ReflectionTestUtils.setField(service, "deliveryPersonRepository", courierRepository);
        ReflectionTestUtils.setField(service, "offerRepository", offerRepository);
        ReflectionTestUtils.setField(service, "shiftRepository", shiftRepository);
        ReflectionTestUtils.setField(service, "staffRepository", staffRepository);
        ReflectionTestUtils.setField(service, "partnershipRepository", partnershipRepository);
        ReflectionTestUtils.setField(service, "orderService", mock(OrderService.class));
        ReflectionTestUtils.setField(service, "notifier", notifier);
        ReflectionTestUtils.setField(service, "properties", properties);
        ReflectionTestUtils.setField(service, "events", mock(ApplicationEventPublisher.class));
        setNow(NOW);
        when(properties.getLocationStaleSeconds()).thenReturn(120);

        restaurant = new Restaurant();
        restaurant.setId(1L);
        restaurant.setLatitude(new BigDecimal("-26.9194"));
        restaurant.setLongitude(new BigDecimal("-49.0661"));

        organization = new Organization();
        organization.setId(3L);
        organization.setStatus(OrganizationStatus.ACTIVE);
        organization.setDeliveryRate(new DeliveryRate(new BigDecimal("7.00"), new BigDecimal("3.0"), new BigDecimal("1.50")));

        order = new Order();
        order.setId(10L);
        order.setDisplayCode("#0010");
        order.setRestaurant(restaurant);
        order.setStatus(OrderStatus.PREPARING);
        order.setDeliveryFee(new BigDecimal("8.00"));
        order.setDeliveryDistanceKm(2.0);
        when(orderRepository.findByIdForUpdate(10L)).thenReturn(Optional.of(order));
        when(offerRepository.findByOrderIdAndStatus(anyLong(), any())).thenReturn(List.of());
        when(offerRepository.findPendingByCourier(anyLong())).thenReturn(Optional.empty());
    }

    private void setNow(LocalDateTime now) {
        ReflectionTestUtils.setField(service, "clock", Clock.fixed(now.atZone(ZONE).toInstant(), ZONE));
    }

    private DeliveryPerson courier(long id, ShiftMode mode) {
        User user = new User();
        user.setFullName("Entregador " + id);
        CourierShift shift = new CourierShift();
        shift.setMode(mode);
        shift.setRestaurant(mode == ShiftMode.FIXED ? restaurant : null);
        shift.setStartedAt(NOW.minusHours(1));

        DeliveryPerson courier = new DeliveryPerson();
        courier.setId(id);
        courier.setUser(user);
        courier.setActive(true);
        courier.setOrganization(organization);
        courier.setWorkStatus(CourierWorkStatus.ONLINE);
        courier.setCurrentShift(shift);
        // A ~2 km da loja
        courier.setLastLatitude(-26.9014);
        courier.setLastLongitude(-49.0661);
        courier.setLastSeenAt(NOW);
        when(courierRepository.findByIdForUpdate(id)).thenReturn(Optional.of(courier));
        return courier;
    }

    @Test
    void assignsFreeCourierDirectlyWithoutOffer() {
        DeliveryPerson courier = courier(5L, ShiftMode.FREE);

        service.assignDirect(1L, 10L, new AssignCourierRequest(5L, null));

        assertThat(order.getDeliveryPerson()).isSameAs(courier);
        assertThat(order.getCourierFee()).isEqualByComparingTo("7.00");
        assertThat(order.getAssignedAt()).isEqualTo(NOW);
        assertThat(courier.getWorkStatus()).isEqualTo(CourierWorkStatus.BUSY);
        ArgumentCaptor<CourierMessage> message = ArgumentCaptor.forClass(CourierMessage.class);
        verify(notifier).send(eq(5L), message.capture());
        assertThat(message.getValue().type()).isEqualTo(CourierMessage.Type.ORDER_ASSIGNED);
    }

    @Test
    void recordsTheCourierAssociationOnTheOrder() {
        courier(5L, ShiftMode.FREE);

        service.assignDirect(1L, 10L, new AssignCourierRequest(5L, null));

        assertThat(order.getCourierOrganization()).isSameAs(organization);
    }

    @Test
    void agreedRateOfThePartnershipReplacesTheAssociationTable() {
        courier(5L, ShiftMode.FREE);
        order.setDeliveryFee(new BigDecimal("5.00"));
        agreeRate(new DeliveryRate(new BigDecimal("5.00"), new BigDecimal("4.0"), new BigDecimal("1.00")));

        // A tabela padrão (R$ 7,00) passaria da taxa; a combinada com a loja (R$ 5,00 até 4 km) cabe
        service.assignDirect(1L, 10L, new AssignCourierRequest(5L, null));

        assertThat(order.getCourierFee()).isEqualByComparingTo("5.00");
        assertThat(order.getRestaurantDeliverySubsidy()).isEqualByComparingTo("0.00");
    }

    @Test
    void agreedRateAboveTheFeeIsPaidInFullWithTheStoreCoveringTheDifference() {
        courier(5L, ShiftMode.FREE);
        restaurant.setCoversDeliveryDifference(true);
        order.setDeliveryDistanceKm(5.0);
        agreeRate(new DeliveryRate(new BigDecimal("9.00"), new BigDecimal("3.0"), new BigDecimal("2.00")));

        service.assignDirect(1L, 10L, new AssignCourierRequest(5L, null));

        // 9,00 + 2 km × 2,00 = 13,00; a loja cobra 8,00 e assume 5,00
        assertThat(order.getCourierFee()).isEqualByComparingTo("13.00");
        assertThat(order.getRestaurantDeliverySubsidy()).isEqualByComparingTo("5.00");
    }

    @Test
    void storeThatPassesTheFeePaysTheCourierEverythingTheCustomerPaid() {
        courier(5L, ShiftMode.FREE);
        restaurant.setDeliveryFeeMode(DeliveryFeeMode.PASS_THROUGH);
        // O cliente pagou R$ 13,00, calculado pela maior tabela entre as associações
        order.setDeliveryDistanceKm(4.0);
        order.setDeliveryFee(new BigDecimal("13.00"));

        service.assignDirect(1L, 10L, new AssignCourierRequest(5L, null));

        // A tabela dele a 4 km daria 7 + 1 × 1,50 = 8,50, mas ele recebe o valor inteiro da entrega
        assertThat(order.getCourierFee()).isEqualByComparingTo("13.00");
        assertThat(order.getRestaurantDeliverySubsidy()).isEqualByComparingTo("0.00");
    }

    private void agreeRate(DeliveryRate rate) {
        RestaurantPartnership partnership = new RestaurantPartnership();
        partnership.setRestaurant(restaurant);
        partnership.setOrganization(organization);
        partnership.setStatus(PartnershipStatus.ACTIVE);
        partnership.setAgreedRate(rate);
        when(partnershipRepository.findActive(1L, 3L)).thenReturn(Optional.of(partnership));
        when(partnershipRepository.findActiveByRestaurant(1L)).thenReturn(List.of(partnership));
    }

    @Test
    void refusesCourierWhoseTableExceedsTheFeeWithoutCoverage() {
        courier(5L, ShiftMode.FREE);
        order.setDeliveryFee(new BigDecimal("5.00"));

        assertThatThrownBy(() -> service.assignDirect(1L, 10L, new AssignCourierRequest(5L, null)))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("passa da sua taxa");
        assertThat(order.getDeliveryPerson()).isNull();
    }

    @Test
    void freeCourierCanOnlyBeSwappedAfterNoShowMinutes() {
        DeliveryPerson first = courier(5L, ShiftMode.FREE);
        courier(6L, ShiftMode.FREE);
        service.assignDirect(1L, 10L, new AssignCourierRequest(5L, null));

        setNow(NOW.plusMinutes(5));
        assertThatThrownBy(() -> service.assignDirect(1L, 10L, new AssignCourierRequest(6L, null)))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("19:10");

        setNow(NOW.plusMinutes(11));
        service.assignDirect(1L, 10L, new AssignCourierRequest(6L, null));

        assertThat(order.getDeliveryPerson().getId()).isEqualTo(6L);
        assertThat(first.getWorkStatus()).isEqualTo(CourierWorkStatus.ONLINE);
        // O anterior não recebe mais oferta deste pedido
        ArgumentCaptor<DeliveryOffer> exclusion = ArgumentCaptor.forClass(DeliveryOffer.class);
        verify(offerRepository).save(exclusion.capture());
        assertThat(exclusion.getValue().getDeliveryPerson()).isSameAs(first);
        assertThat(exclusion.getValue().getStatus()).isEqualTo(DeliveryOfferStatus.CANCELLED);
    }

    @Test
    void fixedCourierCanBeSwappedRightAway() {
        courier(5L, ShiftMode.FIXED);
        StaffCourier staff = new StaffCourier();
        staff.setId(3L);
        staff.setName("Zé da loja");
        when(staffRepository.findByIdAndRestaurantId(3L, 1L)).thenReturn(Optional.of(staff));
        service.assignDirect(1L, 10L, new AssignCourierRequest(5L, null));

        service.assignDirect(1L, 10L, new AssignCourierRequest(null, 3L));

        assertThat(order.getDeliveryPerson()).isNull();
        assertThat(order.getStaffCourier()).isSameAs(staff);
        // Sem valor combinado, a equipe recebe a taxa cobrada do cliente
        assertThat(order.getCourierFee()).isEqualByComparingTo("8.00");
        assertThat(order.getRestaurantDeliverySubsidy()).isEqualByComparingTo("0");
    }

    @Test
    void staffOrdersStayOutOfAutomaticDispatch() {
        order.setStaffCourier(new StaffCourier());

        service.dispatchLocked(order);

        verify(offerRepository, never()).save(any());
        verify(courierRepository, never()).findFreeOnlineCouriers(any());
    }

    @Test
    void pickupOrdersNeverCallACourier() {
        order.setFulfillment(com.openbag.enums.FulfillmentType.PICKUP);
        restaurant.setRouteBatchingEnabled(false);

        service.dispatchLocked(order);

        verify(offerRepository, never()).save(any());
        verify(courierRepository, never()).findFreeOnlineCouriers(any());
        assertThatThrownBy(() -> service.assignDirect(1L, 10L, new AssignCourierRequest(5L, null)))
                .isInstanceOf(BadRequestException.class);
    }

    @Test
    void unassignSendsTheOrderBackToDispatch() {
        DeliveryPerson courier = courier(5L, ShiftMode.FIXED);
        service.assignDirect(1L, 10L, new AssignCourierRequest(5L, null));

        service.unassign(1L, 10L);

        assertThat(order.getDeliveryPerson()).isNull();
        assertThat(order.getCourierFee()).isNull();
        assertThat(courier.getWorkStatus()).isEqualTo(CourierWorkStatus.ONLINE);
        ArgumentCaptor<CourierMessage> messages = ArgumentCaptor.forClass(CourierMessage.class);
        verify(notifier, times(2)).send(eq(5L), messages.capture());
        assertThat(messages.getAllValues().get(1).type()).isEqualTo(CourierMessage.Type.ORDER_UNASSIGNED);
    }

    @Test
    void ordersWaitForThePlannerWhenRoutesAreOn() {
        // Rotas ligadas (padrão) e o planejador ainda não liberou: ninguém é chamado
        service.dispatchLocked(order);
        verify(courierRepository, never()).findFreeOnlineCouriers(any());

        restaurant.setRouteBatchingEnabled(false);
        when(offerRepository.findOfferedCourierIds(10L)).thenReturn(java.util.Set.of());
        when(offerRepository.findCourierIdsWithPendingOffer()).thenReturn(java.util.Set.of());
        service.dispatchLocked(order);
        verify(courierRepository).findFreeOnlineCouriers(any());
    }

    @Test
    void courierStaysBusyWhileTheRouteHasOpenDeliveries() {
        DeliveryPerson courier = courier(5L, ShiftMode.FIXED);
        service.assignDirect(1L, 10L, new AssignCourierRequest(5L, null));
        Order other = new Order();
        other.setId(11L);
        when(orderRepository.findByCourierAndStatusIn(eq(5L), any())).thenReturn(List.of(order, other));

        service.unassign(1L, 10L);

        assertThat(courier.getWorkStatus()).isEqualTo(CourierWorkStatus.BUSY);
    }

    @Test
    void routeOfferPaysTheFullTableValueOfEveryDelivery() {
        // Agrupar nunca reduz o ganho: a rota paga o mesmo que as entregas separadas
        DeliveryPerson courier = courier(5L, ShiftMode.FIXED);
        CourierShift shift = courier.getCurrentShift();
        shift.setDeliveryPerson(courier);
        when(shiftRepository.findOpenFixedAtRestaurant(1L)).thenReturn(List.of(shift));
        when(offerRepository.findOfferedCourierIds(anyLong())).thenReturn(java.util.Set.of());
        when(offerRepository.findCourierIdsWithPendingOffer()).thenReturn(java.util.Set.of());

        Order second = new Order();
        second.setId(11L);
        second.setRestaurant(restaurant);
        second.setStatus(OrderStatus.PREPARING);
        second.setDeliveryFee(new BigDecimal("8.00"));
        second.setDeliveryDistanceKm(5.0);
        com.openbag.delivery.route.entity.DeliveryRoute route = new com.openbag.delivery.route.entity.DeliveryRoute();
        route.setId(1L);
        route.setRestaurant(restaurant);
        route.setStatus(com.openbag.enums.RouteStatus.DISPATCHING);
        for (Order o : List.of(order, second)) {
            o.setRoute(route);
            o.setDispatchReleasedAt(NOW);
            route.getOrders().add(o);
        }
        order.setRouteSequence(1);
        second.setRouteSequence(2);
        restaurant.setCoversDeliveryDifference(true);

        service.dispatchLocked(order);

        ArgumentCaptor<DeliveryOffer> offer = ArgumentCaptor.forClass(DeliveryOffer.class);
        verify(offerRepository).save(offer.capture());
        // 7,00 (até 3 km) + 7,00 + 2 km × 1,50 = 17,00
        assertThat(offer.getValue().getCourierFee()).isEqualByComparingTo("17.00");
        assertThat(offer.getValue().getRoute()).isSameAs(route);
        assertThat(offer.getValue().getOrder()).isSameAs(order);
    }
}
