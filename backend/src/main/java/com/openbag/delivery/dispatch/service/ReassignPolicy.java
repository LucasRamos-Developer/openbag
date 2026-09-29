package com.openbag.delivery.dispatch.service;

import com.openbag.delivery.courier.entity.ShiftMode;
import com.openbag.delivery.courier.entity.CourierShift;
import com.openbag.delivery.courier.entity.DeliveryPerson;
import com.openbag.order.core.entity.Order;
import com.openbag.restaurant.store.entity.Restaurant;
import com.openbag.platform.geo.GeoUtils;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * Quando a loja pode trocar (ou tirar) o entregador de um pedido, sempre antes da retirada:
 * <ul>
 *   <li>fixo em check-in na loja ou equipe própria: a qualquer momento;</li>
 *   <li>entregador livre: só se ele não aparecer — passaram X minutos desde a atribuição e ele não está na loja.</li>
 * </ul>
 */
public final class ReassignPolicy {

    /** A partir desta distância da loja o entregador ainda não "chegou" */
    public static final double ARRIVAL_RADIUS_KM = 0.2;

    private static final DateTimeFormatter HH_MM = DateTimeFormatter.ofPattern("HH:mm");

    private ReassignPolicy() {
    }

    public enum CourierKind { FIXED, FREE, STAFF }

    /**
     * @param availableAt a partir de quando a troca é liberada (entregador livre); nulo nos outros casos
     */
    public record Decision(boolean allowed, String reason, LocalDateTime availableAt, boolean courierAtStore) {
    }

    /** Tipo de quem está com o pedido; nulo se ninguém */
    public static CourierKind kindOf(Order order) {
        if (order.getStaffCourier() != null) {
            return CourierKind.STAFF;
        }
        DeliveryPerson courier = order.getDeliveryPerson();
        if (courier == null) {
            return null;
        }
        return isFixedAt(courier, order.getRestaurant()) ? CourierKind.FIXED : CourierKind.FREE;
    }

    public static boolean isFixedAt(DeliveryPerson courier, Restaurant restaurant) {
        CourierShift shift = courier.getCurrentShift();
        return shift != null && shift.isOpen() && shift.getMode() == ShiftMode.FIXED && shift.getRestaurant() != null
                && shift.getRestaurant().getId().equals(restaurant.getId());
    }

    /** Última localização recente a menos de {@link #ARRIVAL_RADIUS_KM} da loja */
    public static boolean isAtStore(DeliveryPerson courier, Restaurant restaurant, LocalDateTime now, int staleSeconds) {
        if (courier.getLastLatitude() == null || courier.getLastLongitude() == null || courier.getLastSeenAt() == null
                || restaurant.getLatitude() == null || restaurant.getLongitude() == null
                || courier.getLastSeenAt().isBefore(now.minusSeconds(staleSeconds))) {
            return false;
        }
        return GeoUtils.haversineKm(courier.getLastLatitude(), courier.getLastLongitude(),
                restaurant.getLatitude().doubleValue(), restaurant.getLongitude().doubleValue()) <= ARRIVAL_RADIUS_KM;
    }

    /** Horário a partir do qual um entregador livre pode ser trocado; nulo para fixo, equipe ou sem entregador */
    public static LocalDateTime availableAt(Order order) {
        if (kindOf(order) != CourierKind.FREE || order.getAssignedAt() == null) {
            return null;
        }
        return order.getAssignedAt().plusMinutes(order.getRestaurant().getCourierNoShowMinutes());
    }

    public static Decision decide(Order order, LocalDateTime now, int staleSeconds) {
        CourierKind kind = kindOf(order);
        if (kind == null) {
            return new Decision(true, null, null, false);
        }
        if (order.getPickedUpAt() != null || !DispatchService.DISPATCHABLE.contains(order.getStatus())) {
            return new Decision(false, "O pedido já saiu para entrega", null, false);
        }
        if (kind != CourierKind.FREE) {
            return new Decision(true, null, null, false);
        }
        LocalDateTime availableAt = availableAt(order);
        boolean atStore = isAtStore(order.getDeliveryPerson(), order.getRestaurant(), now, staleSeconds);
        if (atStore) {
            return new Decision(false, "O entregador já está na loja", availableAt, true);
        }
        if (availableAt != null && now.isBefore(availableAt)) {
            return new Decision(false, "Entregador livre: a troca é liberada às " + availableAt.format(HH_MM)
                    + " se ele não chegar", availableAt, false);
        }
        return new Decision(true, null, availableAt, false);
    }
}
