package com.openbag.modules.cooperative.service;

import com.openbag.enums.MembershipStatus;
import com.openbag.enums.PollStatus;
import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.platform.web.exception.ResourceNotFoundException;
import com.openbag.modules.cooperative.dto.PollDTO;
import com.openbag.modules.cooperative.dto.PollRequest;
import com.openbag.modules.cooperative.entity.Poll;
import com.openbag.modules.cooperative.entity.PollOption;
import com.openbag.modules.cooperative.entity.PollVote;
import com.openbag.modules.cooperative.repository.PollRepository;
import com.openbag.modules.cooperative.repository.PollVoteRepository;
import com.openbag.modules.organization.entity.AssociationMembership;
import com.openbag.modules.organization.repository.AssociationMembershipRepository;
import com.openbag.modules.organization.service.AssociationService;
import com.openbag.modules.user.entity.User;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Enquetes da associação. O gestor cria (rascunho), abre e encerra; cada cooperado ativo vota uma vez.
 * O voto é secreto: guardamos quem votou (para não votar duas vezes), mas só as contagens saem da API.
 */
@Service
@Transactional
public class PollService {

    @Autowired
    private PollRepository pollRepository;

    @Autowired
    private PollVoteRepository voteRepository;

    @Autowired
    private AssociationMembershipRepository membershipRepository;

    @Autowired
    private AssociationService associationService;

    @Autowired
    private MemberContext memberContext;

    @Autowired
    private Clock clock;

    // ============= Gestor =============

    @Transactional(readOnly = true)
    public List<PollDTO> list(Long organizationId) {
        return toDTOs(pollRepository.findByOrganizationIdOrderByCreatedAtDesc(organizationId), organizationId, null, true);
    }

    public PollDTO create(Long organizationId, PollRequest request, User by) {
        Poll poll = new Poll();
        poll.setOrganization(associationService.findOperational(organizationId));
        poll.setStatus(PollStatus.DRAFT);
        poll.setCreatedBy(by);
        apply(poll, request);
        return toDTO(pollRepository.save(poll), organizationId);
    }

    public PollDTO update(Long organizationId, Long pollId, PollRequest request) {
        Poll poll = find(organizationId, pollId);
        if (poll.getStatus() != PollStatus.DRAFT) {
            throw new BadRequestException("Só dá para editar a enquete antes de abrir a votação");
        }
        apply(poll, request);
        return toDTO(pollRepository.save(poll), organizationId);
    }

    public PollDTO open(Long organizationId, Long pollId) {
        Poll poll = find(organizationId, pollId);
        if (poll.getStatus() != PollStatus.DRAFT) {
            throw new BadRequestException("A votação desta enquete já foi aberta");
        }
        LocalDateTime now = now();
        if (poll.getClosesAt() != null && !poll.getClosesAt().isAfter(now)) {
            throw new BadRequestException("O encerramento precisa ser no futuro");
        }
        poll.setStatus(PollStatus.OPEN);
        poll.setOpenedAt(now);
        return toDTO(pollRepository.save(poll), organizationId);
    }

    public PollDTO close(Long organizationId, Long pollId) {
        Poll poll = find(organizationId, pollId);
        if (poll.effectiveStatus(now()) != PollStatus.OPEN) {
            throw new BadRequestException("A enquete não está aberta");
        }
        poll.setStatus(PollStatus.CLOSED);
        poll.setClosedAt(now());
        return toDTO(pollRepository.save(poll), organizationId);
    }

    public void delete(Long organizationId, Long pollId) {
        Poll poll = find(organizationId, pollId);
        if (poll.getStatus() != PollStatus.DRAFT) {
            throw new BadRequestException("Só dá para apagar rascunhos; enquetes votadas ficam no histórico");
        }
        pollRepository.delete(poll);
    }

    // ============= Cooperado =============

    @Transactional(readOnly = true)
    public List<PollDTO> forMember(User user) {
        AssociationMembership membership = memberContext.current(user);
        Long organizationId = membership.getOrganization().getId();
        return toDTOs(pollRepository.findByOrganizationIdAndStatusInOrderByCreatedAtDesc(organizationId,
                EnumSet.of(PollStatus.OPEN, PollStatus.CLOSED)), organizationId, membership.getId(), false);
    }

