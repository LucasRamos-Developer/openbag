package com.openbag.association.community.dto;

import com.openbag.association.community.entity.AnnouncementType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;

/** Comunicado do gestor. {@code eventAt} é a data e hora da reunião (obrigatória) ou do treinamento. */
public record AnnouncementRequest(
        @NotNull(message = "Escolha o tipo do comunicado") AnnouncementType type,
        @NotBlank(message = "Escreva um título") @Size(max = 150, message = "Título de até 150 caracteres") String title,
        @NotBlank(message = "Escreva o comunicado") @Size(max = 2000, message = "Texto de até 2000 caracteres") String body,
        LocalDateTime eventAt) {
}
