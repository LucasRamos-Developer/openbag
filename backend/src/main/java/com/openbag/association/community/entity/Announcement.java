package com.openbag.association.community.entity;

import com.openbag.account.entity.User;
import com.openbag.association.core.entity.Organization;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * Comunicado da associação para os cooperados (mural): aviso, reunião, mudança operacional, alteração de valor,
 * nova parceria ou treinamento. Publicado na hora; arquivado sai da área do cooperado e fica no histórico.
 */
@Entity
@Table(name = "association_announcements",
        indexes = @Index(name = "idx_announcements_organization", columnList = "organization_id, published_at"))
@Getter
@Setter
@NoArgsConstructor
public class Announcement {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "organization_id", nullable = false)
    private Organization organization;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private AnnouncementType type;

    @Column(nullable = false, length = 150)
    private String title;

    @Column(nullable = false, length = 2000)
    private String body;

    /** Data e hora da reunião ou do treinamento */
    @Column(name = "event_at")
    private LocalDateTime eventAt;

    @Column(name = "published_at", nullable = false)
    private LocalDateTime publishedAt;

    @Column(name = "archived_at")
    private LocalDateTime archivedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by_id")
    private User createdBy;
}
