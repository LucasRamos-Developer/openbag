package com.openbag.order.core.service;

import com.openbag.restaurant.store.entity.AcceptanceMode;
import com.openbag.order.core.entity.CancelledBy;
import com.openbag.order.core.entity.FulfillmentType;
import com.openbag.order.core.entity.OrderChannel;
import com.openbag.order.core.entity.OrderStatus;
import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.platform.web.exception.ResourceNotFoundException;
import com.openbag.restaurant.combo.entity.Combo;
import com.openbag.restaurant.combo.repository.ComboRepository;
import com.openbag.delivery.dispatch.dto.DeliveryQuoteDTO;
import com.openbag.delivery.dispatch.service.DeliveryFeeQuoteService;
import com.openbag.order.core.dto.CreateOrderRequest;
import com.openbag.order.core.dto.CreateStoreOrderRequest;
import com.openbag.order.core.dto.DeliveryQuoteRequest;
import com.openbag.order.core.dto.OrderDTO;
import com.openbag.order.core.entity.Order;
import com.openbag.order.core.entity.OrderItem;
import com.openbag.order.core.entity.OrderTracking;
import com.openbag.order.realtime.OrderChangedEvent;
import com.openbag.order.core.repository.OrderRepository;
import com.openbag.order.core.entity.OrderItemCustomization;
import com.openbag.restaurant.catalog.entity.Product;
import com.openbag.restaurant.catalog.repository.ProductRepository;
import com.openbag.restaurant.store.entity.Restaurant;
import com.openbag.restaurant.store.repository.RestaurantRepository;
import com.openbag.platform.geo.GeocodingService;
import com.openbag.account.entity.User;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDateTime;
import java.text.NumberFormat;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Pedidos do cliente: criação (com preços recalculados no servidor), consulta e cancelamento
 */
@Service
@Transactional
@Slf4j
public class OrderService {

    private static final java.security.SecureRandom PIN_RANDOM = new java.security.SecureRandom();

    private static final DateTimeFormatter ORDER_DATE = DateTimeFormatter.ofPattern("yyyyMMdd");
    private static final NumberFormat BRL = NumberFormat.getCurrencyInstance(Locale.of("pt", "BR"));

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private RestaurantRepository restaurantRepository;

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private ComboRepository comboRepository;

    @Autowired
    private OrderCalculator calculator;

    @Autowired
    private DeliveryFeeQuoteService deliveryFeeQuoteService;

    @Autowired
    private Clock clock;

    @Autowired
    private ApplicationEventPublisher events;

    @Autowired
    private CustomerOrderMapper customerOrderMapper;

    @Transactional(readOnly = true)
    public DeliveryQuoteDTO quoteDelivery(DeliveryQuoteRequest request) {
        Restaurant restaurant = restaurantRepository.findByIdAndIsActiveTrue(request.restaurantId())
                .orElseThrow(() -> new ResourceNotFoundException("Restaurante não encontrado"));
        return DeliveryQuoteDTO.from(deliveryFeeQuoteService.quote(restaurant, request.toQuery(),
                request.latitude(), request.longitude()));
    }

