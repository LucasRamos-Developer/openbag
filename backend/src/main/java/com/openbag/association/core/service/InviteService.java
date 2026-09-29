package com.openbag.association.core.service;

import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.platform.web.exception.ResourceNotFoundException;
import com.openbag.association.core.dto.AssociationSummaryDTO;
import com.openbag.association.core.dto.CreateInviteRequest;
import com.openbag.association.core.dto.InviteDTO;
import com.openbag.association.core.entity.AssociationInvite;
import com.openbag.association.core.entity.Organization;
import com.openbag.association.core.repository.AssociationInviteRepository;
import com.openbag.modules.user.entity.User;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Locale;

/**
 * Códigos de convite para entrada direta de entregadores em uma associação
 */
@Service
@Transactional
@Slf4j
public class InviteService {

    // Sem caracteres ambíguos (0/O, 1/I/L) para facilitar a digitação
    private static final String CODE_ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
    private static final int CODE_LENGTH = 8;
    private static final int DEFAULT_EXPIRATION_DAYS = 7;

    private final SecureRandom random = new SecureRandom();

    @Autowired
    private AssociationInviteRepository inviteRepository;

    @Autowired
    private AssociationService associationService;

    @Transactional(readOnly = true)
    public List<InviteDTO> listInvites(Long organizationId) {
        return inviteRepository.findByOrganizationIdOrderByCreatedAtDesc(organizationId).stream()
                .map(InviteDTO::from)
                .toList();
    }

    public InviteDTO createInvite(Long organizationId, CreateInviteRequest request, User manager) {
        Organization organization = associationService.findOperational(organizationId);
        int days = request != null && request.getExpiresInDays() != null
                ? request.getExpiresInDays()
                : DEFAULT_EXPIRATION_DAYS;

        AssociationInvite invite = new AssociationInvite();
        invite.setCode(generateUniqueCode());
        invite.setOrganization(organization);
        invite.setCreatedBy(manager);
        invite.setExpiresAt(LocalDateTime.now().plusDays(days));
        invite.setMaxUses(request != null ? request.getMaxUses() : null);

        AssociationInvite saved = inviteRepository.save(invite);
        log.info("Convite {} criado para a associação {}", saved.getCode(), organizationId);
        return InviteDTO.from(saved);
    }

    public InviteDTO revokeInvite(Long organizationId, Long inviteId) {
        AssociationInvite invite = inviteRepository.findByIdAndOrganizationId(inviteId, organizationId)
                .orElseThrow(() -> new ResourceNotFoundException("Convite não encontrado"));
        invite.setActive(false);
        return InviteDTO.from(inviteRepository.save(invite));
    }

    /**
     * Valida um código de convite (endpoint público) e retorna a associação de destino
     */
    @Transactional(readOnly = true)
    public AssociationSummaryDTO validateInvite(String code) {
        AssociationInvite invite = inviteRepository.findByCode(normalize(code))
                .orElseThrow(() -> new ResourceNotFoundException("Convite não encontrado"));
        checkUsable(invite);
        return AssociationSummaryDTO.from(invite.getOrganization());
    }

    /**
     * Consome um uso do convite (com lock), validando validade, limite e status da associação
     * @return o convite consumido
     */
    AssociationInvite consume(String code) {
        AssociationInvite invite = inviteRepository.findByCodeForUpdate(normalize(code))
                .orElseThrow(() -> new BadRequestException("Código de convite inválido"));
        checkUsable(invite);
        invite.setUsesCount(invite.getUsesCount() + 1);
        return inviteRepository.save(invite);
    }

    private void checkUsable(AssociationInvite invite) {
        if (!invite.isUsable()) {
            throw new BadRequestException("Convite expirado, revogado ou sem usos disponíveis");
        }
        if (!invite.getOrganization().isOperational()) {
            throw new BadRequestException("A associação deste convite não está ativa");
        }
    }

    private String normalize(String code) {
        if (code == null || code.isBlank()) {
            throw new BadRequestException("Código de convite é obrigatório");
        }
        return code.trim().toUpperCase(Locale.ROOT);
    }

    private String generateUniqueCode() {
        String code;
        do {
            StringBuilder builder = new StringBuilder(CODE_LENGTH);
            for (int i = 0; i < CODE_LENGTH; i++) {
                builder.append(CODE_ALPHABET.charAt(random.nextInt(CODE_ALPHABET.length())));
            }
            code = builder.toString();
        } while (inviteRepository.existsByCode(code));
        return code;
    }
}
