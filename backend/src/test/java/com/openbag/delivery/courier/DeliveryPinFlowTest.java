package com.openbag.delivery.courier;

import com.openbag.account.entity.User;
import com.openbag.account.repository.UserRepository;
import com.openbag.delivery.courier.dto.DeliverRequest;
import com.openbag.delivery.courier.repository.DeliveryPersonRepository;
import com.openbag.delivery.courier.service.CourierWorkService;
import com.openbag.order.core.dto.CreateOrderRequest;
import com.openbag.order.core.dto.CreateStoreOrderRequest;
import com.openbag.order.core.entity.FulfillmentType;
import com.openbag.order.core.entity.Order;
import com.openbag.order.core.entity.OrderChannel;
import com.openbag.order.core.repository.OrderRepository;
import com.openbag.order.core.service.CustomerOrderMapper;
import com.openbag.order.core.service.OrderService;
import com.openbag.platform.seed.DemoDataInitializer;
import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.platform.web.exception.WrongDeliveryPinException;
import com.openbag.support.IntegrationTest;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.support.TransactionTemplate;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Critério de pronto do item 5 da 0.5.0: com o PIN ligado, a entrega só é concluída com o código certo.
 * O pedido é do app (tem PIN) e está a caminho do cliente com o entregador demo.
 */
class DeliveryPinFlowTest extends IntegrationTest {

    @Autowired private CourierWorkService courierWorkService;
    @Autowired private OrderService orderService;
    @Autowired private OrderRepository orderRepository;
    @Autowired private CustomerOrderMapper customerOrderMapper;
    @Autowired private DeliveryPersonRepository deliveryPersonRepository;
    @Autowired private UserRepository userRepository;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private TransactionTemplate transaction;

    private User demo;
    private Long restaurantId;
    private Long orderId;

    @BeforeEach
    void appOrderOnTheWay() {
        demo = userRepository.findByEmail(DemoDataInitializer.DEMO_EMAIL).orElseThrow();
        restaurantId = jdbc.queryForObject("SELECT id FROM restaurants WHERE slug = 'cantina-demo'", Long.class);
        Long courierId = deliveryPersonRepository.findByUserId(demo.getId()).orElseThrow().getId();
        jdbc.update("UPDATE delivery_offers SET status = 'CANCELLED' WHERE status = 'PENDING'");
        jdbc.update("UPDATE orders SET status = 'DELIVERED', courier_settled_at = now() "
                + "WHERE status NOT IN ('DELIVERED', 'CANCELLED')");
        jdbc.update("UPDATE restaurants SET require_delivery_pin = true WHERE id = ?", restaurantId);

        orderId = newOrder();
        // Como um pedido do app: cliente com conta, PIN e a caminho com o entregador demo
        jdbc.update("UPDATE orders SET channel = 'APP', user_id = ?, delivery_pin = '4821', status = 'OUT_FOR_DELIVERY', "
                + "delivery_person_id = ?, assigned_at = now(), picked_up_at = now() WHERE id = ?",
                demo.getId(), courierId, orderId);
    }

    @AfterEach
    void pinOff() {
        jdbc.update("UPDATE restaurants SET require_delivery_pin = NULL WHERE id = ?", restaurantId);
    }

    @Test
    void onlyTheRightPinFinishesTheDeliveryAndRecordsWhereItHappened() {
        assertThatThrownBy(() -> courierWorkService.deliver(demo, orderId, null))
                .isInstanceOf(BadRequestException.class).hasMessageContaining("código de 4 dígitos");

        assertThatThrownBy(() -> courierWorkService.deliver(demo, orderId, new DeliverRequest("1111", null, null)))
                .isInstanceOf(WrongDeliveryPinException.class).hasMessageContaining("Restam 4");
        assertThat(attempts()).as("o erro fica gravado mesmo com a exceção").isEqualTo(1);
        assertThat(status()).isEqualTo("OUT_FOR_DELIVERY");

        courierWorkService.deliver(demo, orderId, new DeliverRequest(" 4821 ", -26.9195, -49.0662));

        assertThat(status()).isEqualTo("DELIVERED");
        assertThat(jdbc.queryForObject("SELECT delivered_latitude FROM orders WHERE id = ?", Double.class, orderId))
                .isEqualTo(-26.9195);
    }

    @Test
    void afterFiveWrongPinsOnlyTheStoreConfirms() {
        for (int i = 0; i < 5; i++) {
            assertThatThrownBy(() -> courierWorkService.deliver(demo, orderId, new DeliverRequest("0000", null, null)))
                    .isInstanceOf(WrongDeliveryPinException.class);
        }

        assertThatThrownBy(() -> courierWorkService.deliver(demo, orderId, new DeliverRequest("4821", null, null)))
                .isInstanceOf(BadRequestException.class).hasMessageContaining("loja confirmar");
        assertThat(status()).isEqualTo("OUT_FOR_DELIVERY");
    }

    @Test
    void withThePinOffTheSimpleConfirmationStillWorks() {
        jdbc.update("UPDATE restaurants SET require_delivery_pin = false WHERE id = ?", restaurantId);

        courierWorkService.deliver(demo, orderId, null);

        assertThat(status()).isEqualTo("DELIVERED");
    }

    @Test
    void theCustomerSeesThePinOnlyWhileTheStoreRequiresIt() {
        String pin = transaction.execute(tx -> customerOrderMapper.toDto(orderRepository.findById(orderId).orElseThrow())
                .getDeliveryPin());
        assertThat(pin).isEqualTo("4821");

        jdbc.update("UPDATE restaurants SET require_delivery_pin = false WHERE id = ?", restaurantId);
        String hidden = transaction.execute(tx -> customerOrderMapper.toDto(orderRepository.findById(orderId).orElseThrow())
                .getDeliveryPin());
        assertThat(hidden).isNull();
    }

    private int attempts() {
        return jdbc.queryForObject("SELECT delivery_pin_attempts FROM orders WHERE id = ?", Integer.class, orderId);
    }

    private String status() {
        return jdbc.queryForObject("SELECT status FROM orders WHERE id = ?", String.class, orderId);
    }

    private Long newOrder() {
        CreateOrderRequest.ItemRequest item = new CreateOrderRequest.ItemRequest();
        item.setProductId(jdbc.queryForObject("SELECT id FROM products WHERE restaurant_id = ? AND deleted_at IS NULL "
                + "ORDER BY id LIMIT 1", Long.class, restaurantId));
        item.setQuantity(1);
        CreateOrderRequest.AddressRequest address = new CreateOrderRequest.AddressRequest();
        address.setStreet("Rua XV de Novembro");
        address.setNumber("100");
        address.setNeighborhood("Centro");
        address.setCity("Blumenau");
        address.setState("SC");
        address.setZipCode("89010000");
        address.setLatitude(-26.9200);
        address.setLongitude(-49.0700);
        CreateStoreOrderRequest request = new CreateStoreOrderRequest();
        request.setChannel(OrderChannel.PHONE);
        request.setFulfillment(FulfillmentType.DELIVERY);
        request.setCustomerName("Cliente do PIN");
        request.setItems(List.of(item));
        request.setAddress(address);
        request.setPaymentMethod(Order.PaymentMethod.CASH);
        return orderService.createStoreOrder(restaurantId, request).getId();
    }
}
