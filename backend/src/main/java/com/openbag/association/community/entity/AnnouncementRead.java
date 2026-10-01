package com.openbag.association.community.entity;

import com.openbag.association.core.entity.AssociationMembership;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/** Cooperado que já leu o comunicado (um registro por comunicado e vínculo) */
@Entity
@Table(name = "association_announcement_reads",
        uniqueConstraints = @UniqueConstraint(name = "uk_announcement_reads", columnNames = {"announcement_id", "membership_id"}))
@Getter
@Setter
@NoArgsConstructor
public class AnnouncementRead {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "announcement_id", nullable = false)
    private Announcement announcement;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "membership_id", nullable = false)
    private AssociationMembership membership;

    @Column(name = "read_at", nullable = false)
    private LocalDateTime readAt;
}
