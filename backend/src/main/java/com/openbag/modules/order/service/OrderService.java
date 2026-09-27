package com.openbag.modules.order.service;

import com.openbag.enums.AcceptanceMode;
import com.openbag.enums.CancelledBy;
import com.openbag.enums.OrderStatus;
import com.openbag.exception.BadRequestException;
import com.openbag.exception.ResourceNotFoundException;
import com.openbag.modules.combo.entity.Combo;
import com.openbag.modules.combo.repository.ComboRepository;
import com.openbag.modules.order.dto.CreateOrderRequest;
import com.openbag.modules.order.dto.OrderDTO;
import com.openbag.modules.order.entity.Order;
import com.openbag.modules.order.entity.OrderItem;
import com.openbag.modules.order.entity.OrderTracking;
import com.openbag.modules.order.realtime.OrderChangedEvent;
import com.openbag.modules.order.repository.OrderRepository;
import com.openbag.modules.product.entity.OrderItemCustomization;
import com.openbag.modules.product.entity.Product;
import com.openbag.modules.product.repository.ProductRepository;
import com.openbag.modules.restaurant.entity.Restaurant;
import com.openbag.modules.restaurant.repository.RestaurantRepository;
import com.openbag.modules.user.entity.User;
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
    private Clock clock;

    @Autowired
    private ApplicationEventPublisher events;

    public OrderDTO createOrder(CreateOrderRequest request, User customer) {
        LocalDateTime now = LocalDateTime.now(clock);

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
        BigDecimal deliveryFee = restaurant.getDeliveryFee();
        BigDecimal total = subtotal.add(deliveryFee);

        BigDecimal changeFor = null;
        if (request.getPaymentMethod() == Order.PaymentMethod.CASH && request.getChangeFor() != null) {
            if (request.getChangeFor().compareTo(total) < 0) {
                throw new BadRequestException("O valor para troco deve ser maior ou igual ao total do pedido");
            }
            changeFor = request.getChangeFor();
        }

        int dailyNumber = orderRepository.findMaxDailyNumber(restaurant.getId(), now.toLocalDate().atStartOfDay()) + 1;
        CreateOrderRequest.AddressRequest address = request.getAddress();

        Order order = new Order();
        order.setUser(customer);
        order.setRestaurant(restaurant);
        order.setOrderDate(now);
        order.setDailyNumber(dailyNumber);
        order.setDisplayCode(String.format("#%04d", dailyNumber));
        order.setOrderNumber("OB-" + now.format(ORDER_DATE) + "-" + restaurant.getId() + "-" + dailyNumber);
        order.setSubtotal(subtotal);
        order.setDeliveryFee(deliveryFee);
        order.setTotalAmount(total);
        order.setPaymentMethod(request.getPaymentMethod());
        order.setPaymentStatus(Order.PaymentStatus.PENDING);
        order.setChangeFor(changeFor);
        order.setOrderNotes(request.getNotes() != null && !request.getNotes().isBlank() ? request.getNotes().trim() : null);
        order.setDeliveryAddress(address.format());
        order.setDeliveryLatitude(address.getLatitude());
        order.setDeliveryNeighborhood(address.getNeighborhood().trim());
        order.setDeliveryLongitude(address.getLongitude());
        order.setCustomerName(customer.getFullName());
        order.setCustomerPhone(request.getCustomerPhone() != null && !request.getCustomerPhone().isBlank()
                ? request.getCustomerPhone().trim()
                : customer.getPhoneNumber());
        order.setEstimatedDeliveryTime(restaurant.getDeliveryTimeMax());

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
        return OrderDTO.forCustomer(saved);
    }

    @Transactional(readOnly = true)
    public Page<OrderDTO> getMyOrders(User customer, Pageable pageable) {
        return orderRepository.findByUserIdOrderByOrderDateDesc(customer.getId(), pageable).map(OrderDTO::forCustomer);
    }

    /**
     * Pedido por id; a autorização (cliente, dono do restaurante ou ADMIN) é feita no controller
     */
    @Transactional(readOnly = true)
    public OrderDTO getOrder(Long orderId) {
        return OrderDTO.forCustomer(findOrder(orderId));
    }

    /**
     * O cliente só cancela enquanto o restaurante não aceitou
     */
    public OrderDTO cancelByCustomer(Long orderId, User customer) {
        Order order = orderRepository.findByIdAndUserId(orderId, customer.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Pedido não encontrado"));
        if (order.getStatus() != OrderStatus.PENDING) {
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
        return OrderDTO.forCustomer(saved);
    }

    // ============= Helpers =============

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
