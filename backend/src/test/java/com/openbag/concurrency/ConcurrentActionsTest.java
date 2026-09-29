package com.openbag.concurrency;

import com.openbag.platform.seed.DemoDataInitializer;
import com.openbag.enums.DeliveryOfferStatus;
import com.openbag.enums.FulfillmentType;
import com.openbag.enums.InvoiceStatus;
import com.openbag.enums.LedgerAccount;
import com.openbag.enums.ManualEntryKind;
import com.openbag.enums.MemberPaymentMethod;
import com.openbag.enums.OrderChannel;
import com.openbag.enums.OrderStatus;
import com.openbag.modules.cooperative.dto.LedgerEntryRequest;
import com.openbag.modules.cooperative.dto.PayInvoiceRequest;
import com.openbag.modules.cooperative.repository.LedgerEntryRepository;
import com.openbag.modules.cooperative.service.LedgerService;
import com.openbag.modules.cooperative.service.MemberInvoiceService;
import com.openbag.delivery.courier.dto.LocationRequest;
import com.openbag.delivery.dispatch.entity.DeliveryOffer;
import com.openbag.delivery.courier.entity.DeliveryPerson;
import com.openbag.delivery.dispatch.repository.DeliveryOfferRepository;
import com.openbag.delivery.courier.repository.DeliveryPersonRepository;
import com.openbag.delivery.courier.service.CourierWorkService;
import com.openbag.order.core.dto.CreateOrderRequest;
import com.openbag.order.core.dto.CreateStoreOrderRequest;
import com.openbag.order.core.entity.Order;
import com.openbag.order.core.repository.OrderRepository;
import com.openbag.order.core.service.OrderService;
import com.openbag.order.core.service.RestaurantOrderService;
import com.openbag.modules.user.entity.User;
import com.openbag.modules.user.repository.UserRepository;
import com.openbag.support.IntegrationTest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.RepeatedTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.support.TransactionTemplate;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.function.Supplier;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Duas ações sobre o mesmo registro ao mesmo tempo, contra o banco de verdade e com os dados de demonstração.
 * Cada caso reproduz uma corrida encontrada na revisão da 0.4.0: sem as travas, ele falhava (ou falhava às vezes).
 */
class ConcurrentActionsTest extends IntegrationTest {

    @Autowired private OrderService orderService;
    @Autowired private RestaurantOrderService restaurantOrderService;
    @Autowired private CourierWorkService courierWorkService;
    @Autowired private MemberInvoiceService invoiceService;
    @Autowired private LedgerService ledgerService;
    @Autowired private OrderRepository orderRepository;
    @Autowired private DeliveryOfferRepository offerRepository;
    @Autowired private DeliveryPersonRepository deliveryPersonRepository;
    @Autowired private LedgerEntryRepository ledgerRepository;
    @Autowired private UserRepository userRepository;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private TransactionTemplate transaction;

    private User demo;
    private Long restaurantId;
    private Long courierId;

    @BeforeEach
    void cleanSlate() {
        demo = userRepository.findByEmail(DemoDataInitializer.DEMO_EMAIL).orElseThrow();
        restaurantId = jdbc.queryForObject("SELECT id FROM restaurants WHERE slug = 'cantina-demo'", Long.class);
        courierId = deliveryPersonRepository.findByUserId(demo.getId()).orElseThrow().getId();
        // Nenhuma entrega nem oferta em aberto de testes anteriores; entregador offline
        jdbc.update("UPDATE delivery_offers SET status = 'CANCELLED' WHERE status = 'PENDING'");
        jdbc.update("UPDATE orders SET status = 'DELIVERED', courier_settled_at = now() "
                + "WHERE status NOT IN ('DELIVERED', 'CANCELLED')");
        jdbc.update("UPDATE delivery_persons SET work_status = 'OFFLINE', is_available = false WHERE id = ?", courierId);
    }

    // ============= Pedido =============

    @RepeatedTest(3)
    void customerCancelAndRestaurantAcceptNeverBothWin() throws Exception {
        Long orderId = newOrder();
        jdbc.update("UPDATE orders SET status = 'PENDING', user_id = ?, accepted_at = NULL WHERE id = ?", demo.getId(), orderId);
        jdbc.update("DELETE FROM order_tracking WHERE order_id = ?", orderId);

        List<Throwable> results = race(
                () -> orderService.cancelByCustomer(orderId, demo),
                () -> restaurantOrderService.accept(restaurantId, orderId));

        assertThat(results).as("só uma das duas ações vale").containsOnlyOnce((Throwable) null);
        Order order = orderRepository.findById(orderId).orElseThrow();
        List<String> history = jdbc.queryForList("SELECT status FROM order_tracking WHERE order_id = ?", String.class, orderId);
        assertThat(history).containsExactly(order.getStatus().name());
    }

