package com.openbag.modules.organization.service;

import com.openbag.enums.MembershipOrigin;
import com.openbag.enums.MembershipStatus;
import com.openbag.enums.OrganizationStatus;
import com.openbag.exception.BadRequestException;
import com.openbag.exception.ResourceNotFoundException;
import com.openbag.modules.delivery.entity.DeliveryPerson;
import com.openbag.modules.delivery.repository.DeliveryPersonRepository;
import com.openbag.modules.delivery.service.CourierProfileService;
import com.openbag.modules.organization.dto.JoinAssociationRequest;
import com.openbag.modules.organization.dto.MemberDTO;
import com.openbag.modules.organization.entity.AssociationInvite;
import com.openbag.modules.organization.entity.AssociationMembership;
import com.openbag.modules.organization.entity.Organization;
import com.openbag.modules.organization.repository.AssociationMembershipRepository;
import com.openbag.modules.user.entity.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class MembershipServiceTest {

    private static final long ORG_ID = 10L;

    @Mock
    private AssociationMembershipRepository membershipRepository;

    @Mock
    private DeliveryPersonRepository deliveryPersonRepository;

    @Mock
    private AssociationService associationService;

    @Mock
    private InviteService inviteService;

    @Mock
    private CourierProfileService courierProfileService;

    @InjectMocks
    private MembershipService membershipService;

    private Organization organization;
    private DeliveryPerson deliveryPerson;
    private User manager;

    @BeforeEach
    void setUp() {
        organization = new Organization();
        organization.setId(ORG_ID);
        organization.setTradingName("Coop Teste");
        organization.setStatus(OrganizationStatus.ACTIVE);

        User courier = new User();
        courier.setId(2L);
        courier.setFullName("Entregador");
        deliveryPerson = new DeliveryPerson();
        deliveryPerson.setId(3L);
        deliveryPerson.setUser(courier);
        deliveryPerson.setActive(false);

        manager = new User();
        manager.setId(1L);

        lenient().when(associationService.findOperational(ORG_ID)).thenReturn(organization);
        lenient().when(membershipRepository.save(any(AssociationMembership.class))).thenAnswer(inv -> inv.getArgument(0));
    }

    private AssociationMembership membership(MembershipStatus status) {
        AssociationMembership membership = new AssociationMembership();
        membership.setId(50L);
        membership.setOrganization(organization);
        membership.setDeliveryPerson(deliveryPerson);
        membership.setStatus(status);
        membership.setOrigin(MembershipOrigin.SELF_REQUEST);
        membership.setRequestedAt(LocalDateTime.now());
        when(membershipRepository.findByIdAndOrganizationId(50L, ORG_ID)).thenReturn(Optional.of(membership));
        return membership;
    }

    @Test
    void approvingPendingActivatesCourierAndAssignsNextMemberNumber() {
        membership(MembershipStatus.PENDING);
        when(membershipRepository.findMaxMemberNumber(ORG_ID)).thenReturn(7);

        MemberDTO result = membershipService.approve(ORG_ID, 50L, manager);

        assertThat(result.getStatus()).isEqualTo(MembershipStatus.ACTIVE);
        assertThat(result.getMemberNumber()).isEqualTo(8);
        assertThat(deliveryPerson.isActive()).isTrue();
        assertThat(deliveryPerson.getOrganization()).isSameAs(organization);
    }

    @Test
    void reactivatingKeepsTheOriginalMemberNumber() {
        AssociationMembership membership = membership(MembershipStatus.SUSPENDED);
        membership.setMemberNumber(3);

        MemberDTO result = membershipService.reactivate(ORG_ID, 50L, manager);

        assertThat(result.getMemberNumber()).isEqualTo(3);
        verify(membershipRepository, never()).findMaxMemberNumber(anyLong());
    }

    @Test
    void suspendingDeactivatesCourierButKeepsAssociation() {
        membership(MembershipStatus.ACTIVE);
        deliveryPerson.setActive(true);
        deliveryPerson.setAvailable(true);
        deliveryPerson.setOrganization(organization);

        MemberDTO result = membershipService.suspend(ORG_ID, 50L, "Documentação vencida", manager);

        assertThat(result.getStatus()).isEqualTo(MembershipStatus.SUSPENDED);
        assertThat(result.getReason()).isEqualTo("Documentação vencida");
        assertThat(deliveryPerson.isActive()).isFalse();
        assertThat(deliveryPerson.isAvailable()).isFalse();
        assertThat(deliveryPerson.getOrganization()).isSameAs(organization);
    }

    @Test
    void removingEndsMembershipAndUnlinksCourier() {
        membership(MembershipStatus.ACTIVE);
        deliveryPerson.setOrganization(organization);

        MemberDTO result = membershipService.remove(ORG_ID, 50L, null, manager);

        assertThat(result.getStatus()).isEqualTo(MembershipStatus.REMOVED);
        assertThat(result.getEndedAt()).isNotNull();
        assertThat(deliveryPerson.getOrganization()).isNull();
        assertThat(deliveryPerson.isActive()).isFalse();
    }

    @Test
    void invalidTransitionIsRejected() {
        membership(MembershipStatus.PENDING);

        assertThatThrownBy(() -> membershipService.suspend(ORG_ID, 50L, null, manager))
                .isInstanceOf(BadRequestException.class);
        verify(membershipRepository, never()).save(any());
    }

    @Test
    void membershipFromAnotherOrganizationIsNotFound() {
        when(membershipRepository.findByIdAndOrganizationId(50L, ORG_ID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> membershipService.approve(ORG_ID, 50L, manager))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void courierWithOpenMembershipCannotJoinAnotherAssociation() {
        when(deliveryPersonRepository.findByUserIdForUpdate(2L)).thenReturn(Optional.of(deliveryPerson));
        AssociationMembership open = new AssociationMembership();
        open.setStatus(MembershipStatus.ACTIVE);
        when(membershipRepository.findByDeliveryPersonIdAndStatusIn(eq(3L), any())).thenReturn(List.of(open));

        assertThatThrownBy(() -> membershipService.requestToJoin(deliveryPerson.getUser(),
                new JoinAssociationRequest(99L, null)))
                .isInstanceOf(BadRequestException.class);
        verify(inviteService, never()).consume(any());
    }

    @Test
    void joiningWithInviteActivatesImmediately() {
        when(deliveryPersonRepository.findByUserIdForUpdate(2L)).thenReturn(Optional.of(deliveryPerson));
        when(membershipRepository.findByDeliveryPersonIdAndStatusIn(eq(3L), any())).thenReturn(List.of());
        AssociationInvite invite = new AssociationInvite();
        invite.setOrganization(organization);
        when(inviteService.consume("ABCD2345")).thenReturn(invite);
        when(membershipRepository.findMaxMemberNumber(ORG_ID)).thenReturn(0);

        MemberDTO result = membershipService.requestToJoin(deliveryPerson.getUser(),
                new JoinAssociationRequest(null, "ABCD2345"));

        assertThat(result.getStatus()).isEqualTo(MembershipStatus.ACTIVE);
        assertThat(result.getOrigin()).isEqualTo(MembershipOrigin.INVITE);
        assertThat(result.getMemberNumber()).isEqualTo(1);
    }

    @Test
    void joiningWithoutInviteStaysPendingAndInactive() {
        when(deliveryPersonRepository.findByUserIdForUpdate(2L)).thenReturn(Optional.of(deliveryPerson));
        when(membershipRepository.findByDeliveryPersonIdAndStatusIn(eq(3L), any())).thenReturn(List.of());

        MemberDTO result = membershipService.requestToJoin(deliveryPerson.getUser(),
                new JoinAssociationRequest(ORG_ID, null));

        assertThat(result.getStatus()).isEqualTo(MembershipStatus.PENDING);
        assertThat(result.getMemberNumber()).isNull();
        assertThat(result.getDecidedAt()).isNull();
        assertThat(deliveryPerson.isActive()).isFalse();
    }

    @Test
    void inviteUsabilityRespectsLimitExpirationAndRevocation() {
        AssociationInvite invite = new AssociationInvite();
        invite.setExpiresAt(LocalDateTime.now().plusDays(1));
        invite.setMaxUses(1);
        assertThat(invite.isUsable()).isTrue();

        invite.setUsesCount(1);
        assertThat(invite.isUsable()).isFalse();

        invite.setMaxUses(null);
        assertThat(invite.isUsable()).isTrue();

        invite.setExpiresAt(LocalDateTime.now().minusMinutes(1));
        assertThat(invite.isUsable()).isFalse();

        invite.setExpiresAt(LocalDateTime.now().plusDays(1));
        invite.setActive(false);
        assertThat(invite.isUsable()).isFalse();
    }
}