    public PollDTO vote(User user, Long pollId, Long optionId) {
        AssociationMembership membership = memberContext.current(user);
        if (membership.getStatus() != MembershipStatus.ACTIVE) {
            throw new BadRequestException("Só cooperados ativos votam");
        }
        Long organizationId = membership.getOrganization().getId();
        Poll poll = find(organizationId, pollId);
        if (poll.effectiveStatus(now()) != PollStatus.OPEN) {
            throw new BadRequestException("A votação desta enquete está encerrada");
        }
        PollOption option = poll.getOptions().stream()
                .filter(o -> o.getId().equals(optionId))
                .findFirst()
                .orElseThrow(() -> new BadRequestException("Escolha uma das opções da enquete"));
        if (voteRepository.findByPollIdAndMembershipId(pollId, membership.getId()).isPresent()) {
            throw new BadRequestException("Você já votou nesta enquete");
        }

        PollVote vote = new PollVote();
        vote.setPoll(poll);
        vote.setOption(option);
        vote.setMembership(membership);
        voteRepository.save(vote);
        return toDTOs(List.of(poll), organizationId, membership.getId(), false).get(0);
    }

    // ============= Auxiliares =============

    private static void apply(Poll poll, PollRequest request) {
        List<String> labels = request.options() == null ? List.of()
                : request.options().stream().map(String::trim).filter(s -> !s.isEmpty()).distinct().toList();
        if (labels.size() < 2) {
            throw new BadRequestException("A enquete precisa de pelo menos 2 opções diferentes");
        }
        poll.setQuestion(request.question().trim());
        poll.setDescription(request.description() != null && !request.description().isBlank()
                ? request.description().trim() : null);
        poll.setClosesAt(request.closesAt());
        poll.getOptions().clear();
        for (int i = 0; i < labels.size(); i++) {
            PollOption option = new PollOption();
            option.setPoll(poll);
            option.setLabel(labels.get(i));
            option.setPosition(i);
            poll.getOptions().add(option);
        }
    }

    private PollDTO toDTO(Poll poll, Long organizationId) {
        return toDTOs(List.of(poll), organizationId, null, true).get(0);
    }

    /** Monta as enquetes com as contagens; {@code manager} sempre vê o resultado, o cooperado só depois de votar */
    private List<PollDTO> toDTOs(List<Poll> polls, Long organizationId, Long membershipId, boolean manager) {
        if (polls.isEmpty()) {
            return List.of();
        }
        List<Long> ids = polls.stream().map(Poll::getId).filter(java.util.Objects::nonNull).toList();
        Map<Long, Long> votesByOption = new HashMap<>();
        Map<Long, Long> votesByPoll = new HashMap<>();
        if (!ids.isEmpty()) {
            for (Object[] row : voteRepository.countByOption(ids)) {
                long count = ((Number) row[2]).longValue();
                votesByOption.put((Long) row[1], count);
                votesByPoll.merge((Long) row[0], count, Long::sum);
            }
        }
        Map<Long, Long> myChoices = new HashMap<>();
        if (membershipId != null && !ids.isEmpty()) {
            for (Object[] row : voteRepository.choicesOf(membershipId, ids)) {
                myChoices.put((Long) row[0], (Long) row[1]);
            }
        }
        long eligible = membershipRepository.findByOrganizationId(organizationId).stream()
                .filter(m -> m.getStatus() == MembershipStatus.ACTIVE)
                .count();
        LocalDateTime now = now();

        return polls.stream().map(poll -> {
            PollStatus status = poll.effectiveStatus(now);
            Long mine = myChoices.get(poll.getId());
            boolean showResults = manager || mine != null || status == PollStatus.CLOSED;
            return new PollDTO(poll.getId(), poll.getQuestion(), poll.getDescription(), status, poll.getOpenedAt(),
                    poll.getClosesAt(), poll.getClosedAt(),
                    poll.getOptions().stream()
                            .map(o -> new PollDTO.Option(o.getId(), o.getLabel(),
                                    showResults ? votesByOption.getOrDefault(o.getId(), 0L) : null))
                            .toList(),
                    showResults ? votesByPoll.getOrDefault(poll.getId(), 0L) : 0,
                    eligible, showResults, mine);
        }).toList();
    }

    private Poll find(Long organizationId, Long pollId) {
        return pollRepository.findByIdAndOrganizationId(pollId, organizationId)
                .orElseThrow(() -> new ResourceNotFoundException("Enquete não encontrada"));
    }

    private LocalDateTime now() {
        return LocalDateTime.now(clock);
    }
}
