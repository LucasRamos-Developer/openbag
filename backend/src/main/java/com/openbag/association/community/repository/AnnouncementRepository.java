package com.openbag.association.community.repository;

import com.openbag.association.community.entity.Announcement;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface AnnouncementRepository extends JpaRepository<Announcement, Long> {

    List<Announcement> findByOrganizationIdOrderByPublishedAtDesc(Long organizationId);

    List<Announcement> findByOrganizationIdAndArchivedAtIsNullOrderByPublishedAtDesc(Long organizationId);

    Optional<Announcement> findByIdAndOrganizationId(Long id, Long organizationId);
}
