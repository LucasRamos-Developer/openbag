package com.openbag.modules.delivery.dispatch;

import com.openbag.platform.geo.GeoUtils;

import java.text.Normalizer;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.*;

/**
 * Agrupa entregas de uma loja em rotas (regras puras, sem banco).
 *
 * <ul>
 *   <li><b>Combinam</b>: mesmo bairro, ou destinos a até {@value #NEAR_KM} km um do outro e na mesma direção a partir
 *       da loja (diferença de rumo até {@value #MAX_BEARING_DIFF}°).</li>
 *   <li><b>Espera</b>: um grupo só junta pedidos que ficam prontos até {@code maxHoldMinutes} depois do primeiro —
 *       nenhum pedido pronto espera mais que isso por outro.</li>
 *   <li><b>Proteção do cliente</b>: o trecho até cada parada não passa de {@code direto × }{@value #MAX_DETOUR_FACTOR}
 *       {@code + }{@value #MAX_DETOUR_EXTRA_KM} km.</li>
 *   <li><b>Ordem</b>: a menor distância entre todas as ordens possíveis (poucos pedidos por rota).</li>
 *   <li><b>Quando chamar o entregador</b>: {@code leadMinutes} antes de o último pedido do grupo ficar pronto.</li>
 * </ul>
 * Distâncias: linha reta × {@value #ROAD_FACTOR} (fator de ruas, sem serviço de mapas).
 */
public final class RoutePlanner {

    public static final double ROAD_FACTOR = 1.3;
    public static final double NEAR_KM = 1.5;
    public static final double MAX_BEARING_DIFF = 35;
    public static final double MAX_DETOUR_FACTOR = 1.6;
    public static final double MAX_DETOUR_EXTRA_KM = 1.0;

    private RoutePlanner() {
    }

    /**
     * Pedido esperando entregador.
     *
     * @param readyAt         quando ficou pronto (nulo = ainda em preparo)
     * @param expectedReadyAt previsão de ficar pronto (aceite + tempo de preparo)
     * @param solo            a loja separou o pedido: nunca entra em grupo
     */
    public record Stop(Long orderId, String code, Double lat, Double lng, String neighborhood,
                       LocalDateTime readyAt, LocalDateTime expectedReadyAt, boolean solo) {

        LocalDateTime eta(LocalDateTime now) {
            if (readyAt != null) {
                return readyAt;
            }
            return expectedReadyAt != null && expectedReadyAt.isAfter(now) ? expectedReadyAt : now;
        }

        boolean hasLocation() {
            return lat != null && lng != null;
        }

        boolean ready() {
            return readyAt != null;
        }
    }

    public record Settings(int maxOrders, int maxHoldMinutes, int leadMinutes) {
    }

    /**
     * Um grupo (1 pedido = sai sozinho) na ordem de entrega.
     *
     * @param dispatchAt quando chamar o entregador (antes de agora = já)
     * @param waitReason com pedidos prontos esperando outro do grupo: o aviso para a loja
     */
    public record Group(List<Long> orderIds, double totalKm, double savedKm, LocalDateTime dispatchAt,
                        String waitReason) {

        public boolean dueAt(LocalDateTime now) {
            return !dispatchAt.isAfter(now);
        }
    }

    public static List<Group> plan(double storeLat, double storeLng, List<Stop> stops, Settings settings, LocalDateTime now) {
        List<Stop> remaining = new ArrayList<>(stops);
        remaining.sort(Comparator.comparing((Stop s) -> s.eta(now)).thenComparing(Stop::orderId));
        List<Group> groups = new ArrayList<>();

        while (!remaining.isEmpty()) {
            Stop seed = remaining.remove(0);
            List<Stop> group = new ArrayList<>(List.of(seed));
            if (!seed.solo() && seed.hasLocation()) {
                grow(storeLat, storeLng, seed, group, remaining, settings, now);
            }
            groups.add(toGroup(storeLat, storeLng, group, settings, now));
        }
        return groups;
    }