    @RepeatedTest(3)
    void restaurantReadyDuringTheCourierAcceptKeepsTheCourier() throws Exception {
        Long orderId = newOrder();
        Long offerId = offerTo(orderId);

        List<Throwable> results = race(
                () -> courierWorkService.acceptOffer(demo, offerId),
                () -> restaurantOrderService.ready(restaurantId, orderId));

        assertThat(results).containsOnlyNulls();
        Order order = orderRepository.findById(orderId).orElseThrow();
        assertThat(order.getStatus()).isEqualTo(OrderStatus.READY_FOR_PICKUP);
        assertThat(order.getDeliveryPerson()).as("o pronto da loja não apaga o entregador").isNotNull();
        assertThat(order.getDeliveryPerson().getId()).isEqualTo(courierId);
        assertThat(workStatus()).isEqualTo("BUSY");
    }

    @RepeatedTest(3)
    void locationPingDuringTheAcceptDoesNotPutTheCourierBackOnline() throws Exception {
        Long orderId = newOrder();
        Long offerId = offerTo(orderId);
        LocationRequest here = new LocationRequest();
        here.setLatitude(-26.9195);
        here.setLongitude(-49.0662);
        // Último ping há dois minutos: o primeiro deste teste vale (os seguintes caem no throttling)
        jdbc.update("UPDATE delivery_persons SET last_seen_at = now() - interval '2 minutes' WHERE id = ?", courierId);

        List<Throwable> results = race(
                () -> courierWorkService.acceptOffer(demo, offerId),
                () -> {
                    for (int i = 0; i < 5; i++) {
                        courierWorkService.updateLocation(demo, here);
                    }
                    return null;
                });

        assertThat(results).containsOnlyNulls();
        assertThat(workStatus()).as("o ping não desfaz o aceite").isEqualTo("BUSY");
        assertThat(jdbc.queryForObject("SELECT last_latitude FROM delivery_persons WHERE id = ?", Double.class, courierId))
                .isEqualTo(-26.9195);
    }

    @Test
    void doubleTapOnAcceptAssignsTheOrderOnce() throws Exception {
        Long orderId = newOrder();
        Long offerId = offerTo(orderId);

        List<Throwable> results = race(
                () -> courierWorkService.acceptOffer(demo, offerId),
                () -> courierWorkService.acceptOffer(demo, offerId));

        // O segundo toque espera o primeiro e recebe a entrega já aceita, sem erro
        assertThat(results).containsOnlyNulls();
        assertThat(jdbc.queryForObject("SELECT count(*) FROM order_tracking WHERE order_id = ? AND description LIKE 'Entregador definido%'",
                Integer.class, orderId)).isEqualTo(1);
    }

    // ============= Cooperativa =============

    @Test
    void invoicePaidTwiceAtTheSameTimeIsRecordedOnce() throws Exception {
        Long organizationId = demoOrganization();
        Long invoiceId = jdbc.queryForObject("SELECT id FROM member_invoices WHERE organization_id = ? AND status = 'OPEN' "
                + "ORDER BY id LIMIT 1", Long.class, organizationId);
        PayInvoiceRequest payment = new PayInvoiceRequest(MemberPaymentMethod.PIX, null, null);

        List<Throwable> results = race(
                () -> invoiceService.pay(organizationId, invoiceId, payment, demo),
                () -> invoiceService.pay(organizationId, invoiceId, payment, demo));

        assertThat(results).containsOnlyOnce((Throwable) null);
        Integer lines = jdbc.queryForObject("SELECT count(*) FROM member_invoice_lines WHERE invoice_id = ? AND amount > 0",
                Integer.class, invoiceId);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM ledger_entries WHERE invoice_id = ?", Integer.class, invoiceId))
                .as("a mensalidade e a caixinha entram uma vez só").isEqualTo(lines);
        assertThat(jdbc.queryForObject("SELECT status FROM member_invoices WHERE id = ?", String.class, invoiceId))
                .isEqualTo(InvoiceStatus.PAID.name());
    }

