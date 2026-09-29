package com.openbag.restaurant.store.dto;

import com.openbag.restaurant.store.entity.RestaurantThemePreset;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Aparência escolhida no cadastro. primary/secondary são o formato antigo (cor livre):
 * se vierem sem tema, a primária vira a cor da marca sobre o tema padrão.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class LayoutConfigDTO {

    private RestaurantThemePreset themePreset;

    @Pattern(regexp = AppearanceRequest.HEX_COLOR, message = "Cor da marca deve estar no formato hexadecimal (ex: #FF0000)")
    private String brandColor;

    @Size(max = 80, message = "O slogan deve ter no máximo 80 caracteres")
    private String slogan;

    @Pattern(regexp = AppearanceRequest.HEX_COLOR, message = "Cor primária deve estar no formato hexadecimal (ex: #FF0000)")
    private String primaryColor;

    @Pattern(regexp = AppearanceRequest.HEX_COLOR, message = "Cor secundária deve estar no formato hexadecimal (ex: #000000)")
    private String secondaryColor;
}
