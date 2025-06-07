package com.openbag.service;

import com.openbag.entity.*;
import com.openbag.enums.OrderStatus;
import com.openbag.exception.BadRequestException;
import com.openbag.exception.ResourceNotFoundException;
import com.openbag.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Service
@Transactional
public class OrderService {

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private OrderTrackingRepository orderTrackingRepository;

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private UserService userService;

    public Order createOrder(Order order) {
        User currentUser = userService.getCurrentUser();
        order.setUser(currentUser);
        order.setOrderDate(LocalDateTime.now());
        order.setStatus(OrderStatus.PENDING);

        // Validar e calcular total do pedido
        BigDecimal totalAmount = BigDecimal.ZERO;
        Restaurant restaurant = null;

        for (OrderItem item : order.getItems()) {
            Product product = productRepository.findById(item.getProduct().getId())
                    .orElseThrow(() -> new ResourceNotFoundException("Produto não encontrado"));

            if (!product.isActive()) {
                throw new BadRequestException("Produto não está disponível: " + product.getName());
            }

            if (restaurant == null) {
                restaurant = product.getRestaurant();
            } else if (!restaurant.getId().equals(product.getRestaurant().getId())) {
                throw new BadRequestException("Todos os produtos devem ser do mesmo restaurante");
            }

            if (!product.getRestaurant().isActive()) {
                throw new BadRequestException("Restaurante não está ativo");
            }

            item.setProduct(product);
            item.setUnitPrice(product.getPrice());
            item.setSubtotal(product.getPrice().multiply(BigDecimal.valueOf(item.getQuantity())));
            item.setOrder(order);

            totalAmount = totalAmount.add(item.getSubtotal());
        }

        if (restaurant == null) {
            throw new BadRequestException("Nenhum restaurante encontrado nos itens do pedido");
        }

        order.setRestaurant(restaurant);
        
        // Adicionar taxa de entrega
        BigDecimal deliveryFee = restaurant.getDeliveryFee();
        order.setDeliveryFee(deliveryFee);
        totalAmount = totalAmount.add(deliveryFee);

        // Verificar pedido mínimo
        BigDecimal itemsTotal = totalAmount.subtract(deliveryFee);
        if (itemsTotal.compareTo(restaurant.getMinimumOrder()) < 0) {
            throw new BadRequestException("Valor mínimo do pedido é " + restaurant.getMinimumOrder());
        }

        order.setTotalAmount(totalAmount);

        Order savedOrder = orderRepository.save(order);

        // Criar tracking inicial
        createOrderTracking(savedOrder, OrderStatus.PENDING, "Pedido criado");

        return savedOrder;
    }

    public Order getOrderById(Long id) {
        User currentUser = userService.getCurrentUser();
        return orderRepository.findByIdAndUserId(id, currentUser.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Pedido não encontrado"));
    }

    public Page<Order> getUserOrders(Pageable pageable) {
        User currentUser = userService.getCurrentUser();
        return orderRepository.findByUserIdOrderByOrderDateDesc(currentUser.getId(), pageable);
    }

    public List<Order> getRestaurantOrders(Long restaurantId) {
        return orderRepository.findByRestaurantIdOrderByOrderDateDesc(restaurantId);
    }

    public Order updateOrderStatus(Long orderId, OrderStatus newStatus) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Pedido não encontrado"));

        // Validar transição de status
        if (!isValidStatusTransition(order.getStatus(), newStatus)) {
            throw new BadRequestException("Transição de status inválida de " + 
                    order.getStatus() + " para " + newStatus);
        }

        order.setStatus(newStatus);
        Order updatedOrder = orderRepository.save(order);

        // Criar tracking
        String message = getStatusMessage(newStatus);
        createOrderTracking(updatedOrder, newStatus, message);

        return updatedOrder;
    }

    public void cancelOrder(Long orderId) {
        Order order = getOrderById(orderId);

        if (order.getStatus() != OrderStatus.PENDING && order.getStatus() != OrderStatus.CONFIRMED) {
            throw new BadRequestException("Não é possível cancelar pedido com status: " + order.getStatus());
        }

        order.setStatus(OrderStatus.CANCELLED);
        orderRepository.save(order);

        createOrderTracking(order, OrderStatus.CANCELLED, "Pedido cancelado pelo cliente");
    }

    public List<OrderTracking> getOrderTracking(Long orderId) {
        Order order = getOrderById(orderId);
        return orderTrackingRepository.findByOrderIdOrderByTimestampAsc(order.getId());
    }

    private void createOrderTracking(Order order, OrderStatus status, String message) {
        OrderTracking tracking = new OrderTracking();
        tracking.setOrder(order);
        tracking.setStatus(status);
        tracking.setMessage(message);
        tracking.setTimestamp(LocalDateTime.now());
        orderTrackingRepository.save(tracking);
    }

    private boolean isValidStatusTransition(OrderStatus currentStatus, OrderStatus newStatus) {
        switch (currentStatus) {
            case PENDING:
                return newStatus == OrderStatus.CONFIRMED || newStatus == OrderStatus.CANCELLED;
            case CONFIRMED:
                return newStatus == OrderStatus.PREPARING || newStatus == OrderStatus.CANCELLED;
            case PREPARING:
                return newStatus == OrderStatus.READY_FOR_PICKUP;
            case READY_FOR_PICKUP:
                return newStatus == OrderStatus.OUT_FOR_DELIVERY;
            case OUT_FOR_DELIVERY:
                return newStatus == OrderStatus.DELIVERED;
            case DELIVERED:
            case CANCELLED:
                return false;
            default:
                return false;
        }
    }

    private String getStatusMessage(OrderStatus status) {
        switch (status) {
            case PENDING:
                return "Aguardando confirmação";
            case CONFIRMED:
                return "Pedido confirmado";
            case PREPARING:
                return "Preparando seu pedido";
            case READY_FOR_PICKUP:
                return "Pronto para retirada";
            case OUT_FOR_DELIVERY:
                return "Saiu para entrega";
            case DELIVERED:
                return "Pedido entregue";
            case CANCELLED:
                return "Pedido cancelado";
            default:
                return "Status atualizado";
        }
    }
}
