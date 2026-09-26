package com.openbag.modules.delivery.dispatch;

import com.openbag.modules.delivery.entity.DeliveryPerson;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

/**
 * Escolha do entregador que recebe a oferta (regras puras, sem banco).
 *
 * <ul>
 *   <li>Fixos em check-in: rodízio — menos entregas no turno, depois quem está parado há mais tempo.</li>
 *   <li>Modo livre: menor pontuação {@code wDist × distância/raio + wFair × ganhoHoje/maiorGanhoHoje},
 *       ou seja, perto do restaurante e, entre os próximos, quem ganhou menos no dia.</li>
 * </ul>
 */
public final class CourierSelector {

    private CourierSelector() {
    }

    /**
     * Entregador apto a receber o pedido, com o valor que ele receberia
     */
    public record Candidate(DeliveryPerson courier, Double pickupDistanceKm, BigDecimal courierFee,
                            BigDecimal earnedToday, int shiftDeliveries, LocalDateTime lastDeliveryAt,
                            LocalDateTime shiftStartedAt) {
    }

    public record Choice(Candidate candidate, double score) {
    }

    /**
     * Regra da taxa: o valor do entregador cabe na taxa cobrada do cliente, ou o restaurante assume a diferença
     */
    public static boolean feeAllowed(BigDecimal courierFee, BigDecimal customerFee, boolean restaurantCoversDifference) {
        if (restaurantCoversDifference) {
            return true;
        }
        BigDecimal charged = customerFee != null ? customerFee : BigDecimal.ZERO;
        return courierFee.compareTo(charged) <= 0;
    }

    public static Optional<Choice> pickFixed(List<Candidate> candidates) {
        return candidates.stream()
                .min(Comparator.comparingInt(Candidate::shiftDeliveries)
                        .thenComparing(Candidate::lastDeliveryAt, Comparator.nullsFirst(Comparator.naturalOrder()))
                        .thenComparing(Candidate::shiftStartedAt, Comparator.nullsLast(Comparator.naturalOrder())))
                .map(c -> new Choice(c, c.shiftDeliveries()));
    }

    public static Optional<Choice> pickFree(List<Candidate> candidates, double radiusKm,
                                            double weightDistance, double weightFairness) {
        if (candidates.isEmpty()) {
            return Optional.empty();
        }
        double maxEarned = candidates.stream()
                .mapToDouble(c -> earned(c).doubleValue())
                .max()
                .orElse(0);

        return candidates.stream()
                .map(c -> new Choice(c, score(c, radiusKm, maxEarned, weightDistance, weightFairness)))
                .min(Comparator.comparingDouble(Choice::score)
                        .thenComparing(choice -> choice.candidate().courier().getId()));
    }

    static double score(Candidate c, double radiusKm, double maxEarned, double weightDistance, double weightFairness) {
        // Sem distância conhecida (restaurante sem coordenadas) conta como meio raio
        double distance = c.pickupDistanceKm() != null ? c.pickupDistanceKm() : radiusKm / 2;
        double distancePart = radiusKm > 0 ? Math.min(distance / radiusKm, 1.0) : 0;
        double fairnessPart = maxEarned > 0 ? earned(c).doubleValue() / maxEarned : 0;
        return weightDistance * distancePart + weightFairness * fairnessPart;
    }

    private static BigDecimal earned(Candidate c) {
        return c.earnedToday() != null ? c.earnedToday() : BigDecimal.ZERO;
    }
}