    /** Adiciona ao grupo, um de cada vez, o pedido compatível que mais economiza */
    private static void grow(double storeLat, double storeLng, Stop seed, List<Stop> group, List<Stop> remaining,
                             Settings settings, LocalDateTime now) {
        LocalDateTime holdLimit = seed.eta(now).plusMinutes(settings.maxHoldMinutes());
        while (group.size() < settings.maxOrders()) {
            Stop best = null;
            double bestSaving = 0;
            for (Stop candidate : remaining) {
                if (candidate.solo() || !candidate.hasLocation() || candidate.eta(now).isAfter(holdLimit)
                        || !compatible(storeLat, storeLng, seed, candidate)) {
                    continue;
                }
                List<Stop> trial = new ArrayList<>(group);
                trial.add(candidate);
                List<Stop> sequence = bestSequence(storeLat, storeLng, trial);
                if (sequence == null) {
                    continue;
                }
                double saving = separateKm(storeLat, storeLng, trial) - routeKm(storeLat, storeLng, sequence, true);
                if (saving > bestSaving) {
                    bestSaving = saving;
                    best = candidate;
                }
            }
            if (best == null) {
                return;
            }
            group.add(best);
            remaining.remove(best);
        }
    }

    private static Group toGroup(double storeLat, double storeLng, List<Stop> group, Settings settings, LocalDateTime now) {
        List<Stop> sequence = group.size() > 1 ? bestSequence(storeLat, storeLng, group) : group;
        LocalDateTime lastEta = group.stream().map(s -> s.eta(now)).max(Comparator.naturalOrder()).orElse(now);
        LocalDateTime dispatchAt = lastEta.minusMinutes(settings.leadMinutes());

        double total = 0;
        double saved = 0;
        String waitReason = null;
        if (group.size() > 1 && group.stream().allMatch(Stop::hasLocation)) {
            total = routeKm(storeLat, storeLng, sequence, false);
            saved = Math.max(0, separateKm(storeLat, storeLng, group) - routeKm(storeLat, storeLng, sequence, true));
            List<Stop> late = group.stream().filter(s -> !s.ready()).toList();
            if (group.stream().anyMatch(Stop::ready) && !late.isEmpty()) {
                Stop last = late.stream().max(Comparator.comparing(s -> s.eta(now))).orElseThrow();
                long minutes = Math.max(1, Duration.between(now, last.eta(now)).toMinutes());
                waitReason = String.format(Locale.ROOT, "Aguardando %s ficar pronto (~%d min) para sair junto: economiza %s km",
                        last.code(), minutes, km(saved));
            }
        }
        return new Group(sequence.stream().map(Stop::orderId).toList(), round(total), round(saved), dispatchAt, waitReason);
    }

    /**
     * Ordem de entrega de uma rota montada pela loja: a melhor que protege o cliente ou, se nenhuma protege
     * (a loja decidiu juntar assim), a de menor distância
     */
    public static List<Long> manualSequence(double storeLat, double storeLng, List<Stop> stops) {
        List<Stop> located = stops.stream().filter(Stop::hasLocation).toList();
        List<Stop> sequence = located.size() > 1 ? bestSequence(storeLat, storeLng, located) : located;
        if (sequence == null) {
            sequence = permutations(located).stream()
                    .min(Comparator.comparingDouble(p -> routeKm(storeLat, storeLng, p, false)))
                    .orElse(located);
        }
        List<Long> ids = new ArrayList<>(sequence.stream().map(Stop::orderId).toList());
        stops.stream().filter(s -> !s.hasLocation()).forEach(s -> ids.add(s.orderId()));
        return ids;
    }

    /** Distância total da rota nesta ordem (sem a volta) e economia em relação a uma viagem por pedido */
    public static double[] distances(double storeLat, double storeLng, List<Stop> sequence) {
        List<Stop> located = sequence.stream().filter(Stop::hasLocation).toList();
        if (located.size() < 2) {
            return new double[]{0, 0};
        }
        double total = routeKm(storeLat, storeLng, located, false);
        double saved = Math.max(0, separateKm(storeLat, storeLng, located) - routeKm(storeLat, storeLng, located, true));
        return new double[]{round(total), round(saved)};
    }

    // ============= Regras =============

