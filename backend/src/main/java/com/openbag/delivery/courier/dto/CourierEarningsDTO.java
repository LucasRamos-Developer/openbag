package com.openbag.delivery.courier.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Ganhos do entregador: resumo (hoje, semana, mês), série diária, entregas do período e, só para ele, km, tempo
 * e médias do período
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CourierEarningsDTO {

    private Total today;
    private Total week;
    private Total month;

    private LocalDate from;
    private LocalDate to;
    private Total period;
    private List<Day> daily;
    private List<Delivery> deliveries;
    private Stats stats;
    private CostEstimate cost;

    /** @param distanceKm km rodados: com o pedido e até a retirada */
    public record Total(BigDecimal amount, long deliveries, double distanceKm) {
    }

    /**
     * Km, tempo e médias do período. Os valores sem base para o cálculo (nenhuma entrega, nenhum km, nenhum turno)
     * vêm nulos, para a tela não mostrar um zero que não é real.
     *
     * @param deliveryKm        km com o pedido (da loja ao cliente)
     * @param pickupKm          km até a retirada (de onde a oferta foi aceita até a loja)
     * @param onlineMinutes     tempo em operação, pelos turnos
     * @param deliveringMinutes tempo com pedido, do aceite à entrega (numa rota, o mesmo minuto conta uma vez)
     * @param perDelivery       médias por entrega: valor, km com o pedido e minutos do aceite à entrega
     * @param perKm             R$ por km rodado
     * @param perHour           R$ por hora em operação
     */
    public record Stats(double deliveryKm, double pickupKm, double totalKm, long onlineMinutes, long deliveringMinutes,
                        Average perDelivery, BigDecimal perKm, BigDecimal perHour) {
    }

    public record Average(BigDecimal amount, Double distanceKm, Long minutes) {
    }

    /**
     * Resultado estimado do período: o que sobra do ganho depois do combustível, da manutenção e da depreciação.
     * É estimativa, não valor contábil. Vem nulo quando nenhum veículo usado tem custo informado (a tela convida a
     * preencher em vez de mostrar zero). Uma parte vem nula quando nenhum veículo a informou.
     *
     * @param complete todos os veículos com km no período têm todos os custos que se aplicam a eles
     * @param vehicles os veículos usados, com os km de cada um
     */
    public record CostEstimate(double distanceKm, BigDecimal revenue, BigDecimal fuel, BigDecimal maintenance,
                               BigDecimal depreciation, BigDecimal total, BigDecimal result, boolean complete,
                               List<VehicleCost> vehicles) {
    }

    public record VehicleCost(Long vehicleId, String name, double distanceKm, boolean complete) {
    }

    public record Day(LocalDate date, BigDecimal amount, long deliveries) {
    }

    public record Delivery(Long orderId, String displayCode, LocalDateTime deliveredAt, String restaurantName,
                           Double distanceKm, BigDecimal courierFee) {
    }
}
