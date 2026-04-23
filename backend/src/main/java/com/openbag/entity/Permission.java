package com.openbag.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "permissions")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Permission {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank
    @Size(max = 100)
    @Column(unique = true, nullable = false)
    private String name;

    @Size(max = 255)
    private String description;

    @NotBlank
    @Size(max = 50)
    @Column(nullable = false)
    private String category;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @ManyToMany(mappedBy = "permissions")
    @Builder.Default
    private Set<Role> roles = new HashSet<>();

    /**
     * Categorias de permissões
     */
    public enum Category {
        ORDERS,
        RESTAURANTS,
        PRODUCTS,
        DELIVERY,
        USERS,
        ASSOCIATION
    }

    /**
     * Enum com todas as permissões disponíveis
     */
    public enum PermissionName {
        // ORDERS
        ORDER_CREATE("ORDERS", "Criar pedidos"),
        ORDER_VIEW("ORDERS", "Visualizar próprios pedidos"),
        ORDER_VIEW_ALL("ORDERS", "Visualizar todos os pedidos"),
        ORDER_MANAGE("ORDERS", "Gerenciar pedidos"),
        ORDER_ASSIGN_DELIVERY("ORDERS", "Atribuir entregador ao pedido"),

        // RESTAURANTS
        RESTAURANT_CREATE("RESTAURANTS", "Criar restaurante"),
        RESTAURANT_VIEW("RESTAURANTS", "Visualizar restaurantes"),
        RESTAURANT_EDIT("RESTAURANTS", "Editar próprio restaurante"),
        RESTAURANT_DELETE("RESTAURANTS", "Deletar próprio restaurante"),
        RESTAURANT_MANAGE_ALL("RESTAURANTS", "Gerenciar todos os restaurantes"),

        // PRODUCTS
        PRODUCT_CREATE("PRODUCTS", "Criar produtos"),
        PRODUCT_EDIT("PRODUCTS", "Editar produtos"),
        PRODUCT_DELETE("PRODUCTS", "Deletar produtos"),
        PRODUCT_VIEW("PRODUCTS", "Visualizar produtos"),

        // DELIVERY
        DELIVERY_VIEW_ASSIGNED("DELIVERY", "Visualizar entregas atribuídas"),
        DELIVERY_ACCEPT("DELIVERY", "Aceitar entregas"),
        DELIVERY_UPDATE_STATUS("DELIVERY", "Atualizar status de entrega"),
        DELIVERY_VIEW_ALL("DELIVERY", "Visualizar todas as entregas"),

        // USERS
        USER_VIEW("USERS", "Visualizar usuários"),
        USER_EDIT("USERS", "Editar usuários"),
        USER_MANAGE_ALL("USERS", "Gerenciar todos os usuários"),
        USER_DELETE("USERS", "Deletar usuários"),

        // ASSOCIATION
        ASSOCIATION_MANAGE_DELIVERY_PERSONS("ASSOCIATION", "Gerenciar entregadores da associação"),
        ASSOCIATION_VIEW_STATS("ASSOCIATION", "Visualizar estatísticas da associação");

        private final String category;
        private final String description;

        PermissionName(String category, String description) {
            this.category = category;
            this.description = description;
        }

        public String getCategory() {
            return category;
        }

        public String getDescription() {
            return description;
        }
    }
}
