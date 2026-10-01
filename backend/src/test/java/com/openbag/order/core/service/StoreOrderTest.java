package com.openbag.order.core.service;

import com.openbag.order.core.entity.FulfillmentType;
import com.openbag.order.core.entity.OrderChannel;
import com.openbag.order.core.entity.OrderStatus;
import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.restaurant.combo.repository.ComboRepository;
import com.openbag.delivery.dispatch.service.DeliveryFeeQuoteService;
import com.openbag.restaurant.menu.entity.MenuSection;
import com.openbag.order.core.dto.CreateOrderRequest;
import com.openbag.order.core.dto.CreateStoreOrderRequest;
import com.openbag.order.core.entity.Order;
import com.openbag.order.realtime.OrderChangedEvent;
import com.openbag.order.core.repository.OrderRepository;
import com.openbag.restaurant.catalog.entity.Product;
import com.openbag.restaurant.catalog.repository.ProductRepository;
import com.openbag.restaurant.store.entity.Restaurant;
import com.openbag.restaurant.store.repository.RestaurantRepository;
import com.openbag.platform.geo.GeocodingService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Pedido registrado pela loja (balcão, telefone, WhatsApp)
 */
@ExtendWith(MockitoExtension.class)
class StoreOrderTest {

    private static final long RID = 1L;

    @Mock private OrderRepository orderRepository;
    @Mock private RestaurantRepository restaurantRepository;
    @Mock private ProductRepository productRepository;
    @Mock private ComboRepository comboRepository;
    @Spy private OrderCalculator calculator = new OrderCalculator();
    @Mock private DeliveryFeeQuoteService deliveryFeeQuoteService;
    @Mock private ApplicationEventPublisher events;
    @Mock private CustomerOrderMapper customerOrderMapper;
    @Spy private Clock clock = Clock.fixed(Instant.parse("2026-09-28T15:00:00Z"), ZoneId.of("America/Sao_Paulo"));

    @InjectMocks
    private OrderService service;

    private Restaurant restaurant;

    @BeforeEach
    void setUp() {
        restaurant = new Restaurant();
        restaurant.setId(RID);
        restaurant.setName("Burger");
        restaurant.setMinimumOrder(new BigDecimal("50.00"));
        restaurant.setDeliveryTimeMax(45);

        MenuSection section = new MenuSection();
        Product burger = new Product();
        burger.setId(7L);
        burger.setName("X-Burger");
        burger.setPrice(new BigDecimal("30.00"));
        burger.setMenuSection(section);

        lenient().when(restaurantRepository.findByIdForUpdate(RID)).thenReturn(Optional.of(restaurant));
        lenient().when(productRepository.findByRestaurantIdAndDeletedAtIsNullOrderByPositionAscIdAsc(RID)).thenReturn(List.of(burger));
        lenient().when(comboRepository.findByRestaurantIdAndDeletedAtIsNullOrderByPositionAscIdAsc(RID)).thenReturn(List.of());
        lenient().when(orderRepository.findMaxDailyNumber(eq(RID), any())).thenReturn(41);
        lenient().when(orderRepository.save(any(Order.class))).thenAnswer(inv -> inv.getArgument(0));
    }

    private static CreateStoreOrderRequest request(OrderChannel channel, FulfillmentType fulfillment) {
        CreateStoreOrderRequest request = new CreateStoreOrderRequest();
        request.setChannel(channel);
        request.setFulfillment(fulfillment);
        request.setCustomerName("  Dona Maria ");
        request.setCustomerPhone("(11) 99999-0000");
        request.setItems(List.of(new CreateOrderRequest.ItemRequest(7L, null, 1, null, List.of())));
        request.setPaymentMethod(Order.PaymentMethod.CASH);
        return request;
    }

    private static CreateOrderRequest.AddressRequest address() {
        return new CreateOrderRequest.AddressRequest("Rua A", "10", null, "Centro", "São Paulo", "SP", null, null,
                null, null);
    }

    private Order saved() {
        ArgumentCaptor<Order> captor = ArgumentCaptor.forClass(Order.class);
        verify(orderRepository).save(captor.capture());
        return captor.getValue();
    }

