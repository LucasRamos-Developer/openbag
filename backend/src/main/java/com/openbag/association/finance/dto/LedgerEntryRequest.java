package com.openbag.association.finance.dto;

import com.openbag.association.finance.entity.ManualEntryKind;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDate;

/** Lançamento manual: despesa, outra entrada, contribuição avulsa para a caixinha ou auxílio a um cooperado */
public record LedgerEntryRequest(
        @NotNull(message = "Escolha o tipo do lançamento") ManualEntryKind kind,
        @NotNull(message = "Informe o valor") @DecimalMin(value = "0.01", message = "O valor deve ser maior que zero")
        BigDecimal amount,
        LocalDate date,
        @NotBlank(message = "Descreva o lançamento") @Size(max = 200) String description,
        Long membershipId) {
}
