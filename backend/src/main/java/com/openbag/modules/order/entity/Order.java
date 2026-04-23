package com.openbag.modules.order.entity;

import com.openbag.modules.user.entity.User;
import com.openbag.modules.restaurant.entity.Restaurant;
import com.openbag.modules.delivery.entity.DeliveryPerson;
import com.openbag.enums.OrderStatus;
import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "orders")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "order_number", unique = true)
    private String orderNumber;

    @NotNull
    @Column(name = "subtotal", precision = 10, scale = 2)
    private BigDecimal subtotal;

    @NotNull
    @Column(name = "delivery_fee", precision = 10, scale = 2)
    private BigDecimal deliveryFee;

    @NotNull
    @Column(name = "total_amount", precision = 10, scale = 2)
    private BigDecimal totalAmount;

    @NotNull
    @Column(name = "order_date")
    private LocalDateTime orderDate;

    @Enumerated(EnumType.STRING)
    private OrderStatus status = OrderStatus.PENDING;

    @Enumerated(EnumType.STRING)
    @Column(name = "payment_method")
    private PaymentMethod paymentMethod;

    @Enumerated(EnumType.STRING)
    @Column(name = "payment_status")
    private PaymentStatus paymentStatus = PaymentStatus.PENDING;

    @Column(name = "estimated_delivery_time")
    private Integer estimatedDeliveryTime;

    @Column(name = "delivery_address", length = 500)
    private String deliveryAddress;

    @Column(name = "order_notes", length = 500)
    private String orderNotes;

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @Column(name = "delivered_at")
    private LocalDateTime deliveredAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "restaurant_id")
    private Restaurant restaurant;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "delivery_person_id")
    private DeliveryPerson deliveryPerson;

    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<OrderItem> items = new ArrayList<>();

    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<OrderTracking> trackings = new ArrayList<>();

    // Constructors
    public Order(User user, Restaurant restaurant, BigDecimal subtotal, BigDecimal deliveryFee, 
                PaymentMethod paymentMethod, String deliveryAddress) {
        this.user = user;
        this.restaurant = restaurant;
        this.subtotal = subtotal;
        this.deliveryFee = deliveryFee;
        this.totalAmount = subtotal.add(deliveryFee);
        this.paymentMethod = paymentMethod;
        this.deliveryAddress = deliveryAddress;
        this.orderNumber = generateOrderNumber();
        this.orderDate = LocalDateTime.now();
    }

    private String generateOrderNumber() {
        return "ORD-" + System.currentTimeMillis();
    }

    public enum PaymentMethod {
        CREDIT_CARD, DEBIT_CARD, PIX, CASH, FOOD_VOUCHER
    }

    public enum PaymentStatus {
        PENDING, PROCESSING, PAID, FAILED, REFUNDED
    }
}
