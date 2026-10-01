package com.openbag.association.community.service;

import com.openbag.account.entity.User;
import com.openbag.association.community.dto.AnnouncementDTO;
import com.openbag.association.community.dto.AnnouncementRequest;
import com.openbag.association.community.entity.Announcement;
import com.openbag.association.community.entity.AnnouncementType;
import com.openbag.association.community.repository.AnnouncementReadRepository;
import com.openbag.association.community.repository.AnnouncementRepository;
import com.openbag.association.core.entity.AssociationMembership;
import com.openbag.association.core.entity.MembershipStatus;
import com.openbag.association.core.repository.AssociationMembershipRepository;
import com.openbag.association.core.service.AssociationService;
import com.openbag.association.member.service.MemberContext;
import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.platform.web.exception.ResourceNotFoundException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Comunicados da associação (mural). O gestor publica, edita e arquiva; o cooperado ativo ou suspenso lê os não
 * arquivados, e cada leitura fica registrada para o resumo dele e para o gestor saber quantos leram.
 */
@Service
@Transactional
public class AnnouncementService {

    @Autowired
    private AnnouncementRepository announcementRepository;

    @Autowired
    private AnnouncementReadRepository readRepository;

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
    public List<AnnouncementDTO> list(Long organizationId) {
        return forManager(announcementRepository.findByOrganizationIdOrderByPublishedAtDesc(organizationId),
                organizationId);
    }

    public AnnouncementDTO publish(Long organizationId, AnnouncementRequest request, User by) {
        Announcement announcement = new Announcement();
        announcement.setOrganization(associationService.findOperational(organizationId));
        announcement.setCreatedBy(by);
        announcement.setPublishedAt(now());
        apply(announcement, request);
        return forManager(List.of(announcementRepository.save(announcement)), organizationId).get(0);
    }

    public AnnouncementDTO update(Long organizationId, Long announcementId, AnnouncementRequest request) {
        Announcement announcement = find(organizationId, announcementId);
        apply(announcement, request);
        return forManager(List.of(announcementRepository.save(announcement)), organizationId).get(0);
    }

    /** Arquivar tira o comunicado da área do cooperado; restaurar devolve */
    public AnnouncementDTO archive(Long organizationId, Long announcementId, boolean archived) {
        Announcement announcement = find(organizationId, announcementId);
        announcement.setArchivedAt(archived ? now() : null);
        return forManager(List.of(announcementRepository.save(announcement)), organizationId).get(0);
    }

    // ============= Cooperado =============

    @Transactional(readOnly = true)
    public List<AnnouncementDTO> forMember(User user) {
        AssociationMembership membership = memberContext.current(user);
        List<Announcement> announcements = announcementRepository
                .findByOrganizationIdAndArchivedAtIsNullOrderByPublishedAtDesc(membership.getOrganization().getId());
        Set<Long> read = announcements.isEmpty() ? Set.of()
                : new HashSet<>(readRepository.readBy(membership.getId(),
                announcements.stream().map(Announcement::getId).toList()));
        return announcements.stream()
                .map(a -> dto(a, null, null, read.contains(a.getId())))
                .toList();
    }

    /** Marca como lido; ler de novo não muda nada */
    public AnnouncementDTO markRead(User user, Long announcementId) {
        AssociationMembership membership = memberContext.current(user);
        Announcement announcement = find(membership.getOrganization().getId(), announcementId);
        if (announcement.getArchivedAt() != null) {
            throw new ResourceNotFoundException("Comunicado não encontrado");
        }
        readRepository.markRead(announcementId, membership.getId(), now());
        return dto(announcement, null, null, true);
    }

    // ============= Auxiliares =============

    private static void apply(Announcement announcement, AnnouncementRequest request) {
        if (request.type() == AnnouncementType.MEETING && request.eventAt() == null) {
            throw new BadRequestException("Informe a data e a hora da reunião");
        }
        announcement.setType(request.type());
        announcement.setTitle(request.title().trim());
        announcement.setBody(request.body().trim());
        boolean dated = request.type() == AnnouncementType.MEETING || request.type() == AnnouncementType.TRAINING;
        announcement.setEventAt(dated ? request.eventAt() : null);
    }

    private List<AnnouncementDTO> forManager(List<Announcement> announcements, Long organizationId) {
        if (announcements.isEmpty()) {
            return List.of();
        }
        Map<Long, Long> reads = new HashMap<>();
        for (Object[] row : readRepository.countByAnnouncement(announcements.stream().map(Announcement::getId).toList())) {
            reads.put((Long) row[0], ((Number) row[1]).longValue());
        }
        long members = membershipRepository.findByOrganizationId(organizationId).stream()
                .filter(m -> EnumSet.of(MembershipStatus.ACTIVE, MembershipStatus.SUSPENDED).contains(m.getStatus()))
                .count();
        return announcements.stream()
                .map(a -> dto(a, reads.getOrDefault(a.getId(), 0L), members, null))
                .toList();
    }

    private static AnnouncementDTO dto(Announcement a, Long readCount, Long memberCount, Boolean read) {
        return new AnnouncementDTO(a.getId(), a.getType(), a.getTitle(), a.getBody(), a.getEventAt(),
                a.getPublishedAt(), a.getArchivedAt(), readCount, memberCount, read);
    }

    private Announcement find(Long organizationId, Long announcementId) {
        return announcementRepository.findByIdAndOrganizationId(announcementId, organizationId)
                .orElseThrow(() -> new ResourceNotFoundException("Comunicado não encontrado"));
    }

    private LocalDateTime now() {
        return LocalDateTime.now(clock);
    }
}
