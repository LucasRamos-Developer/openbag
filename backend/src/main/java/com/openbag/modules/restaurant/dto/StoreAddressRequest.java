package com.openbag.modules.restaurant.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Endereço do restaurante (aba Loja › Endereço). Latitude e longitude são opcionais.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class StoreAddressRequest {

    @NotBlank(message = "CEP é obrigatório")
    @Size(max = 10, message = "CEP deve ter no máximo 10 caracteres")
    private String zipCode;

    @NotBlank(message = "Rua é obrigatória")
    @Size(max = 200, message = "Rua deve ter no máximo 200 caracteres")
    private String street;

    @NotBlank(message = "Número é obrigatório")
    @Size(max = 10, message = "Número deve ter no máximo 10 caracteres")
    private String number;

    @Size(max = 100, message = "Complemento deve ter no máximo 100 caracteres")
    private String complement;

    @NotBlank(message = "Bairro é obrigatório")
    @Size(max = 100, message = "Bairro deve ter no máximo 100 caracteres")
    private String neighborhood;

    @NotBlank(message = "Cidade é obrigatória")
    @Size(max = 100, message = "Cidade deve ter no máximo 100 caracteres")
    private String city;

    @NotBlank(message = "Estado é obrigatório")
    @Size(max = 50, message = "Estado deve ter no máximo 50 caracteres")
    private String state;

    private BigDecimal latitude;
    private BigDecimal longitude;
}
