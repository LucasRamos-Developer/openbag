package com.openbag.association.partnership.service;

import com.openbag.association.core.entity.MembershipStatus;
import com.openbag.association.partnership.entity.PartnershipStatus;
import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.platform.web.exception.ResourceNotFoundException;
import com.openbag.association.partnership.dto.AssociationReportDTO;
import com.openbag.delivery.courier.entity.DeliveryPerson;
import com.openbag.association.partnership.entity.RestaurantPartnership;
import com.openbag.delivery.courier.repository.DeliveryPersonRepository;
import com.openbag.association.partnership.repository.RestaurantPartnershipRepository;
import com.openbag.order.core.entity.Order;
import com.openbag.order.core.repository.OrderRepository;
import com.openbag.order.incident.entity.IncidentType;
import com.openbag.order.incident.repository.OrderIncidentRepository;
import com.openbag.order.incident.repository.OrderIncidentRepository.RestaurantTypeCount;
import com.openbag.association.core.entity.AssociationMembership;
import com.openbag.association.core.entity.DeliveryRate;
import com.openbag.association.core.entity.Organization;
import com.openbag.association.core.repository.AssociationMembershipRepository;
import com.openbag.association.core.repository.OrganizationRepository;
import com.openbag.restaurant.store.entity.Restaurant;
import com.openbag.account.entity.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AssociationReportServiceTest {

    private static final ZoneId ZONE = ZoneId.of("America/Sao_Paulo");
    private static final LocalDate TODAY = LocalDate.of(2026, 9, 28);

    @Mock private OrderRepository orderRepository;
    @Mock private OrganizationRepository organizationRepository;
    @Mock private AssociationMembershipRepository membershipRepository;
    @Mock private RestaurantPartnershipRepository partnershipRepository;
    @Mock private DeliveryPersonRepository deliveryPersonRepository;
    @Mock private OrderIncidentRepository incidentRepository;
    @Spy private Clock clock = Clock.fixed(TODAY.atTime(12, 0).atZone(ZONE).toInstant(), ZONE);

    @InjectMocks
    private AssociationReportService service;

    private Organization organization;
    private Restaurant cantina;
    private Restaurant pizzaria;
    private DeliveryPerson ana;
    private DeliveryPerson bruno;

    @BeforeEach
    void setUp() {
        organization = new Organization();
        organization.setId(10L);
        organization.setTradingName("Coop Centro");
        lenient().when(organizationRepository.findById(10L)).thenReturn(Optional.of(organization));

        cantina = restaurant(1L, "Cantina");
        pizzaria = restaurant(2L, "Pizzaria");
        ana = courier(5L, "Ana");
        bruno = courier(6L, "Bruno");

        List<Order> orders = List.of(
                order(cantina, ana, "8.00", "0.00", 3.0, TODAY.minusDays(1)),
                order(cantina, bruno, "9.50", "1.50", 4.0, TODAY.minusDays(1)),
                order(pizzaria, ana, "7.00", "0.00", 2.5, TODAY));
        lenient().when(orderRepository.findDeliveredByOrganizationBetween(eq(10L), any(), any())).thenReturn(orders);

        RestaurantPartnership agreement = new RestaurantPartnership();
        agreement.setRestaurant(cantina);
        agreement.setOrganization(organization);
        agreement.setStatus(PartnershipStatus.ACTIVE);
        agreement.setAgreedRate(new DeliveryRate(new BigDecimal("8.00"), new BigDecimal("4"), BigDecimal.ONE));
        lenient().when(partnershipRepository.findActiveByOrganization(10L)).thenReturn(List.of(agreement));
    }

    private static Restaurant restaurant(long id, String name) {
        Restaurant restaurant = new Restaurant();
        restaurant.setId(id);
        restaurant.setName(name);
        restaurant.setSlug(name.toLowerCase());
        return restaurant;
    }

    private static DeliveryPerson courier(long id, String name) {
        User user = new User();
        user.setId(id * 100);
        user.setFullName(name);
        DeliveryPerson courier = new DeliveryPerson();
        courier.setId(id);
        courier.setUser(user);
        return courier;
    }

    private static Order order(Restaurant restaurant, DeliveryPerson courier, String fee, String subsidy, double km,
                               LocalDate day) {
        Order order = new Order();
        order.setRestaurant(restaurant);
        order.setDeliveryPerson(courier);
        order.setCourierFee(new BigDecimal(fee));
        order.setRestaurantDeliverySubsidy(new BigDecimal(subsidy));
        order.setDeliveryDistanceKm(km);
        order.setDeliveredAt(day.atTime(20, 0));
        return order;
    }

    private static AssociationMembership membership(DeliveryPerson courier, int number, LocalDateTime requestedAt) {
        AssociationMembership membership = new AssociationMembership();
        membership.setDeliveryPerson(courier);
        membership.setMemberNumber(number);
        membership.setRequestedAt(requestedAt);
        membership.setStatus(MembershipStatus.ACTIVE);
        return membership;
    }

    @Test
    void managerSeesTotalsByDayByMemberAndByStore() {
        when(membershipRepository.findByOrganizationId(10L)).thenReturn(List.of(
                membership(ana, 1, LocalDateTime.of(2026, 1, 1, 0, 0)),
                membership(bruno, 2, LocalDateTime.of(2026, 2, 1, 0, 0))));

        AssociationReportDTO report = service.forManager(10L, null, null);

        assertThat(report.getFrom()).isEqualTo(TODAY.minusDays(29));
        assertThat(report.getTo()).isEqualTo(TODAY);
        assertThat(report.getSummary().deliveries()).isEqualTo(3);
        assertThat(report.getSummary().earnings()).isEqualByComparingTo("24.50");
        assertThat(report.getSummary().restaurantSubsidy()).isEqualByComparingTo("1.50");
        assertThat(report.getSummary().distanceKm()).isEqualTo(9.5);
        assertThat(report.getSummary().members()).isEqualTo(2);
        assertThat(report.getSummary().restaurants()).isEqualTo(2);

        assertThat(report.getDaily()).hasSize(30);
        assertThat(report.getDaily().get(28).deliveries()).isEqualTo(2);
        assertThat(report.getDaily().get(29).earnings()).isEqualByComparingTo("7.00");

        // Quem ganhou mais primeiro
        assertThat(report.getByMember()).extracting(AssociationReportDTO.MemberLine::name)
                .containsExactly("Ana", "Bruno");
        assertThat(report.getByMember().get(0).earnings()).isEqualByComparingTo("15.00");
        assertThat(report.getByMember().get(0).memberNumber()).isEqualTo(1);

        assertThat(report.getByRestaurant()).extracting(AssociationReportDTO.RestaurantLine::name)
                .containsExactly("Cantina", "Pizzaria");
        assertThat(report.getByRestaurant().get(0).agreedRate()).isTrue();
        assertThat(report.getByRestaurant().get(1).agreedRate()).isFalse();
        assertThat(report.getByRestaurant().get(0).restaurantSubsidy()).isEqualByComparingTo("1.50");
        assertThat(report.getMine()).isNull();
    }

    @Test
    void memberSeesTheAssociationAndOnlyTheirOwnShare() {
        User user = ana.getUser();
        when(deliveryPersonRepository.findByUserId(user.getId())).thenReturn(Optional.of(ana));
        AssociationMembership membership = membership(ana, 1, LocalDateTime.of(2026, 1, 1, 0, 0));
        membership.setOrganization(organization);
        when(membershipRepository.findByDeliveryPersonIdAndStatusIn(eq(5L), anyCollection()))
                .thenReturn(List.of(membership));

        AssociationReportDTO report = service.forMember(user, null, null);

        assertThat(report.getByMember()).isNull();
        assertThat(report.getMine().deliveries()).isEqualTo(2);
        assertThat(report.getMine().earnings()).isEqualByComparingTo("15.00");
        assertThat(report.getSummary().earnings()).isEqualByComparingTo("24.50");
        assertThat(report.getByRestaurant()).hasSize(2);
    }

    @Test
    void memberWithoutAnActiveMembershipHasNoReport() {
        User user = ana.getUser();
        when(deliveryPersonRepository.findByUserId(user.getId())).thenReturn(Optional.of(ana));
        when(membershipRepository.findByDeliveryPersonIdAndStatusIn(eq(5L), anyCollection())).thenReturn(List.of());

        assertThatThrownBy(() -> service.forMember(user, null, null)).isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void periodIsLimitedTo92Days() {
        assertThatThrownBy(() -> service.forManager(10L, TODAY.minusDays(92), TODAY))
                .isInstanceOf(BadRequestException.class);
        assertThatThrownBy(() -> service.forManager(10L, TODAY, TODAY.minusDays(1)))
                .isInstanceOf(BadRequestException.class);
    }

    @Test
    void incidentsAreCountedByTypeAndByRestaurantWithTheMostCitedFirst() {
        List<RestaurantTypeCount> rows = List.of(
                new RestaurantTypeCount(1L, "Cantina", "cantina", null, IncidentType.ORDER_NOT_READY, 1),
                new RestaurantTypeCount(2L, "Burger", "burger", null, IncidentType.ORDER_NOT_READY, 3),
                new RestaurantTypeCount(2L, "Burger", "burger", null, IncidentType.CUSTOMER_NOT_FOUND, 1),
                new RestaurantTypeCount(1L, "Cantina", "cantina", null, IncidentType.WRONG_ADDRESS, 2));

        AssociationReportDTO.Incidents incidents = AssociationReportService.incidents(rows);

        assertThat(incidents.total()).isEqualTo(7);
        assertThat(incidents.byType()).containsExactly(
                new AssociationReportDTO.TypeCount(IncidentType.ORDER_NOT_READY, 4),
                new AssociationReportDTO.TypeCount(IncidentType.WRONG_ADDRESS, 2),
                new AssociationReportDTO.TypeCount(IncidentType.CUSTOMER_NOT_FOUND, 1));
        assertThat(incidents.byRestaurant()).extracting(AssociationReportDTO.RestaurantIncidents::name)
                .containsExactly("Burger", "Cantina");
        assertThat(incidents.byRestaurant().get(0).byType()).containsExactly(
                new AssociationReportDTO.TypeCount(IncidentType.ORDER_NOT_READY, 3),
                new AssociationReportDTO.TypeCount(IncidentType.CUSTOMER_NOT_FOUND, 1));
    }

    @Test
    void withoutIncidentsTheReportShowsZero() {
        AssociationReportDTO.Incidents incidents = AssociationReportService.incidents(List.of());

        assertThat(incidents.total()).isZero();
        assertThat(incidents.byType()).isEmpty();
        assertThat(incidents.byRestaurant()).isEmpty();
    }
}
