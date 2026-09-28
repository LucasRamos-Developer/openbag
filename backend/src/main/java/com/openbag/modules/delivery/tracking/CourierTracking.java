package com.openbag.modules.delivery.tracking;

import com.openbag.enums.OrderStatus;
import com.openbag.modules.order.entity.Order;

import java.util.Collection;
import java.util.Comparator;
import java.util.Optional;

/**
 * Quando o cliente pode ver o entregador no mapa. Só depois da retirada e só quando é a vez do pedido dele:
 * numa rota, o cliente do segundo pedido nunca vê o entregador indo para outra entrega.
 * A equipe própria da loja não usa o app, então nunca é rastreada.
 */
public final class CourierTracking {

    // Ordem das paradas: sequência da rota, depois retirada e id (pedidos solo não têm sequência)
    private static final Comparator<Order> STOP_ORDER = Comparator
            .comparing(Order::getRouteSequence, Comparator.nullsLast(Comparator.naturalOrder()))
            .thenComparing(Order::getPickedUpAt, Comparator.nullsLast(Comparator.naturalOrder()))
            .thenComparing(Order::getId, Comparator.nullsLast(Comparator.naturalOrder()));

    private CourierTracking() {
    }

    /**
     * Próxima entrega do entregador entre os pedidos que ele está levando
     */
    public static Optional<Order> currentStop(Collection<Order> courierOrders) {
        return courierOrders.stream()
                .filter(o -> o.getStatus() == OrderStatus.OUT_FOR_DELIVERY)
                .min(STOP_ORDER);
    }

    /**
     * O pedido está a caminho, com entregador do app, e é a próxima entrega dele
     *
     * @param courierOrders pedidos que o entregador do pedido está levando agora
     */
    public static boolean isTrackable(Order order, Collection<Order> courierOrders) {
        if (order.getStatus() != OrderStatus.OUT_FOR_DELIVERY || order.getDeliveryPerson() == null) {
            return false;
        }
        return currentStop(courierOrders).map(stop -> stop.getId().equals(order.getId())).orElse(false);
    }
}