    @Test
    void twoAidsAtTheSameTimeNeverOverdrawTheSolidarityFund() throws Exception {
        Long organizationId = demoOrganization();
        Long membershipId = jdbc.queryForObject("SELECT id FROM association_memberships WHERE organization_id = ? "
                + "AND status = 'ACTIVE' ORDER BY id LIMIT 1", Long.class, organizationId);
        BigDecimal balance = ledgerRepository.balance(organizationId, LedgerAccount.SOLIDARITY_FUND);
        if (balance.compareTo(new BigDecimal("10.00")) < 0) {
            ledgerService.create(organizationId, new LedgerEntryRequest(ManualEntryKind.CONTRIBUTION,
                    new BigDecimal("100.00"), null, "Contribuição de teste", membershipId), demo);
            balance = ledgerRepository.balance(organizationId, LedgerAccount.SOLIDARITY_FUND);
        }
        // Cada auxílio cabe no saldo sozinho, mas os dois juntos não
        BigDecimal aid = balance.multiply(new BigDecimal("0.6")).setScale(2, java.math.RoundingMode.DOWN);
        LedgerEntryRequest request = new LedgerEntryRequest(ManualEntryKind.AID, aid, null, "Auxílio de teste", membershipId);

        List<Throwable> results = race(
                () -> ledgerService.create(organizationId, request, demo),
                () -> ledgerService.create(organizationId, request, demo));

        assertThat(results).containsOnlyOnce((Throwable) null);
        assertThat(ledgerRepository.balance(organizationId, LedgerAccount.SOLIDARITY_FUND)).isNotNegative();
    }

    // ============= Auxiliares =============

    /** Pedido de balcão para entrega (entra já aceito), sem entregador */
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
        request.setChannel(OrderChannel.COUNTER);
        request.setFulfillment(FulfillmentType.DELIVERY);
        request.setCustomerName("Cliente de teste");
        request.setItems(List.of(item));
        request.setAddress(address);
        request.setPaymentMethod(Order.PaymentMethod.PIX);
        return orderService.createStoreOrder(restaurantId, request).getId();
    }

    /** Entregador online com uma oferta pendente do pedido */
    private Long offerTo(Long orderId) {
        jdbc.update("UPDATE delivery_persons SET work_status = 'ONLINE', is_available = true, last_seen_at = now() "
                + "WHERE id = ?", courierId);
        return transaction.execute(tx -> {
            jdbc.update("UPDATE delivery_offers SET status = 'CANCELLED' WHERE status = 'PENDING'");
            DeliveryOffer offer = new DeliveryOffer();
            offer.setOrder(orderRepository.findById(orderId).orElseThrow());
            DeliveryPerson courier = deliveryPersonRepository.findById(courierId).orElseThrow();
            offer.setDeliveryPerson(courier);
            offer.setStatus(DeliveryOfferStatus.PENDING);
            offer.setCourierFee(new BigDecimal("8.00"));
            offer.setOfferedAt(LocalDateTime.now());
            offer.setExpiresAt(LocalDateTime.now().plusMinutes(5));
            return offerRepository.save(offer).getId();
        });
    }

    private String workStatus() {
        return jdbc.queryForObject("SELECT work_status FROM delivery_persons WHERE id = ?", String.class, courierId);
    }

    private Long demoOrganization() {
        return jdbc.queryForObject("SELECT organization_id FROM delivery_persons WHERE id = ?", Long.class, courierId);
    }

    /**
     * Roda as ações ao mesmo tempo (todas esperam o mesmo sinal para começar). Devolve, na ordem, null para cada
     * ação que deu certo ou a exceção que ela lançou.
     */
    private static List<Throwable> race(Supplier<?>... actions) throws Exception {
        ExecutorService pool = Executors.newFixedThreadPool(actions.length);
        CountDownLatch start = new CountDownLatch(1);
        try {
            List<Future<?>> futures = new ArrayList<>();
            for (Supplier<?> action : actions) {
                futures.add(pool.submit(() -> {
                    start.await();
                    return action.get();
                }));
            }
            start.countDown();
            List<Throwable> results = new ArrayList<>();
            for (Future<?> future : futures) {
                try {
                    future.get(30, TimeUnit.SECONDS);
                    results.add(null);
                } catch (java.util.concurrent.ExecutionException e) {
                    results.add(e.getCause());
                }
            }
            return results;
        } finally {
            pool.shutdownNow();
        }
    }
}
