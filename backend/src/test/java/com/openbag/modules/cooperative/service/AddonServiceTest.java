package com.openbag.modules.cooperative.service;

import com.openbag.enums.AddonPricing;
import com.openbag.enums.MemberAddonStatus;
import com.openbag.enums.MembershipStatus;
import com.openbag.modules.cooperative.entity.AddonPlan;
import com.openbag.modules.cooperative.entity.MemberAddon;
import com.openbag.modules.cooperative.repository.AddonPlanRepository;
import com.openbag.modules.cooperative.repository.MemberAddonRepository;
import com.openbag.delivery.courier.entity.DeliveryPerson;
import com.openbag.modules.organization.entity.AssociationMembership;
import com.openbag.modules.organization.repository.AssociationMembershipRepository;
import com.openbag.modules.organization.service.AssociationService;
import com.openbag.modules.user.entity.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
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
class AddonServiceTest {

    private static final ZoneId ZONE = ZoneId.of("America/Sao_Paulo");
    private static final LocalDateTime NOW = LocalDateTime.of(2026, 9, 28, 10, 0);

    @Mock private AddonPlanRepository planRepository;
    @Mock private MemberAddonRepository memberAddonRepository;
    @Mock private AssociationMembershipRepository membershipRepository;
    @Mock private AssociationService associationService;
    @Mock private MemberContext memberContext;
    @Spy private Clock clock = Clock.fixed(NOW.atZone(ZONE).toInstant(), ZONE);

    @InjectMocks
    private AddonService service;

    private AddonPlan insurance;
    private AssociationMembership ana;
    private AssociationMembership bruno;

    @BeforeEach
    void setUp() {
        insurance = new AddonPlan();
        insurance.setId(3L);
        insurance.setName("Seguro de vida");
        insurance.setPricing(AddonPricing.PERCENT_OF_FEE);
        insurance.setValue(BigDecimal.TEN);
        ana = membership(1L, MembershipStatus.ACTIVE);
        bruno = membership(2L, MembershipStatus.ACTIVE);
        lenient().when(planRepository.findByIdAndOrganizationId(3L, 10L)).thenReturn(Optional.of(insurance));
        lenient().when(memberAddonRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
    }

    private static AssociationMembership membership(Long id, MembershipStatus status) {
        User user = new User();
        user.setFullName("Cooperado " + id);
        DeliveryPerson courier = new DeliveryPerson();
        courier.setUser(user);
        AssociationMembership membership = new AssociationMembership();
        membership.setId(id);
        membership.setStatus(status);
        membership.setDeliveryPerson(courier);
        return membership;
    }

    @Test
    void proposesToEveryActiveMemberWhoDoesNotHaveItYet() {
        AssociationMembership left = membership(9L, MembershipStatus.LEFT);
        when(membershipRepository.findByOrganizationId(10L)).thenReturn(List.of(ana, bruno, left));
        when(memberAddonRepository.existsOpen(1L, 3L)).thenReturn(true);
        when(memberAddonRepository.existsOpen(2L, 3L)).thenReturn(false);

        int proposed = service.propose(10L, 3L, null);

        assertThat(proposed).isEqualTo(1);
        ArgumentCaptor<MemberAddon> saved = ArgumentCaptor.forClass(MemberAddon.class);
        verify(memberAddonRepository).save(saved.capture());
        assertThat(saved.getValue().getMembership()).isSameAs(bruno);
        assertThat(saved.getValue().getStatus()).isEqualTo(MemberAddonStatus.PROPOSED);
    }

    @Test
    void inactivePlanIsNotProposed() {
        insurance.setActive(false);

        assertThatThrownBy(() -> service.propose(10L, 3L, null)).hasMessageContaining("Reative");
    }

    @Test
    void memberAcceptsOnlyHisOwnProposal() {
        User user = new User();
        when(memberContext.current(user)).thenReturn(ana);
        MemberAddon mine = new MemberAddon();
        mine.setId(20L);
        mine.setMembership(ana);
        mine.setPlan(insurance);
        mine.setStatus(MemberAddonStatus.PROPOSED);
        MemberAddon someoneElses = new MemberAddon();
        someoneElses.setMembership(bruno);
        when(memberAddonRepository.findById(20L)).thenReturn(Optional.of(mine));
        when(memberAddonRepository.findById(21L)).thenReturn(Optional.of(someoneElses));

        assertThatThrownBy(() -> service.answer(user, 21L, "accept")).hasMessageContaining("não encontrado");

        service.answer(user, 20L, "accept");
        assertThat(mine.getStatus()).isEqualTo(MemberAddonStatus.ACTIVE);
        assertThat(mine.getDecidedAt()).isEqualTo(NOW);
        assertThatThrownBy(() -> service.answer(user, 20L, "decline")).hasMessageContaining("não está aguardando");

        service.answer(user, 20L, "cancel");
        assertThat(mine.getStatus()).isEqualTo(MemberAddonStatus.CANCELLED);
    }
}
