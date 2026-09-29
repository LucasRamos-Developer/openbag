package com.openbag.association.community.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;
import java.util.List;

public record PollRequest(
        @NotBlank(message = "Escreva a pergunta") @Size(max = 200) String question,
        @Size(max = 1000) String description,
        @Size(min = 2, max = 10, message = "A enquete precisa de 2 a 10 opções")
        List<@NotBlank(message = "Opção vazia") @Size(max = 150) String> options,
        LocalDateTime closesAt) {
}
