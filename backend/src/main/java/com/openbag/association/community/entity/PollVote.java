package com.openbag.association.community.entity;

import com.openbag.association.core.entity.AssociationMembership;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

/** Voto de um cooperado: um por enquete (restrição no banco) */
@Entity
@Table(name = "association_poll_votes",
        uniqueConstraints = @UniqueConstraint(name = "uk_poll_votes_poll_membership",
                columnNames = {"poll_id", "membership_id"}))
@Getter
@Setter
@NoArgsConstructor
public class PollVote {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "poll_id", nullable = false)
    private Poll poll;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "option_id", nullable = false)
    private PollOption option;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "membership_id", nullable = false)
    private AssociationMembership membership;

    @CreationTimestamp
    @Column(name = "voted_at")
    private LocalDateTime votedAt;
}
