package com.openbag.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class LayoutConfigDTO {

    @NotBlank(message = "Cor primária é obrigatória")
    @Pattern(regexp = "^#[0-9A-Fa-f]{6}$", message = "Cor primária deve estar no formato hexadecimal (ex: #FF0000)")
    private String primaryColor;

    @NotBlank(message = "Cor secundária é obrigatória")
    @Pattern(regexp = "^#[0-9A-Fa-f]{6}$", message = "Cor secundária deve estar no formato hexadecimal (ex: #000000)")
    private String secondaryColor;
}
