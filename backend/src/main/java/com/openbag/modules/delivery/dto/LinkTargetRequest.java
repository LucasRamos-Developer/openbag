package com.openbag.modules.delivery.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * Alvo de um pedido de vínculo de entregador fixo: slug (ou link) do restaurante ou do perfil público do entregador
 */
@Data
public class LinkTargetRequest {

    @NotBlank(message = "Informe o link ou o identificador")
    private String target;

    /**
     * Aceita o slug puro ou um link colado (".../r/pizzaria-x" ou ".../e/joao-silva-ab12")
     */
    public String slug() {
        String value = target.trim();
        if (value.endsWith("/")) {
            value = value.substring(0, value.length() - 1);
        }
        int slash = value.lastIndexOf('/');
        return (slash >= 0 ? value.substring(slash + 1) : value).toLowerCase();
    }
}
