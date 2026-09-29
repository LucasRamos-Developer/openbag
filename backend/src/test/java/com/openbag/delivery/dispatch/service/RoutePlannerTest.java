package com.openbag.delivery.dispatch.service;

import com.openbag.delivery.dispatch.service.RoutePlanner.Group;
import com.openbag.delivery.dispatch.service.RoutePlanner.Settings;
import com.openbag.delivery.dispatch.service.RoutePlanner.Stop;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class RoutePlannerTest {

    // Loja no centro de Blumenau; ~0,009° de latitude ≈ 1 km
    private static final double LAT = -26.9194;
    private static final double LNG = -49.0661;
    private static final LocalDateTime NOW = LocalDateTime.of(2026, 9, 27, 19, 0);
    private static final Settings SETTINGS = new Settings(3, 8, 10);

    private static Stop stop(long id, double northKm, double eastKm, String neighborhood, LocalDateTime readyAt,
                             LocalDateTime expected) {
        return new Stop(id, "#" + id, LAT + northKm * 0.009, LNG + eastKm * 0.01, neighborhood, readyAt, expected, false);
    }

    private static Stop ready(long id, double northKm, double eastKm, String neighborhood) {
        return stop(id, northKm, eastKm, neighborhood, NOW, NOW.minusMinutes(1));
    }

    private static List<Group> plan(Stop... stops) {
        return RoutePlanner.plan(LAT, LNG, List.of(stops), SETTINGS, NOW);
    }

    @Test
    void sameNeighborhoodGoesTogetherNearestFirst() {
        List<Group> groups = plan(ready(1, 2.0, 0.3, "Vila Nova"), ready(2, 1.0, 0.2, "vila  nová"));

        assertThat(groups).hasSize(1);
        assertThat(groups.get(0).orderIds()).containsExactly(2L, 1L);
        assertThat(groups.get(0).savedKm()).isPositive();
    }

    @Test
    void closeDestinationsInTheSameDirectionGoTogetherEvenInOtherNeighborhoods() {
        List<Group> groups = plan(ready(1, 2.0, 0.0, "Velha"), ready(2, 2.5, 0.4, "Garcia"));

        assertThat(groups).hasSize(1);
    }

    @Test
    void oppositeDirectionsGoSeparately() {
        List<Group> groups = plan(ready(1, 2.0, 0.0, "Norte"), ready(2, -2.0, 0.0, "Sul"));

        assertThat(groups).hasSize(2);
    }

    @Test
    void customerProtectionBlocksBigDetours() {
        // Mesmo "bairro" no cadastro, mas um de cada lado da loja
        List<Group> groups = plan(ready(1, 3.0, 0.0, "Centro"), ready(2, -3.0, 0.0, "Centro"));

        assertThat(groups).hasSize(2);
    }

    @Test
    void respectsTheMaximumOrdersPerRoute() {
        List<Group> groups = plan(ready(1, 1.0, 0.0, "Vila Nova"), ready(2, 1.2, 0.1, "Vila Nova"),
                ready(3, 1.4, 0.0, "Vila Nova"), ready(4, 1.6, 0.1, "Vila Nova"));

        assertThat(groups).extracting(g -> g.orderIds().size()).containsExactlyInAnyOrder(3, 1);
    }

    @Test
    void readyOrderWaitsForACompatibleOneThatIsAlmostReady() {
        Stop a = ready(1, 2.0, 0.0, "Velha");
        Stop b = stop(2, 2.3, 0.2, "Velha", null, NOW.plusMinutes(5));

        List<Group> groups = plan(a, b);

        assertThat(groups).hasSize(1);
        Group group = groups.get(0);
        assertThat(group.waitReason()).contains("#2").contains("~5 min");
        // O entregador é chamado já: chega quando o segundo estiver pronto
        assertThat(group.dueAt(NOW)).isTrue();
    }

    @Test
    void readyOrderDoesNotWaitLongerThanTheLimit() {
        Stop a = ready(1, 2.0, 0.0, "Velha");
        Stop b = stop(2, 2.3, 0.2, "Velha", null, NOW.plusMinutes(12));

        List<Group> groups = plan(a, b);

        assertThat(groups).hasSize(2);
        assertThat(groups.get(0).orderIds()).containsExactly(1L);
        assertThat(groups.get(0).dueAt(NOW)).isTrue();
        // O segundo só chama entregador 10 min antes de ficar pronto
        assertThat(groups.get(1).dueAt(NOW)).isFalse();
        assertThat(groups.get(1).dispatchAt()).isEqualTo(NOW.plusMinutes(2));
    }

    @Test
    void anOrderReadyLongAgoIsNotHeldEvenForAShortWait() {
        Stop a = stop(1, 2.0, 0.0, "Velha", NOW.minusMinutes(6), NOW.minusMinutes(8));
        Stop b = stop(2, 2.3, 0.2, "Velha", null, NOW.plusMinutes(5));

        assertThat(plan(a, b)).hasSize(2);
    }

    @Test
    void separatedOrdersNeverJoinARoute() {
        Stop solo = new Stop(2L, "#2", LAT + 0.02, LNG, "Velha", NOW, NOW, true);

        assertThat(plan(ready(1, 2.0, 0.0, "Velha"), solo)).hasSize(2);
    }

    @Test
    void ordersWithoutLocationGoAlone() {
        Stop unknown = new Stop(2L, "#2", null, null, "Velha", NOW, NOW, false);

        assertThat(plan(ready(1, 2.0, 0.0, "Velha"), unknown)).hasSize(2);
    }
}