    public OrderDTO createOrder(CreateOrderRequest request, User customer) {
        LocalDateTime now = LocalDateTime.now(clock);

        // Localiza o endereço antes de travar a loja: a consulta ao mapa pode levar alguns segundos
        CreateOrderRequest.AddressRequest deliveryAddress = request.getAddress();
        GeocodingService.Coordinates point = deliveryFeeQuoteService.locate(deliveryAddress.toQuery(),
                deliveryAddress.getLatitude(), deliveryAddress.getLongitude());

        // Lock no restaurante: serializa a numeração do dia e a checagem de "aberto"
        Restaurant restaurant = restaurantRepository.findByIdForUpdate(request.getRestaurantId())
                .orElseThrow(() -> new ResourceNotFoundException("Restaurante não encontrado"));
        if (!restaurant.isOpenNow(now)) {
            throw new BadRequestException(restaurant.isPaused(now)
                    ? "O restaurante pausou os pedidos por alguns minutos. Tente novamente em breve."
                    : "O restaurante está fechado no momento");
        }

        var lines = calculator.price(request.getItems(), sellableProducts(restaurant.getId()), sellableCombos(restaurant.getId()));
        BigDecimal subtotal = calculator.subtotal(lines);
        if (subtotal.compareTo(restaurant.getMinimumOrder()) < 0) {
            throw new BadRequestException("O pedido mínimo deste restaurante é " + BRL.format(restaurant.getMinimumOrder()));
        }
        // Taxa fixa da loja ou, se ela repassa, pela distância até o endereço (calculada aqui, nunca pelo app)
        DeliveryFeeQuoteService.Quote quote = point != null
                ? deliveryFeeQuoteService.quote(restaurant, point.latitude(), point.longitude())
                : deliveryFeeQuoteService.quote(restaurant, null, null);
        BigDecimal deliveryFee = quote.fee();
        BigDecimal total = subtotal.add(deliveryFee);

        Order order = newOrder(restaurant, now, lines, subtotal, deliveryFee);
        order.setUser(customer);
        order.setChannel(OrderChannel.APP);
        // PIN de entrega: sempre gerado; só é pedido ao entregador se a loja exigir
        order.setDeliveryPin(String.format("%04d", PIN_RANDOM.nextInt(10_000)));
        order.setFulfillment(FulfillmentType.DELIVERY);
        order.setPaymentMethod(request.getPaymentMethod());
        order.setChangeFor(changeFor(request.getPaymentMethod(), request.getChangeFor(), total));
        order.setOrderNotes(trimToNull(request.getNotes()));
        applyAddress(order, request.getAddress(), quote);
        order.setCustomerName(customer.getFullName());
        order.setCustomerPhone(request.getCustomerPhone() != null && !request.getCustomerPhone().isBlank()
                ? request.getCustomerPhone().trim()
                : customer.getPhoneNumber());
        order.setEstimatedDeliveryTime(restaurant.getDeliveryTimeMax());

        addTracking(order, OrderStatus.PENDING, "Pedido recebido", now);
        if (restaurant.getAcceptanceMode() == AcceptanceMode.AUTO) {
            order.setStatus(OrderStatus.CONFIRMED);
            order.setAcceptedAt(now);
            order.setExpectedReadyAt(now.plusMinutes(restaurant.getDefaultPreparationMinutes()));
            addTracking(order, OrderStatus.CONFIRMED, "Pedido confirmado pelo restaurante", now);
        } else {
            order.setStatus(OrderStatus.PENDING);
            order.setAcceptDeadline(now.plusMinutes(restaurant.getAcceptanceTimeoutMinutes()));
        }

        Order saved = orderRepository.save(order);
        events.publishEvent(new OrderChangedEvent(saved.getId(), OrderChangedEvent.Type.ORDER_CREATED));
        log.info("Pedido {} ({}) criado no restaurante {} com status {}", saved.getId(), saved.getDisplayCode(),
                restaurant.getId(), saved.getStatus());
        return customerOrderMapper.toDto(saved);
    }

