package com.openbag.association.community.entity;

import com.openbag.enums.PollStatus;
import com.openbag.association.core.entity.Organization;
import com.openbag.modules.user.entity.User;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Enquete da associação: o gestor escreve (rascunho), abre para votação e encerra (ou ela encerra sozinha em
 * {@code closesAt}). Cada cooperado ativo vota uma vez; o voto é secreto (só as contagens aparecem).
 */
@Entity
@Table(name = "association_polls", indexes = @Index(name = "idx_polls_organization", columnList = "organization_id"))
@Getter
@Setter
@NoArgsConstructor
public class Poll {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "organization_id", nullable = false)
    private Organization organization;

    @Column(nullable = false, length = 200)
    private String question;

    @Column(length = 1000)
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private PollStatus status;

    @Column(name = "opened_at")
    private LocalDateTime openedAt;

    /** Encerramento automático (nulo = até o gestor encerrar) */
    @Column(name = "closes_at")
    private LocalDateTime closesAt;

    @Column(name = "closed_at")
    private LocalDateTime closedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by_id")
    private User createdBy;

    @OneToMany(mappedBy = "poll", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("position")
    private List<PollOption> options = new ArrayList<>();

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    /** A situação de fato: aberta que passou do prazo conta como encerrada */
    public PollStatus effectiveStatus(LocalDateTime now) {
        if (status == PollStatus.OPEN && closesAt != null && !closesAt.isAfter(now)) {
            return PollStatus.CLOSED;
        }
        return status;
    }
}
