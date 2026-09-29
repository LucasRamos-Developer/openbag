package com.openbag.order.core.dto;

import com.openbag.order.core.entity.FulfillmentType;
import com.openbag.order.core.entity.OrderChannel;
import com.openbag.order.core.entity.Order;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

/**
 * Pedido registrado pela loja (balcão, telefone ou WhatsApp) para um cliente sem conta.
 * Como no app, os preços são recalculados no servidor a partir do cardápio.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateStoreOrderRequest {

    @NotNull(message = "Informe por onde o pedido chegou")
    private OrderChannel channel;

    @NotNull(message = "Escolha entrega ou retirada")
    private FulfillmentType fulfillment;

    @NotBlank(message = "Informe o nome do cliente")
    @Size(max = 100, message = "Nome deve ter no máximo 100 caracteres")
    private String customerName;

    @Size(max = 20, message = "Telefone deve ter no máximo 20 caracteres")
    private String customerPhone;

    @Valid
    @NotEmpty(message = "Adicione pelo menos um item")
    @Size(max = 50, message = "Máximo de 50 itens por pedido")
    private List<CreateOrderRequest.ItemRequest> items;

    // Obrigatório na entrega
    @Valid
    private CreateOrderRequest.AddressRequest address;

    @NotNull(message = "Forma de pagamento é obrigatória")
    private Order.PaymentMethod paymentMethod;

    // Pagamento em dinheiro: valor que o cliente vai entregar (para o troco)
    @DecimalMin(value = "0.00", message = "Valor para troco inválido")
    private BigDecimal changeFor;

    @Size(max = 300, message = "Observação deve ter no máximo 300 caracteres")
    private String notes;
}
