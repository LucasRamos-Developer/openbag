package com.openbag.modules.delivery.dto;

import com.openbag.modules.delivery.dispatch.ReassignPolicy.CourierKind;
import com.openbag.modules.order.entity.Order;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Caixa da loja num período: vendas pelo OpenBag, formas de pagamento, acerto por entregador e acertos feitos.
 * Com pagamento na entrega, o dinheiro fica com o entregador; cartão e Pix caem na maquininha/Pix da loja.
 */
public record CashReportDTO(LocalDate from, LocalDate to, Summary summary, List<PaymentLine> payments,
                            List<CourierLine> couriers, List<SettlementDTO> settlements) {

    /**
     * @param storeBalance     recebido dos clientes − pago aos entregadores
     * @param withoutCourier   entregas marcadas pela loja sem entregador atribuído
     */
    public record Summary(int deliveredOrders, long cancelledOrders, BigDecimal productSales, BigDecimal deliveryFees,
                          BigDecimal totalReceived, BigDecimal paidToCouriers, BigDecimal restaurantSubsidy,
                          BigDecimal storeBalance, BigDecimal averageTicket, int withoutCourier) {
    }

    public record PaymentLine(Order.PaymentMethod method, int orders, BigDecimal amount) {
    }

    /**
     * Um entregador no período e o que falta acertar (de qualquer data).
     *
     * @param pendingBalance dinheiro recebido − ganhos ainda não acertados; positivo = ele devolve à loja
     */
    public record CourierLine(CourierKind kind, Long deliveryPersonId, Long staffCourierId, String name, String photoUrl,
                              int deliveries, BigDecimal earnings, BigDecimal cashCollected, BigDecimal otherCollected,
                              int pendingOrders, BigDecimal pendingCash, BigDecimal pendingEarnings,
                              BigDecimal pendingBalance) {
    }
}
