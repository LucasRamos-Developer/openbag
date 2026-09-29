package com.openbag.restaurant.cash.dto;

import com.openbag.modules.delivery.dispatch.ReassignPolicy.CourierKind;
import com.openbag.order.core.entity.Order;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Caixa da loja num período: vendas pelo OpenBag, formas de pagamento, acerto por entregador e acertos feitos.
 * Com pagamento na entrega, o dinheiro fica com o entregador; cartão e Pix caem na maquininha/Pix da loja.
 */
public record CashReportDTO(LocalDate from, LocalDate to, Summary summary, List<PaymentLine> payments,
                            List<CourierLine> couriers, List<SettlementDTO> settlements, Subsidy subsidy) {

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

    /**
     * Diferença que a loja assumiu nas entregas do período (taxa cobrada do cliente menor que a tabela da
     * associação). O entregador sempre recebe o valor cheio da tabela.
     */
    public record Subsidy(BigDecimal total, int orders, List<SubsidyByAssociation> byAssociation,
                          List<SubsidyLine> lines) {
    }

    public record SubsidyByAssociation(Long organizationId, String name, int orders, BigDecimal total) {
    }

    /**
     * @param customerFee taxa de entrega cobrada do cliente
     * @param courierFee  valor da tabela pago ao entregador
     */
    public record SubsidyLine(Long orderId, String displayCode, LocalDateTime deliveredAt, String courierName,
                              String organizationName, Double distanceKm, BigDecimal customerFee,
                              BigDecimal courierFee, BigDecimal subsidy) {
    }
}