    /** Mesmo bairro, ou perto e na mesma direção a partir da loja */
    static boolean compatible(double storeLat, double storeLng, Stop a, Stop b) {
        if (a.neighborhood() != null && b.neighborhood() != null
                && normalize(a.neighborhood()).equals(normalize(b.neighborhood()))) {
            return true;
        }
        double apart = GeoUtils.haversineKm(a.lat(), a.lng(), b.lat(), b.lng());
        double bearingDiff = angleDiff(bearing(storeLat, storeLng, a.lat(), a.lng()), bearing(storeLat, storeLng, b.lat(), b.lng()));
        return apart <= NEAR_KM && bearingDiff <= MAX_BEARING_DIFF;
    }

    /**
     * Ordem de menor distância que respeita a proteção do cliente em todas as paradas; nulo se nenhuma respeita
     */
    static List<Stop> bestSequence(double storeLat, double storeLng, List<Stop> stops) {
        List<Stop> best = null;
        double bestKm = Double.MAX_VALUE;
        for (List<Stop> order : permutations(stops)) {
            if (!withinDetour(storeLat, storeLng, order)) {
                continue;
            }
            double km = routeKm(storeLat, storeLng, order, false);
            if (km < bestKm) {
                bestKm = km;
                best = order;
            }
        }
        return best;
    }

    static boolean withinDetour(double storeLat, double storeLng, List<Stop> sequence) {
        double travelled = 0;
        double lat = storeLat;
        double lng = storeLng;
        for (Stop stop : sequence) {
            travelled += road(lat, lng, stop.lat(), stop.lng());
            double direct = road(storeLat, storeLng, stop.lat(), stop.lng());
            if (travelled > direct * MAX_DETOUR_FACTOR + MAX_DETOUR_EXTRA_KM) {
                return false;
            }
            lat = stop.lat();
            lng = stop.lng();
        }
        return true;
    }

    /** Distância da rota saindo da loja; com {@code backToStore}, conta a volta à loja depois da última parada */
    static double routeKm(double storeLat, double storeLng, List<Stop> sequence, boolean backToStore) {
        double total = 0;
        double lat = storeLat;
        double lng = storeLng;
        for (Stop stop : sequence) {
            total += road(lat, lng, stop.lat(), stop.lng());
            lat = stop.lat();
            lng = stop.lng();
        }
        return backToStore ? total + road(lat, lng, storeLat, storeLng) : total;
    }

    /** Cada pedido numa viagem própria, com a volta à loja */
    static double separateKm(double storeLat, double storeLng, List<Stop> stops) {
        return stops.stream().mapToDouble(s -> 2 * road(storeLat, storeLng, s.lat(), s.lng())).sum();
    }

    static double road(double lat1, double lng1, double lat2, double lng2) {
        return GeoUtils.haversineKm(lat1, lng1, lat2, lng2) * ROAD_FACTOR;
    }

    static String normalize(String text) {
        return Normalizer.normalize(text, Normalizer.Form.NFD).replaceAll("\\p{M}", "")
                .toLowerCase(Locale.ROOT).trim().replaceAll("\\s+", " ");
    }

    private static double bearing(double lat1, double lng1, double lat2, double lng2) {
        double phi1 = Math.toRadians(lat1);
        double phi2 = Math.toRadians(lat2);
        double dLng = Math.toRadians(lng2 - lng1);
        double y = Math.sin(dLng) * Math.cos(phi2);
        double x = Math.cos(phi1) * Math.sin(phi2) - Math.sin(phi1) * Math.cos(phi2) * Math.cos(dLng);
        return (Math.toDegrees(Math.atan2(y, x)) + 360) % 360;
    }

    private static double angleDiff(double a, double b) {
        double diff = Math.abs(a - b) % 360;
        return diff > 180 ? 360 - diff : diff;
    }

    private static List<List<Stop>> permutations(List<Stop> stops) {
        if (stops.size() <= 1) {
            return List.of(new ArrayList<>(stops));
        }
        List<List<Stop>> result = new ArrayList<>();
        for (int i = 0; i < stops.size(); i++) {
            List<Stop> rest = new ArrayList<>(stops);
            Stop first = rest.remove(i);
            for (List<Stop> tail : permutations(rest)) {
                List<Stop> perm = new ArrayList<>();
                perm.add(first);
                perm.addAll(tail);
                result.add(perm);
            }
        }
        return result;
    }

    private static double round(double km) {
        return Math.round(km * 10) / 10.0;
    }

    private static String km(double value) {
        return String.format(Locale.ROOT, "%.1f", value).replace('.', ',');
    }
}
