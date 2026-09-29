package com.openbag.association.core.entity;

import com.openbag.account.entity.User;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

/**
 * Código de convite gerado pelo gestor. O entregador que se cadastra com um convite
 * válido entra direto como associado ativo, sem passar pela aprovação.
 */
@Entity
@Table(name = "association_invites")
@Getter
@Setter
@NoArgsConstructor
public class AssociationInvite {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 12)
    private String code;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "organization_id", nullable = false)
    private Organization organization;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by_id")
    private User createdBy;

    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;

    // null = usos ilimitados
    @Column(name = "max_uses")
    private Integer maxUses;

    @Column(name = "uses_count", nullable = false)
    private int usesCount = 0;

    @Column(nullable = false)
    private boolean active = true;

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    public boolean isUsable() {
        return active
                && expiresAt.isAfter(LocalDateTime.now())
                && (maxUses == null || usesCount < maxUses);
    }
}
