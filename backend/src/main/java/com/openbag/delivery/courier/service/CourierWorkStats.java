package com.openbag.delivery.courier.service;

import com.openbag.delivery.courier.dto.CourierEarningsDTO;
import com.openbag.order.core.entity.Order;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/**
 * Km, tempo e médias do entregador num período. Só contas: quem chama busca as entregas, o km até cada retirada e
 * os turnos.
 */
final class CourierWorkStats {

    /** Intervalo de tempo; {@code end} nulo é um turno ainda aberto */
    record Interval(LocalDateTime start, LocalDateTime end) {
    }

    private CourierWorkStats() {
    }

    /**
     * @param delivered entregas concluídas no período
     * @param pickupKm  km até a retirada, por pedido (só os pedidos que vieram de uma oferta aceita)
     * @param shifts    turnos que tocam o período
     * @param start     início do período
     * @param end       fim do período (exclusivo)
     * @param now       agora: um turno aberto conta até aqui
     */
    static CourierEarningsDTO.Stats of(List<Order> delivered, Map<Long, Double> pickupKm, List<Interval> shifts,
                                       LocalDateTime start, LocalDateTime end, LocalDateTime now) {
        double deliveryKm = round(deliveryKm(delivered));
        double pickup = round(delivered.stream().map(o -> pickupKm.get(o.getId())).filter(Objects::nonNull)
                .mapToDouble(Double::doubleValue).sum());
        double totalKm = round(deliveryKm + pickup);
        BigDecimal amount = amount(delivered);

        LocalDateTime until = now.isBefore(end) ? now : end;
        long online = minutes(merge(shifts.stream()
                .map(s -> clip(s.start(), s.end() != null ? s.end() : now, start, until))
                .filter(Objects::nonNull)
                .toList()));
        List<Interval> deliveries = delivered.stream()
                .filter(o -> o.getAssignedAt() != null && o.getDeliveredAt() != null
                        && o.getDeliveredAt().isAfter(o.getAssignedAt()))
                .map(o -> new Interval(o.getAssignedAt(), o.getDeliveredAt()))
                .toList();
        long delivering = minutes(merge(deliveries));

        int count = delivered.size();
        long withDistance = delivered.stream().filter(o -> o.getDeliveryDistanceKm() != null).count();
        CourierEarningsDTO.Average perDelivery = count == 0 ? null : new CourierEarningsDTO.Average(
                amount.divide(BigDecimal.valueOf(count), 2, RoundingMode.HALF_UP),
                withDistance == 0 ? null : round(deliveryKm / withDistance),
                deliveries.isEmpty() ? null : minutes(deliveries) / deliveries.size());

        return new CourierEarningsDTO.Stats(deliveryKm, pickup, totalKm, online, delivering, perDelivery,
                totalKm > 0 ? amount.divide(BigDecimal.valueOf(totalKm), 2, RoundingMode.HALF_UP) : null,
                online > 0 ? amount.multiply(BigDecimal.valueOf(60)).divide(BigDecimal.valueOf(online), 2,
                        RoundingMode.HALF_UP) : null);
    }

    /** Km rodados com o pedido e até a retirada, para os quadros de hoje, semana e mês */
    static double totalKm(List<Order> delivered, Map<Long, Double> pickupKm) {
        double pickup = delivered.stream().map(o -> pickupKm.get(o.getId())).filter(Objects::nonNull)
                .mapToDouble(Double::doubleValue).sum();
        return round(deliveryKm(delivered) + pickup);
    }

    private static double deliveryKm(List<Order> orders) {
        return orders.stream().map(Order::getDeliveryDistanceKm).filter(Objects::nonNull)
                .mapToDouble(Double::doubleValue).sum();
    }

    private static BigDecimal amount(List<Order> orders) {
        return orders.stream().map(Order::getCourierFee).filter(Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    /** O pedaço do intervalo dentro de [from, to), ou nulo se ficar de fora */
    private static Interval clip(LocalDateTime start, LocalDateTime end, LocalDateTime from, LocalDateTime to) {
        LocalDateTime s = start.isBefore(from) ? from : start;
        LocalDateTime e = end.isAfter(to) ? to : end;
        return e.isAfter(s) ? new Interval(s, e) : null;
    }

    /** Junta os intervalos que se sobrepõem, para o mesmo minuto não contar duas vezes */
    static List<Interval> merge(List<Interval> intervals) {
        List<Interval> sorted = new ArrayList<>(intervals);
        sorted.sort(Comparator.comparing(Interval::start));
        List<Interval> merged = new ArrayList<>();
        for (Interval next : sorted) {
            Interval last = merged.isEmpty() ? null : merged.get(merged.size() - 1);
            if (last != null && !next.start().isAfter(last.end())) {
                merged.set(merged.size() - 1, new Interval(last.start(),
                        next.end().isAfter(last.end()) ? next.end() : last.end()));
            } else {
                merged.add(next);
            }
        }
        return merged;
    }

    private static long minutes(List<Interval> intervals) {
        return intervals.stream().mapToLong(i -> Duration.between(i.start(), i.end()).toMinutes()).sum();
    }

    private static double round(double km) {
        return Math.round(km * 10) / 10.0;
    }
}
