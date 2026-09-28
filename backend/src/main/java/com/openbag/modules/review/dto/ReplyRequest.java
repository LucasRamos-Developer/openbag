package com.openbag.modules.review.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Resposta da loja a uma avaliação */
public record ReplyRequest(@NotBlank @Size(max = 500) String reply) {
}