    @Test
    void pickupEntersAcceptedWithoutAddressFeeOrMinimumOrder() {
        var request = request(OrderChannel.COUNTER, FulfillmentType.PICKUP);
        request.setChangeFor(new BigDecimal("50.00"));

        var dto = service.createStoreOrder(RID, request);

        Order order = saved();
        assertThat(order.getStatus()).isEqualTo(OrderStatus.CONFIRMED);
        assertThat(order.getAcceptedAt()).isEqualTo(LocalDateTime.now(clock));
        assertThat(order.getExpectedReadyAt()).isEqualTo(LocalDateTime.now(clock).plusMinutes(20));
        assertThat(order.getUser()).isNull();
        assertThat(order.getCustomerName()).isEqualTo("Dona Maria");
        assertThat(order.getChannel()).isEqualTo(OrderChannel.COUNTER);
        assertThat(order.isPickup()).isTrue();
        assertThat(order.getDeliveryAddress()).isNull();
        assertThat(order.getDeliveryFee()).isEqualByComparingTo("0");
        assertThat(order.getTotalAmount()).isEqualByComparingTo("30.00");
        assertThat(order.getChangeFor()).isEqualByComparingTo("50.00");
        assertThat(order.getDisplayCode()).isEqualTo("#0042");
        assertThat(dto.getFulfillment()).isEqualTo(FulfillmentType.PICKUP);
        verifyNoInteractions(deliveryFeeQuoteService);
        verify(events).publishEvent(new OrderChangedEvent(order.getId(), OrderChangedEvent.Type.ORDER_CREATED));
    }

    @Test
    void deliveryChargesTheFeeForTheLocatedAddress() {
        var request = request(OrderChannel.PHONE, FulfillmentType.DELIVERY);
        request.setAddress(address());
        when(deliveryFeeQuoteService.locate(any(), isNull(), isNull()))
                .thenReturn(new GeocodingService.Coordinates(-23.5, -46.6));
        when(deliveryFeeQuoteService.quote(restaurant, -23.5, -46.6))
                .thenReturn(new DeliveryFeeQuoteService.Quote(-23.5, -46.6, 2.4, new BigDecimal("8.00"), true));

        service.createStoreOrder(RID, request);

        Order order = saved();
        assertThat(order.getFulfillment()).isEqualTo(FulfillmentType.DELIVERY);
        assertThat(order.getDeliveryFee()).isEqualByComparingTo("8.00");
        assertThat(order.getTotalAmount()).isEqualByComparingTo("38.00");
        assertThat(order.getDeliveryAddress()).startsWith("Rua A, 10");
        assertThat(order.getDeliveryDistanceKm()).isEqualTo(2.4);
        assertThat(order.getEstimatedDeliveryTime()).isEqualTo(45);
    }

    @Test
    void deliveryRequiresTheAddress() {
        assertThatThrownBy(() -> service.createStoreOrder(RID, request(OrderChannel.WHATSAPP, FulfillmentType.DELIVERY)))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("endereço");
        verify(orderRepository, never()).save(any());
    }

    @Test
    void appIsNotAStoreChannel() {
        assertThatThrownBy(() -> service.createStoreOrder(RID, request(OrderChannel.APP, FulfillmentType.PICKUP)))
                .isInstanceOf(BadRequestException.class);
    }

    @Test
    void changeMustCoverTheTotal() {
        var request = request(OrderChannel.COUNTER, FulfillmentType.PICKUP);
        request.setChangeFor(new BigDecimal("20.00"));

        assertThatThrownBy(() -> service.createStoreOrder(RID, request)).isInstanceOf(BadRequestException.class);
    }

    @Test
    void theAppCheckoutCreatesADeliveryPinAndTheCounterDoesNot() {
        com.openbag.account.entity.User customer = new com.openbag.account.entity.User();
        customer.setId(9L);
        customer.setFullName("Ana Cliente");
        CreateOrderRequest checkout = new CreateOrderRequest();
        checkout.setRestaurantId(RID);
        checkout.setItems(List.of(new CreateOrderRequest.ItemRequest(7L, null, 2, null, List.of())));
        checkout.setAddress(address());
        checkout.setPaymentMethod(Order.PaymentMethod.PIX);
        when(deliveryFeeQuoteService.quote(eq(restaurant), any(), any()))
                .thenReturn(new com.openbag.delivery.dispatch.service.DeliveryFeeQuoteService.Quote(null, null, null,
                        new BigDecimal("5.00"), false));

        service.createOrder(checkout, customer);
        Order app = saved();
        assertThat(app.getDeliveryPin()).matches("\\d{4}");

        org.mockito.Mockito.clearInvocations(orderRepository);
        service.createStoreOrder(RID, request(OrderChannel.COUNTER, FulfillmentType.PICKUP));
        assertThat(saved().getDeliveryPin()).as("o pedido do balcão usa a confirmação simples").isNull();
    }
}
