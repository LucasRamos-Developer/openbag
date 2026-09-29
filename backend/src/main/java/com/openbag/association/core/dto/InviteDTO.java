package com.openbag.association.core.dto;

import com.openbag.association.core.entity.AssociationInvite;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InviteDTO {

    private Long id;
    private String code;
    private LocalDateTime expiresAt;
    private Integer maxUses;
    private int usesCount;
    private boolean active;
    private boolean usable;
    private LocalDateTime createdAt;
    private String createdByName;

    public static InviteDTO from(AssociationInvite invite) {
        return InviteDTO.builder()
                .id(invite.getId())
                .code(invite.getCode())
                .expiresAt(invite.getExpiresAt())
                .maxUses(invite.getMaxUses())
                .usesCount(invite.getUsesCount())
                .active(invite.isActive())
                .usable(invite.isUsable())
                .createdAt(invite.getCreatedAt())
                .createdByName(invite.getCreatedBy() != null ? invite.getCreatedBy().getFullName() : null)
                .build();
    }
}
