package com.openbag.association.community.dto;

import com.openbag.association.community.entity.BenefitCategory;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

public record BenefitRequest(
        @NotBlank(message = "Informe o parceiro") @Size(max = 120) String partnerName,
        @NotNull(message = "Escolha a categoria") BenefitCategory category,
        @NotBlank(message = "Descreva o benefício em poucas palavras") @Size(max = 120) String headline,
        @Size(max = 1000) String description,
        @Size(max = 250) String address,
        @Size(max = 20) String phone,
        @Size(max = 300) @Pattern(regexp = "^$|^https?://.+", message = "O link deve começar com http:// ou https://")
        String link,
        LocalDate validUntil,
        Boolean active) {
}
