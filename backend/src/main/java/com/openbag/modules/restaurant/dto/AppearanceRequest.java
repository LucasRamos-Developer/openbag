package com.openbag.modules.restaurant.dto;

import com.openbag.enums.RestaurantThemePreset;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Aparência da página pública: tema, cor da marca opcional e slogan do banner
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class AppearanceRequest {

    public static final String HEX_COLOR = "^#[0-9A-Fa-f]{6}$";

    @NotNull(message = "Tema é obrigatório")
    private RestaurantThemePreset themePreset;

    /** Nula para usar a cor principal do tema */
    @Pattern(regexp = HEX_COLOR, message = "Cor da marca deve estar no formato hexadecimal (ex: #FF0000)")
    private String brandColor;

    @Size(max = 80, message = "O slogan deve ter no máximo 80 caracteres")
    private String slogan;
}
