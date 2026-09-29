package com.openbag.modules.order.dto;

import com.openbag.platform.geo.GeocodingService;
import com.openbag.modules.order.entity.Order;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

/**
 * Pedido do cliente. Os preços não vêm do cliente: o servidor recalcula tudo a partir do cardápio.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateOrderRequest {

    @NotNull(message = "Restaurante é obrigatório")
    private Long restaurantId;

    @Valid
    @NotEmpty(message = "O carrinho está vazio")
    @Size(max = 50, message = "Máximo de 50 itens por pedido")
    private List<ItemRequest> items;

    @Valid
    @NotNull(message = "Endereço de entrega é obrigatório")
    private AddressRequest address;

    @NotNull(message = "Forma de pagamento é obrigatória")
    private Order.PaymentMethod paymentMethod;

    // Pagamento em dinheiro: valor que o cliente vai entregar (para o troco)
    @DecimalMin(value = "0.00", message = "Valor para troco inválido")
    private BigDecimal changeFor;

    @Size(max = 300, message = "Observação deve ter no máximo 300 caracteres")
    private String notes;

    // Telefone para contato na entrega (padrão: o da conta)
    @Size(max = 20, message = "Telefone deve ter no máximo 20 caracteres")
    private String customerPhone;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ItemRequest {

        // Informe productId (item avulso) ou comboId
        private Long productId;

        private Long comboId;

        @NotNull(message = "Quantidade é obrigatória")
        @Min(value = 1, message = "Quantidade mínima é 1")
        @Max(value = 50, message = "Quantidade máxima é 50")
        private Integer quantity;

        @Size(max = 200, message = "Observação do item deve ter no máximo 200 caracteres")
        private String notes;

        // Opções de complemento escolhidas
        private List<Long> optionIds;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AddressRequest {

        @NotBlank(message = "Rua é obrigatória")
        @Size(max = 200)
        private String street;

        @NotBlank(message = "Número é obrigatório")
        @Size(max = 10)
        private String number;

        @Size(max = 100)
        private String complement;

        @NotBlank(message = "Bairro é obrigatório")
        @Size(max = 100)
        private String neighborhood;

        @NotBlank(message = "Cidade é obrigatória")
        @Size(max = 100)
        private String city;

        @NotBlank(message = "Estado é obrigatório")
        @Size(max = 50)
        private String state;

        @Size(max = 10)
        private String zipCode;

        // Ponto de referência (ex: "portão azul")
        @Size(max = 150)
        private String reference;

        private Double latitude;
        private Double longitude;

        public GeocodingService.AddressQuery toQuery() {
            return new GeocodingService.AddressQuery(street, number, neighborhood, city, state, zipCode);
        }

        public String format() {
            StringBuilder text = new StringBuilder(street.trim()).append(", ").append(number.trim());
            if (complement != null && !complement.isBlank()) text.append(" - ").append(complement.trim());
            text.append(" - ").append(neighborhood.trim()).append(", ").append(city.trim()).append("/").append(state.trim());
            if (zipCode != null && !zipCode.isBlank()) text.append(" - CEP ").append(zipCode.trim());
            if (reference != null && !reference.isBlank()) text.append(" (Ref.: ").append(reference.trim()).append(")");
            return text.toString();
        }
    }
}
