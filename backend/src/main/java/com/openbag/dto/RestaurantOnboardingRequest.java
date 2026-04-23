package com.openbag.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class RestaurantOnboardingRequest {

    @Valid
    @NotNull(message = "Dados do proprietário são obrigatórios")
    private OwnerData owner;

    @Valid
    @NotNull(message = "Dados do restaurante são obrigatórios")
    private RestaurantData restaurant;

    @Valid
    @NotNull(message = "Endereço é obrigatório")
    private AddressDTO address;

    @Valid
    @NotEmpty(message = "Horários de funcionamento são obrigatórios")
    @Size(min = 1, message = "Deve haver pelo menos um horário de funcionamento")
    private List<OpeningHourDTO> openingHours;

    @Valid
    @NotNull(message = "Configuração de layout é obrigatória")
    private LayoutConfigDTO layoutConfig;

    @NotEmpty(message = "Categorias são obrigatórias")
    private List<Long> categoryIds;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class OwnerData {
        @NotBlank(message = "Nome completo é obrigatório")
        @Size(max = 100, message = "Nome completo deve ter no máximo 100 caracteres")
        private String fullName;

        @NotBlank(message = "Email é obrigatório")
        @Email(message = "Email deve ter um formato válido")
        @Size(max = 100, message = "Email deve ter no máximo 100 caracteres")
        private String email;

        @NotBlank(message = "Telefone é obrigatório")
        @Size(max = 15, message = "Telefone deve ter no máximo 15 caracteres")
        private String phoneNumber;

        @NotBlank(message = "Senha é obrigatória")
        @Size(min = 6, max = 100, message = "Senha deve ter entre 6 e 100 caracteres")
        private String password;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RestaurantData {
        @NotBlank(message = "Nome do restaurante é obrigatório")
        @Size(max = 100, message = "Nome deve ter no máximo 100 caracteres")
        private String name;

        @Size(max = 500, message = "Descrição deve ter no máximo 500 caracteres")
        private String description;

        @NotBlank(message = "Telefone do restaurante é obrigatório")
        @Size(max = 15, message = "Telefone deve ter no máximo 15 caracteres")
        private String phoneNumber;

        @NotBlank(message = "CNPJ é obrigatório")
        @Size(max = 18, message = "CNPJ deve ter no máximo 18 caracteres")
        private String cnpj;

        private String logoUrl;
        private String bannerUrl;

        @NotNull(message = "Taxa de entrega é obrigatória")
        @DecimalMin(value = "0.0", message = "Taxa de entrega não pode ser negativa")
        private BigDecimal deliveryFee;

        @NotNull(message = "Pedido mínimo é obrigatório")
        @DecimalMin(value = "0.0", message = "Pedido mínimo não pode ser negativo")
        private BigDecimal minimumOrder;

        @NotNull(message = "Tempo mínimo de entrega é obrigatório")
        @Min(value = 0, message = "Tempo mínimo de entrega não pode ser negativo")
        private Integer deliveryTimeMin;

        @NotNull(message = "Tempo máximo de entrega é obrigatório")
        @Min(value = 0, message = "Tempo máximo de entrega não pode ser negativo")
        private Integer deliveryTimeMax;
    }
}
