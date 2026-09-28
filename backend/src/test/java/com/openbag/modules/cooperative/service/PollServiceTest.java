package com.openbag.modules.cooperative.service;

import com.openbag.enums.MembershipStatus;
import com.openbag.enums.PollStatus;
import com.openbag.modules.cooperative.dto.PollDTO;
import com.openbag.modules.cooperative.dto.PollRequest;
import com.openbag.modules.cooperative.entity.Poll;
import com.openbag.modules.cooperative.entity.PollOption;
import com.openbag.modules.cooperative.entity.PollVote;
import com.openbag.modules.cooperative.repository.PollRepository;
import com.openbag.modules.cooperative.repository.PollVoteRepository;
import com.openbag.modules.organization.entity.AssociationMembership;
import com.openbag.modules.organization.entity.Organization;
import com.openbag.modules.organization.repository.AssociationMembershipRepository;
import com.openbag.modules.organization.service.AssociationService;
import com.openbag.modules.user.entity.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Clock;
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

@ExtendWith(MockitoExtension.class)
class PollServiceTest {

    private static final ZoneId ZONE = ZoneId.of("America/Sao_Paulo");
    private static final LocalDateTime NOW = LocalDateTime.of(2026, 9, 28, 10, 0);

    @Mock private PollRepository pollRepository;
    @Mock private PollVoteRepository voteRepository;
    @Mock private AssociationMembershipRepository membershipRepository;
    @Mock private AssociationService associationService;
    @Mock private MemberContext memberContext;
    @Spy private Clock clock = Clock.fixed(NOW.atZone(ZONE).toInstant(), ZONE);

    @InjectMocks
    private PollService service;

    private Organization organization;
    private AssociationMembership ana;
    private Poll poll;
    private User user;

    @BeforeEach
    void setUp() {
        organization = new Organization();
        organization.setId(10L);
        ana = new AssociationMembership();
        ana.setId(1L);
        ana.setOrganization(organization);
        ana.setStatus(MembershipStatus.ACTIVE);
        user = new User();

        poll = new Poll();
        poll.setId(5L);
        poll.setOrganization(organization);
        poll.setQuestion("Assembleia no sábado ou no domingo?");
        poll.setStatus(PollStatus.OPEN);
        poll.getOptions().add(option(50L, "Sábado"));
        poll.getOptions().add(option(51L, "Domingo"));

        lenient().when(memberContext.current(user)).thenReturn(ana);
        lenient().when(pollRepository.findByIdAndOrganizationId(5L, 10L)).thenReturn(Optional.of(poll));
        lenient().when(membershipRepository.findByOrganizationId(10L)).thenReturn(List.of(ana));
        lenient().when(voteRepository.countByOption(any())).thenReturn(List.of());
        lenient().when(voteRepository.choicesOf(anyLong(), any())).thenReturn(List.of());
    }

    private PollOption option(Long id, String label) {
        PollOption option = new PollOption();
        option.setId(id);
        option.setPoll(poll);
        option.setLabel(label);
        return option;
    }

    @Test
    void activeMemberVotesOnceAndOnlyThenSeesTheResult() {
        when(pollRepository.findByOrganizationIdAndStatusInOrderByCreatedAtDesc(eq(10L), any())).thenReturn(List.of(poll));
        PollDTO before = service.forMember(user).get(0);
        assertThat(before.showResults()).isFalse();
        assertThat(before.options()).allMatch(o -> o.votes() == null);

        when(voteRepository.findByPollIdAndMembershipId(5L, 1L)).thenReturn(Optional.empty());
        when(voteRepository.countByOption(any())).thenReturn(List.<Object[]>of(new Object[]{5L, 50L, 1L}));
        when(voteRepository.choicesOf(anyLong(), any())).thenReturn(List.<Object[]>of(new Object[]{5L, 50L}));

        PollDTO after = service.vote(user, 5L, 50L);

        verify(voteRepository).save(any(PollVote.class));
        assertThat(after.showResults()).isTrue();
        assertThat(after.myOptionId()).isEqualTo(50L);
        assertThat(after.totalVotes()).isEqualTo(1);

        when(voteRepository.findByPollIdAndMembershipId(5L, 1L)).thenReturn(Optional.of(new PollVote()));
        assertThatThrownBy(() -> service.vote(user, 5L, 51L)).hasMessageContaining("já votou");
    }

    @Test
    void suspendedMembersAndClosedPollsDoNotVote() {
        ana.setStatus(MembershipStatus.SUSPENDED);
        assertThatThrownBy(() -> service.vote(user, 5L, 50L)).hasMessageContaining("ativos");

        ana.setStatus(MembershipStatus.ACTIVE);
        poll.setClosesAt(NOW.minusMinutes(1));
        assertThatThrownBy(() -> service.vote(user, 5L, 50L)).hasMessageContaining("encerrada");
        assertThat(poll.effectiveStatus(NOW)).isEqualTo(PollStatus.CLOSED);
    }

    @Test
    void voteMustBeOneOfThePollOptions() {
        assertThatThrownBy(() -> service.vote(user, 5L, 99L)).hasMessageContaining("uma das opções");
    }

    @Test
    void pollNeedsTwoDifferentOptionsAndOnlyDraftsCanBeEdited() {
        when(associationService.findOperational(10L)).thenReturn(organization);

        assertThatThrownBy(() -> service.create(10L, new PollRequest("Pergunta?", null, List.of("Sim", " Sim "), null), user))
                .hasMessageContaining("2 opções diferentes");
        assertThatThrownBy(() -> service.update(10L, 5L, new PollRequest("Nova?", null, List.of("A", "B"), null)))
                .hasMessageContaining("antes de abrir");
        assertThatThrownBy(() -> service.delete(10L, 5L)).hasMessageContaining("rascunhos");
    }
}
