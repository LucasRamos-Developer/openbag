package com.openbag.association.partnership.dto;

import com.openbag.modules.organization.dto.DeliveryRateDTO;
import jakarta.validation.Valid;

/**
 * Propor uma tabela especial para a parceria; sem {@code rate} (ou {@code toDefault}) = voltar à tabela da associação
 */
public record RateProposalRequest(@Valid DeliveryRateDTO rate, boolean toDefault) {
}
