package com.openbag.association.partnership.service;

import com.openbag.enums.CourierPolicy;
import com.openbag.enums.DeliveryFeeMode;
import com.openbag.enums.OrganizationStatus;
import com.openbag.enums.PartnershipSide;
import com.openbag.enums.PartnershipStatus;
import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.platform.web.exception.ConflictException;
import com.openbag.association.partnership.dto.RateProposalRequest;
import com.openbag.association.partnership.entity.RestaurantPartnership;
import com.openbag.association.partnership.repository.RestaurantPartnershipRepository;
import com.openbag.association.core.dto.DeliveryRateDTO;
import com.openbag.association.core.entity.DeliveryRate;
import com.openbag.association.core.entity.Organization;
import com.openbag.association.core.repository.OrganizationRepository;
import com.openbag.restaurant.store.entity.Restaurant;
import com.openbag.restaurant.store.repository.RestaurantRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class PartnershipServiceTest {

    private static final ZoneId ZONE = ZoneId.of("America/Sao_Paulo");
    private static final LocalDateTime NOW = LocalDateTime.of(2026, 9, 28, 10, 0);

    @Mock
    private RestaurantPartnershipRepository partnershipRepository;

    @Mock
    private RestaurantRepository restaurantRepository;

    @Mock
    private OrganizationRepository organizationRepository;

    @Spy
    private Clock clock = Clock.fixed(NOW.atZone(ZONE).toInstant(), ZONE);

    @InjectMocks
    private PartnershipService service;

    private Restaurant restaurant;
    private Organization organization;

    @BeforeEach
    void setUp() {
        restaurant = new Restaurant();
        restaurant.setId(1L);
        restaurant.setDeliveryFee(new BigDecimal("8.00"));

        organization = new Organization();
        organization.setId(10L);
        organization.setTradingName("Coop Centro");
        organization.setStatus(OrganizationStatus.ACTIVE);
        organization.setDeliveryRate(new DeliveryRate(new BigDecimal("7.00"), new BigDecimal("3"), BigDecimal.ONE));

        lenient().when(restaurantRepository.findById(1L)).thenReturn(Optional.of(restaurant));
        lenient().when(organizationRepository.findById(10L)).thenReturn(Optional.of(organization));
        lenient().when(partnershipRepository.findOpen(1L, 10L)).thenReturn(Optional.empty());
        lenient().when(partnershipRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
    }

    private RestaurantPartnership partnership(PartnershipStatus status, PartnershipSide requestedBy) {
        RestaurantPartnership partnership = new RestaurantPartnership();
        partnership.setId(50L);
        partnership.setRestaurant(restaurant);
        partnership.setOrganization(organization);
        partnership.setStatus(status);
        partnership.setRequestedBy(requestedBy);
        lenient().when(partnershipRepository.findWithParties(50L)).thenReturn(Optional.of(partnership));
        return partnership;
    }

    // ============= Pedido e decisão =============

    @Test
    void requestStartsPendingUntilTheOtherSideAccepts() {
        RestaurantPartnership created = service.requestByRestaurant(1L, 10L);

        assertThat(created.getStatus()).isEqualTo(PartnershipStatus.PENDING);
        assertThat(created.getRequestedBy()).isEqualTo(PartnershipSide.RESTAURANT);
    }

    @Test
    void requestAboveTheFeeNeedsTheStoreToCoverTheDifference() {
        restaurant.setDeliveryFee(new BigDecimal("6.00"));

        assertThatThrownBy(() -> service.requestByRestaurant(1L, 10L))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("assume a diferença");
        verify(partnershipRepository, never()).save(any());
    }

    @Test
    void requestingWhenTheOtherSideAlreadyInvitedStartsThePartnership() {
        RestaurantPartnership invite = partnership(PartnershipStatus.PENDING, PartnershipSide.ASSOCIATION);
        when(partnershipRepository.findOpen(1L, 10L)).thenReturn(Optional.of(invite));

        RestaurantPartnership result = service.requestByRestaurant(1L, 10L);

        assertThat(result).isSameAs(invite);
        assertThat(result.getStatus()).isEqualTo(PartnershipStatus.ACTIVE);
        assertThat(result.getDecidedAt()).isEqualTo(NOW);
    }

    @Test
    void onlyTheOtherSideAcceptsOrDeclines() {
        partnership(PartnershipStatus.PENDING, PartnershipSide.RESTAURANT);

        assertThatThrownBy(() -> service.accept(50L, PartnershipSide.RESTAURANT, 1L))
                .isInstanceOf(BadRequestException.class);
        assertThatThrownBy(() -> service.decline(50L, PartnershipSide.RESTAURANT, 1L))
                .isInstanceOf(BadRequestException.class);

        RestaurantPartnership accepted = service.accept(50L, PartnershipSide.ASSOCIATION, 10L);
        assertThat(accepted.getStatus()).isEqualTo(PartnershipStatus.ACTIVE);
    }

    @Test
    void associationCannotTouchAnotherAssociationsPartnership() {
        partnership(PartnershipStatus.PENDING, PartnershipSide.RESTAURANT);

        assertThatThrownBy(() -> service.accept(50L, PartnershipSide.ASSOCIATION, 99L))
                .hasMessageContaining("não encontrada");
    }

    @Test
    void associationDeclinesARequest() {
        partnership(PartnershipStatus.PENDING, PartnershipSide.RESTAURANT);

        RestaurantPartnership declined = service.decline(50L, PartnershipSide.ASSOCIATION, 10L);

        assertThat(declined.getStatus()).isEqualTo(PartnershipStatus.DECLINED);
    }

    @Test
    void storeAcceptingAnInviteAboveItsFeeMustCoverTheDifference() {
        restaurant.setDeliveryFee(new BigDecimal("6.00"));
        partnership(PartnershipStatus.PENDING, PartnershipSide.ASSOCIATION);

        assertThatThrownBy(() -> service.accept(50L, PartnershipSide.RESTAURANT, 1L))
                .isInstanceOf(ConflictException.class);

        restaurant.setCoversDeliveryDifference(true);
        assertThat(service.accept(50L, PartnershipSide.RESTAURANT, 1L).isActive()).isTrue();
    }

    // ============= Encerramento =============

    @Test
    void storeCannotEndItsOnlyPartnerWhileReceivingOnlyFromPartners() {
        restaurant.setCourierPolicy(CourierPolicy.PARTNERS_ONLY);
        RestaurantPartnership active = partnership(PartnershipStatus.ACTIVE, PartnershipSide.RESTAURANT);
        when(partnershipRepository.findActiveByRestaurant(1L)).thenReturn(List.of(active));

        assertThatThrownBy(() -> service.end(50L, PartnershipSide.RESTAURANT, 1L))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("única parceira");
    }

    @Test
    void associationLeavingTheLastPartnershipOpensTheStoreToAnyCourier() {
        restaurant.setCourierPolicy(CourierPolicy.PARTNERS_ONLY);
        RestaurantPartnership active = partnership(PartnershipStatus.ACTIVE, PartnershipSide.RESTAURANT);
        when(partnershipRepository.findActiveByRestaurant(1L)).thenReturn(List.of(active));

        RestaurantPartnership ended = service.end(50L, PartnershipSide.ASSOCIATION, 10L);

        assertThat(ended.getStatus()).isEqualTo(PartnershipStatus.ENDED);
        assertThat(ended.getEndedBy()).isEqualTo(PartnershipSide.ASSOCIATION);
        assertThat(restaurant.getCourierPolicy()).isEqualTo(CourierPolicy.OPEN);
        assertThat(restaurant.getPartnersEndedNoticeAt()).isEqualTo(NOW);
        verify(restaurantRepository).save(restaurant);
    }

    @Test
    void requesterCancelsItsOwnPendingRequestButMustDeclineTheOthers() {
        partnership(PartnershipStatus.PENDING, PartnershipSide.ASSOCIATION);

        assertThatThrownBy(() -> service.end(50L, PartnershipSide.RESTAURANT, 1L))
                .hasMessageContaining("Recuse");
        assertThat(service.end(50L, PartnershipSide.ASSOCIATION, 10L).getStatus()).isEqualTo(PartnershipStatus.ENDED);
    }

    @Test
    void partnershipsFromBeforeTheAcceptStepCountAsActive() {
        RestaurantPartnership legacy = new RestaurantPartnership();
        assertThat(legacy.getStatus()).isEqualTo(PartnershipStatus.ACTIVE);

        legacy.setEndedAt(NOW);
        assertThat(legacy.getStatus()).isEqualTo(PartnershipStatus.ENDED);
    }

    // ============= Tabela especial =============

    private static RateProposalRequest rate(String base, String km, String extra) {
        return new RateProposalRequest(new DeliveryRateDTO(new BigDecimal(base), new BigDecimal(km),
                new BigDecimal(extra), true), false);
    }

    @Test
    void agreedRateNeedsTheAcceptOfTheOtherSide() {
        RestaurantPartnership active = partnership(PartnershipStatus.ACTIVE, PartnershipSide.RESTAURANT);

        service.proposeRate(50L, PartnershipSide.RESTAURANT, 1L, rate("6.50", "4", "1.20"));
        assertThat(active.hasAgreedRate()).isFalse();
        assertThat(active.getEffectiveRate()).isSameAs(organization.getDeliveryRate());
        assertThatThrownBy(() -> service.acceptRate(50L, PartnershipSide.RESTAURANT, 1L))
                .isInstanceOf(BadRequestException.class);

        service.acceptRate(50L, PartnershipSide.ASSOCIATION, 10L);

        assertThat(active.hasAgreedRate()).isTrue();
        assertThat(active.getEffectiveRate().getBaseFee()).isEqualByComparingTo("6.50");
        assertThat(active.getAgreedAt()).isEqualTo(NOW);
        assertThat(active.hasRateProposal()).isFalse();
    }

    @Test
    void counterProposalReplacesTheOtherSideProposalAndPassesTheTurn() {
        RestaurantPartnership active = partnership(PartnershipStatus.ACTIVE, PartnershipSide.RESTAURANT);
        service.proposeRate(50L, PartnershipSide.ASSOCIATION, 10L, rate("7.50", "3", "1.50"));

        service.proposeRate(50L, PartnershipSide.RESTAURANT, 1L, rate("7.00", "3", "1.20"));

        assertThat(active.getRateProposedBy()).isEqualTo(PartnershipSide.RESTAURANT);
        assertThat(active.getProposedRate().getBaseFee()).isEqualByComparingTo("7.00");
        assertThat(active.getAwaitingSide()).isEqualTo(PartnershipSide.ASSOCIATION);
        assertThatThrownBy(() -> service.acceptRate(50L, PartnershipSide.RESTAURANT, 1L))
                .isInstanceOf(BadRequestException.class);

        service.acceptRate(50L, PartnershipSide.ASSOCIATION, 10L);
        assertThat(active.getAgreedRate().getExtraPerKm()).isEqualByComparingTo("1.20");
    }

    @Test
    void inviteCanCarryAProposedRateThatTheStoreAcceptsWithThePartnership() {
        DeliveryRate proposed = new DeliveryRate(new BigDecimal("7.50"), new BigDecimal("5"), BigDecimal.ONE);

        RestaurantPartnership invite = service.requestByAssociation(10L, 1L, proposed);
        assertThat(invite.getRateProposedBy()).isEqualTo(PartnershipSide.ASSOCIATION);
        assertThat(invite.getAwaitingSide()).isEqualTo(PartnershipSide.RESTAURANT);

        invite.setId(50L);
        when(partnershipRepository.findWithParties(50L)).thenReturn(Optional.of(invite));
        RestaurantPartnership accepted = service.accept(50L, PartnershipSide.RESTAURANT, 1L);

        assertThat(accepted.isActive()).isTrue();
        assertThat(accepted.getAgreedRate().getBaseFee()).isEqualByComparingTo("7.50");
        assertThat(accepted.hasRateProposal()).isFalse();
    }

    @Test
    void storeAnswersAnInviteWithACounterProposalAndTheAssociationDecides() {
        RestaurantPartnership invite = partnership(PartnershipStatus.PENDING, PartnershipSide.ASSOCIATION);

        service.proposeRate(50L, PartnershipSide.RESTAURANT, 1L, rate("6.50", "4", "1"));

        assertThat(invite.getStatus()).isEqualTo(PartnershipStatus.PENDING);
        assertThat(invite.getAwaitingSide()).isEqualTo(PartnershipSide.ASSOCIATION);
        // Quem mandou a contraproposta não aceita a própria proposta, mas pode desistir do pedido
        assertThatThrownBy(() -> service.accept(50L, PartnershipSide.RESTAURANT, 1L))
                .isInstanceOf(BadRequestException.class);
        assertThatThrownBy(() -> service.proposeRate(50L, PartnershipSide.RESTAURANT, 1L, rate("6.00", "4", "1")))
                .hasMessageContaining("Aguarde");

        RestaurantPartnership accepted = service.accept(50L, PartnershipSide.ASSOCIATION, 10L);

        assertThat(accepted.isActive()).isTrue();
        assertThat(accepted.getEffectiveRate().getBaseFee()).isEqualByComparingTo("6.50");
    }

    @Test
    void proposalCanBeDeclinedOrCancelled() {
        RestaurantPartnership active = partnership(PartnershipStatus.ACTIVE, PartnershipSide.RESTAURANT);

        service.proposeRate(50L, PartnershipSide.ASSOCIATION, 10L, rate("7.50", "3", "1.50"));
        assertThatThrownBy(() -> service.cancelRate(50L, PartnershipSide.RESTAURANT, 1L))
                .isInstanceOf(BadRequestException.class);
        service.declineRate(50L, PartnershipSide.RESTAURANT, 1L);
        assertThat(active.hasRateProposal()).isFalse();

        service.proposeRate(50L, PartnershipSide.ASSOCIATION, 10L, rate("7.50", "3", "1.50"));
        service.cancelRate(50L, PartnershipSide.ASSOCIATION, 10L);
        assertThat(active.hasRateProposal()).isFalse();
        assertThat(active.hasAgreedRate()).isFalse();
    }

    @Test
    void goingBackToTheDefaultTableAlsoNeedsTheAccept() {
        RestaurantPartnership active = partnership(PartnershipStatus.ACTIVE, PartnershipSide.RESTAURANT);
        active.setAgreedRate(new DeliveryRate(new BigDecimal("6.50"), new BigDecimal("4"), BigDecimal.ONE));

        service.proposeRate(50L, PartnershipSide.ASSOCIATION, 10L, new RateProposalRequest(null, true));
        assertThat(active.hasAgreedRate()).isTrue();

        service.acceptRate(50L, PartnershipSide.RESTAURANT, 1L);

        assertThat(active.hasAgreedRate()).isFalse();
        assertThat(active.getEffectiveRate()).isSameAs(organization.getDeliveryRate());
    }

    @Test
    void agreedRateAboveTheFeeNeedsTheStoreToCoverTheDifference() {
        partnership(PartnershipStatus.ACTIVE, PartnershipSide.RESTAURANT);
        service.proposeRate(50L, PartnershipSide.ASSOCIATION, 10L, rate("9.00", "3", "1.50"));

        assertThatThrownBy(() -> service.acceptRate(50L, PartnershipSide.RESTAURANT, 1L))
                .isInstanceOf(ConflictException.class);
    }

    @Test
    void rateCannotBeProposedOnAnEndedPartnership() {
        partnership(PartnershipStatus.ENDED, PartnershipSide.RESTAURANT);

        assertThatThrownBy(() -> service.proposeRate(50L, PartnershipSide.RESTAURANT, 1L, rate("6.00", "3", "1")))
                .hasMessageContaining("parceria ativa");
    }

    @Test
    void storeThatPassesTheFeeToTheCustomerDoesNotNeedToCoverTheDifference() {
        restaurant.setDeliveryFee(new BigDecimal("3.00"));
        restaurant.setDeliveryFeeMode(DeliveryFeeMode.PASS_THROUGH);

        RestaurantPartnership created = service.requestByRestaurant(1L, 10L);

        assertThat(created.getStatus()).isEqualTo(PartnershipStatus.PENDING);
    }

    @Test
    void pendingCountsWhatWaitsForEachSide() {
        RestaurantPartnership request = new RestaurantPartnership();
        request.setStatus(PartnershipStatus.PENDING);
        request.setRequestedBy(PartnershipSide.RESTAURANT);
        RestaurantPartnership proposal = new RestaurantPartnership();
        proposal.setStatus(PartnershipStatus.ACTIVE);
        proposal.setRateProposedBy(PartnershipSide.ASSOCIATION);

        RestaurantPartnership counter = new RestaurantPartnership();
        counter.setStatus(PartnershipStatus.PENDING);
        counter.setRequestedBy(PartnershipSide.RESTAURANT);
        counter.setRateProposedBy(PartnershipSide.ASSOCIATION);

        List<RestaurantPartnership> all = List.of(request, proposal, counter);

        assertThat(PartnershipService.pendingFor(all, PartnershipSide.ASSOCIATION)).isEqualTo(1);
        assertThat(PartnershipService.pendingFor(all, PartnershipSide.RESTAURANT)).isEqualTo(2);
    }
}