    /**
     * Pedido registrado pela própria loja (balcão, telefone, WhatsApp) para um cliente sem conta. Entra já aceito
     * e segue o fluxo dos pedidos do app: cozinha, despacho (se for entrega) e caixa. A loja fechada ou pausada não
     * impede o registro, e o pedido mínimo não se aplica: quem decide é quem está atendendo.
     */
    public OrderDTO createStoreOrder(Long restaurantId, CreateStoreOrderRequest request) {
        if (request.getChannel() == OrderChannel.APP) {
            throw new BadRequestException("Escolha balcão, telefone ou WhatsApp");
        }
        boolean pickup = request.getFulfillment() == FulfillmentType.PICKUP;
        CreateOrderRequest.AddressRequest address = request.getAddress();
        if (!pickup && address == null) {
            throw new BadRequestException("Informe o endereço de entrega");
        }
        LocalDateTime now = LocalDateTime.now(clock);

        // Localiza o endereço antes de travar a loja: a consulta ao mapa pode levar alguns segundos
        GeocodingService.Coordinates point = pickup ? null
                : deliveryFeeQuoteService.locate(address.toQuery(), address.getLatitude(), address.getLongitude());

        Restaurant restaurant = restaurantRepository.findByIdForUpdate(restaurantId)
                .orElseThrow(() -> new ResourceNotFoundException("Restaurante não encontrado"));

        var lines = calculator.price(request.getItems(), sellableProducts(restaurant.getId()), sellableCombos(restaurant.getId()));
        BigDecimal subtotal = calculator.subtotal(lines);
        DeliveryFeeQuoteService.Quote quote = null;
        if (!pickup) {
            quote = point != null
                    ? deliveryFeeQuoteService.quote(restaurant, point.latitude(), point.longitude())
                    : deliveryFeeQuoteService.quote(restaurant, null, null);
        }
        BigDecimal deliveryFee = quote != null ? quote.fee() : BigDecimal.ZERO;
        BigDecimal total = subtotal.add(deliveryFee);

        Order order = newOrder(restaurant, now, lines, subtotal, deliveryFee);
        order.setChannel(request.getChannel());
        order.setFulfillment(request.getFulfillment());
        order.setPaymentMethod(request.getPaymentMethod());
        order.setChangeFor(changeFor(request.getPaymentMethod(), request.getChangeFor(), total));
        order.setOrderNotes(trimToNull(request.getNotes()));
        order.setCustomerName(request.getCustomerName().trim());
        order.setCustomerPhone(trimToNull(request.getCustomerPhone()));
        if (!pickup) {
            applyAddress(order, address, quote);
            order.setEstimatedDeliveryTime(restaurant.getDeliveryTimeMax());
        }

        order.setStatus(OrderStatus.CONFIRMED);
        order.setAcceptedAt(now);
        order.setExpectedReadyAt(now.plusMinutes(restaurant.getDefaultPreparationMinutes()));
        addTracking(order, OrderStatus.CONFIRMED,
                "Pedido registrado pela loja (" + request.getChannel().getDisplayName().toLowerCase(Locale.ROOT) + ")", now);

        Order saved = orderRepository.save(order);
        events.publishEvent(new OrderChangedEvent(saved.getId(), OrderChangedEvent.Type.ORDER_CREATED));
        log.info("Pedido {} ({}) registrado pela loja {} ({}, {})", saved.getId(), saved.getDisplayCode(),
                restaurant.getId(), request.getChannel(), request.getFulfillment());
        return OrderDTO.from(saved);
    }

    @Transactional(readOnly = true)
    public Page<OrderDTO> getMyOrders(User customer, Pageable pageable) {
        return customerOrderMapper.toDtos(orderRepository.findByUserIdOrderByOrderDateDesc(customer.getId(), pageable));
    }

    /**
     * Pedido por id; a autorização (cliente, dono do restaurante ou ADMIN) é feita no controller
     */
    @Transactional(readOnly = true)
    public OrderDTO getOrder(Long orderId) {
        return customerOrderMapper.toDto(findOrder(orderId));
    }

    /**
     * O cliente só cancela enquanto o restaurante não aceitou
     */
    public OrderDTO cancelByCustomer(Long orderId, User customer) {
        // Travado: se o restaurante aceitar no mesmo instante, só uma das duas ações vale
        Order order = orderRepository.findByIdForUpdate(orderId)
                .filter(o -> o.getUser() != null && o.getUser().getId().equals(customer.getId()))
                .orElseThrow(() -> new ResourceNotFoundException("Pedido não encontrado"));
        if (order.getStatus() != OrderStatus.PENDING || !order.getStatus().canTransitionTo(OrderStatus.CANCELLED)) {
            throw new BadRequestException("O restaurante já aceitou o pedido. Para cancelar, fale com o restaurante.");
        }
        LocalDateTime now = LocalDateTime.now(clock);
        order.setStatus(OrderStatus.CANCELLED);
        order.setCancelledAt(now);
        order.setCancelledBy(CancelledBy.CUSTOMER);
        order.setCancellationReason("Cancelado pelo cliente");
        addTracking(order, OrderStatus.CANCELLED, "Pedido cancelado pelo cliente", now);
        Order saved = orderRepository.save(order);
        events.publishEvent(new OrderChangedEvent(saved.getId(), OrderChangedEvent.Type.ORDER_UPDATED));
        return customerOrderMapper.toDto(saved);
    }

    // ============= Helpers =============

