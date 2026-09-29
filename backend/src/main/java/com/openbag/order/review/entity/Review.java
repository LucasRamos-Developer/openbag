package com.openbag.order.review.entity;

import com.openbag.delivery.courier.entity.DeliveryPerson;
import com.openbag.order.core.entity.Order;
import com.openbag.restaurant.store.entity.Restaurant;
import com.openbag.account.entity.User;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * Avaliação do cliente depois da entrega: uma por pedido, com nota da loja e, quando o pedido foi levado por
 * um entregador do app, nota do entregador. A parte do entregador não aparece para a loja.
 */
@Entity
@Table(name = "reviews", indexes = {
        @Index(name = "idx_review_restaurant", columnList = "restaurant_id, created_at"),
        @Index(name = "idx_review_courier", columnList = "delivery_person_id")
})
@Getter
@Setter
@NoArgsConstructor
public class Review {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "order_id", nullable = false, unique = true)
    private Order order;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "restaurant_id", nullable = false)
    private Restaurant restaurant;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "delivery_person_id")
    private DeliveryPerson deliveryPerson;

    @Column(name = "restaurant_rating", nullable = false)
    private Integer restaurantRating;

    @Column(name = "restaurant_comment", length = 500)
    private String restaurantComment;

    @Column(name = "courier_rating")
    private Integer courierRating;

    @Column(name = "courier_comment", length = 500)
    private String courierComment;

    @Column(name = "restaurant_reply", length = 500)
    private String restaurantReply;

    @Column(name = "replied_at")
    private LocalDateTime repliedAt;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;
}
