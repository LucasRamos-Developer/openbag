package com.openbag.order.incident;

import com.openbag.account.entity.User;
import com.openbag.account.repository.UserRepository;
import com.openbag.association.partnership.dto.AssociationReportDTO;
import com.openbag.association.partnership.service.AssociationReportService;
import com.openbag.delivery.courier.dto.CourierWorkStateDTO;
import com.openbag.delivery.courier.repository.DeliveryPersonRepository;
import com.openbag.delivery.courier.service.CourierWorkService;
import com.openbag.delivery.dispatch.dto.CourierOrderDTO;
import com.openbag.order.core.dto.CreateOrderRequest;
import com.openbag.order.core.dto.CreateStoreOrderRequest;
import com.openbag.order.core.dto.OrderDTO;
import com.openbag.order.core.entity.FulfillmentType;
import com.openbag.order.core.entity.Order;
import com.openbag.order.core.entity.OrderChannel;
import com.openbag.order.core.repository.OrderRepository;
import com.openbag.order.core.service.CustomerOrderMapper;
import com.openbag.order.core.service.OrderService;
import com.openbag.order.incident.entity.IncidentType;
import com.openbag.platform.seed.DemoDataInitializer;
import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.support.IntegrationTest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.support.TransactionTemplate;

import java.time.LocalDate;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Critério de pronto do item 1 da 0.5.0: o entregador relata "cliente não localizado", a loja vê no pedido,
 * o cliente não, e a ocorrência entra no relatório da cooperativa.
 */
class OrderIncidentFlowTest extends IntegrationTest {

    @Autowired private CourierWorkService courierWorkService;
    @Autowired private OrderService orderService;
    @Autowired private OrderRepository orderRepository;
    @Autowired private CustomerOrderMapper customerOrderMapper;
    @Autowired private AssociationReportService reportService;
    @Autowired private DeliveryPersonRepository deliveryPersonRepository;
    @Autowired private UserRepository userRepository;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private TransactionTemplate transaction;

    private User demo;
    private Long restaurantId;
    private Long courierId;
    private Long organizationId;
    private Long orderId;

    @BeforeEach
    void deliveryInProgress() {
        demo = userRepository.findByEmail(DemoDataInitializer.DEMO_EMAIL).orElseThrow();
        restaurantId = jdbc.queryForObject("SELECT id FROM restaurants WHERE slug = 'cantina-demo'", Long.class);
        courierId = deliveryPersonRepository.findByUserId(demo.getId()).orElseThrow().getId();
        organizationId = jdbc.queryForObject("SELECT organization_id FROM delivery_persons WHERE id = ?", Long.class,
                courierId);
        jdbc.update("UPDATE delivery_offers SET status = 'CANCELLED' WHERE status = 'PENDING'");
        jdbc.update("UPDATE orders SET status = 'DELIVERED', courier_settled_at = now() "
                + "WHERE status NOT IN ('DELIVERED', 'CANCELLED')");

        orderId = newStoreOrder();
        // Pronto e com o entregador demo a caminho do cliente
        jdbc.update("UPDATE orders SET status = 'OUT_FOR_DELIVERY', delivery_person_id = ?, assigned_at = now(), "
                + "picked_up_at = now() WHERE id = ?", courierId, orderId);
    }

    @Test
    void theStoreSeesTheIncidentAndTheCooperativeCountsItButNotTheCustomer() {
        long before = incidentsInTheReport(IncidentType.CUSTOMER_NOT_FOUND);

        CourierWorkStateDTO state = courierWorkService.reportIncident(demo, orderId, IncidentType.CUSTOMER_NOT_FOUND,
                null);

        assertThat(state.getActiveOrders()).filteredOn(o -> o.getOrderId().equals(orderId))
                .singleElement()
                .extracting(CourierOrderDTO::getReportedIncidents)
                .isEqualTo(List.of(IncidentType.CUSTOMER_NOT_FOUND));

        OrderDTO forStore = transaction.execute(tx -> OrderDTO.from(orderRepository.findById(orderId).orElseThrow()));
        assertThat(forStore.getIncidents()).singleElement().satisfies(incident -> {
            assertThat(incident.getType()).isEqualTo(IncidentType.CUSTOMER_NOT_FOUND);
            assertThat(incident.getReportedBy()).isEqualTo(demo.getFullName());
            assertThat(incident.getAt()).isNotNull();
        });

        OrderDTO forCustomer = transaction.execute(tx ->
                customerOrderMapper.toDto(orderRepository.findById(orderId).orElseThrow()));
        assertThat(forCustomer.getIncidents()).as("o cliente não vê as ocorrências").isNull();

        assertThat(incidentsInTheReport(IncidentType.CUSTOMER_NOT_FOUND)).isEqualTo(before + 1);
    }

    @Test
    void aSecondTapOfTheSameTypeDoesNotDuplicate() {
        courierWorkService.reportIncident(demo, orderId, IncidentType.ORDER_NOT_READY, null);
        courierWorkService.reportIncident(demo, orderId, IncidentType.ORDER_NOT_READY, null);

        assertThat(incidents()).isEqualTo(1);
    }

    @Test
    void otherNeedsANoteAndEachNoteIsKept() {
        assertThatThrownBy(() -> courierWorkService.reportIncident(demo, orderId, IncidentType.OTHER, "  "))
                .isInstanceOf(BadRequestException.class);

        courierWorkService.reportIncident(demo, orderId, IncidentType.OTHER, "Portão trancado");
        courierWorkService.reportIncident(demo, orderId, IncidentType.OTHER, "Interfone quebrado");

        assertThat(jdbc.queryForList("SELECT note FROM order_incidents WHERE order_id = ? ORDER BY id", String.class,
                orderId)).containsExactly("Portão trancado", "Interfone quebrado");
    }

    @Test
    void aFinishedDeliveryTakesNoIncident() {
        jdbc.update("UPDATE orders SET status = 'DELIVERED', delivered_at = now() WHERE id = ?", orderId);

        assertThatThrownBy(() -> courierWorkService.reportIncident(demo, orderId, IncidentType.WRONG_ADDRESS, null))
                .isInstanceOf(BadRequestException.class);
        assertThat(incidents()).isZero();
    }

    private long incidentsInTheReport(IncidentType type) {
        AssociationReportDTO report = reportService.forManager(organizationId, LocalDate.now(), LocalDate.now());
        return report.getIncidents().byRestaurant().stream()
                .filter(r -> r.restaurantId().equals(restaurantId))
                .flatMap(r -> r.byType().stream())
                .filter(t -> t.type() == type)
                .mapToLong(AssociationReportDTO.TypeCount::count)
                .sum();
    }

    private int incidents() {
        return jdbc.queryForObject("SELECT count(*) FROM order_incidents WHERE order_id = ?", Integer.class, orderId);
    }

    private Long newStoreOrder() {
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
        request.setCustomerName("Cliente das ocorrências");
        request.setItems(List.of(item));
        request.setAddress(address);
        request.setPaymentMethod(Order.PaymentMethod.CASH);
        return orderService.createStoreOrder(restaurantId, request).getId();
    }
}