    /**
     * Pedido com a numeração do dia, os valores e os itens já precificados. A loja precisa estar travada
     * ({@code findByIdForUpdate}) para dois pedidos não receberem o mesmo número.
     */
    private Order newOrder(Restaurant restaurant, LocalDateTime now, List<OrderCalculator.PricedLine> lines,
                           BigDecimal subtotal, BigDecimal deliveryFee) {
        int dailyNumber = orderRepository.findMaxDailyNumber(restaurant.getId(), now.toLocalDate().atStartOfDay()) + 1;

        Order order = new Order();
        order.setRestaurant(restaurant);
        order.setOrderDate(now);
        order.setDailyNumber(dailyNumber);
        order.setDisplayCode(String.format("#%04d", dailyNumber));
        order.setOrderNumber("OB-" + now.format(ORDER_DATE) + "-" + restaurant.getId() + "-" + dailyNumber);
        order.setSubtotal(subtotal);
        order.setDeliveryFee(deliveryFee);
        order.setTotalAmount(subtotal.add(deliveryFee));
        order.setPaymentStatus(Order.PaymentStatus.PENDING);

        for (OrderCalculator.PricedLine line : lines) {
            OrderItem item = new OrderItem();
            item.setOrder(order);
            item.setProduct(line.product());
            item.setCombo(line.combo());
            item.setItemName(line.name());
            item.setQuantity(line.quantity());
            item.setUnitPrice(line.unitPrice());
            item.setSubtotal(line.totalPrice());
            item.setTotalPrice(line.totalPrice());
            item.setObservations(line.notes());
            for (OrderCalculator.PricedOption option : line.options()) {
                OrderItemCustomization customization = new OrderItemCustomization();
                customization.setOrderItem(item);
                customization.setCustomizationOption(option.option());
                customization.setGroupName(option.groupName());
                customization.setOptionName(option.optionName());
                customization.setPriceAtPurchase(option.price());
                item.getCustomizations().add(customization);
            }
            order.getItems().add(item);
        }
        return order;
    }

    /** Troco só no dinheiro, e para um valor que cubra o total */
    private static BigDecimal changeFor(Order.PaymentMethod method, BigDecimal changeFor, BigDecimal total) {
        if (method != Order.PaymentMethod.CASH || changeFor == null) {
            return null;
        }
        if (changeFor.compareTo(total) < 0) {
            throw new BadRequestException("O valor para troco deve ser maior ou igual ao total do pedido");
        }
        return changeFor;
    }

    private static void applyAddress(Order order, CreateOrderRequest.AddressRequest address,
                                     DeliveryFeeQuoteService.Quote quote) {
        order.setDeliveryAddress(address.format());
        order.setDeliveryNeighborhood(address.getNeighborhood().trim());
        order.setDeliveryLatitude(quote.latitude());
        order.setDeliveryLongitude(quote.longitude());
        order.setDeliveryDistanceKm(quote.distanceKm());
    }

    private static String trimToNull(String value) {
        return value != null && !value.isBlank() ? value.trim() : null;
    }

    private Order findOrder(Long orderId) {
        return orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Pedido não encontrado"));
    }

    /**
     * Itens que podem ser vendidos agora: não excluídos, visíveis, disponíveis e em seção visível
     */
    private Map<Long, Product> sellableProducts(Long restaurantId) {
        return productRepository.findByRestaurantIdAndDeletedAtIsNullOrderByPositionAscIdAsc(restaurantId).stream()
                .filter(p -> p.isActive() && p.isAvailable())
                .filter(p -> p.getMenuSection() != null && p.getMenuSection().isActive())
                .collect(Collectors.toMap(Product::getId, Function.identity()));
    }

    /**
     * Combos vendáveis: além do próprio combo, todos os itens dele precisam estar disponíveis
     */
    private Map<Long, Combo> sellableCombos(Long restaurantId) {
        return comboRepository.findByRestaurantIdAndDeletedAtIsNullOrderByPositionAscIdAsc(restaurantId).stream()
                .filter(c -> c.isActive() && c.isAvailable())
                .filter(c -> c.getMenuSection() != null && c.getMenuSection().isActive())
                .filter(c -> c.getComboItems().stream().allMatch(i ->
                        i.getProduct().getDeletedAt() == null && i.getProduct().isAvailable()))
                .collect(Collectors.toMap(Combo::getId, Function.identity()));
    }

    public void addTracking(Order order, OrderStatus status, String message, LocalDateTime at) {
        OrderTracking tracking = new OrderTracking();
        tracking.setOrder(order);
        tracking.setStatus(status);
        tracking.setMessage(message);
        tracking.setDescription(message);
        tracking.setTimestamp(at);
        order.getTrackings().add(tracking);
    }
}
