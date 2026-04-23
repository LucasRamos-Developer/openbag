package com.openbag.modules.user.entity;

import com.openbag.modules.order.entity.Order;
import com.openbag.enums.UserType;
import jakarta.persistence.*;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Entity
@Table(name = "users")
@Data
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(exclude = {"roles", "addresses", "orders"})
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank
    @Size(max = 100)
    @Column(name = "full_name")
    private String fullName;

    @NotBlank
    @Email
    @Size(max = 100)
    @Column(unique = true)
    private String email;

    @NotBlank
    @Size(max = 15)
    @Column(name = "phone_number")
    private String phoneNumber;

    @NotBlank
    @Size(min = 6, max = 100)
    private String password;

    /**
     * @deprecated Use roles instead. Mantido para compatibilidade.
     */
    @Deprecated(since = "2.0", forRemoval = false)
    @Enumerated(EnumType.STRING)
    @Column(name = "user_type")
    private UserType userType = UserType.CUSTOMER;

    @ManyToMany(fetch = FetchType.EAGER, cascade = {CascadeType.PERSIST, CascadeType.MERGE})
    @JoinTable(
        name = "user_roles",
        joinColumns = @JoinColumn(name = "user_id"),
        inverseJoinColumns = @JoinColumn(name = "role_id")
    )
    private Set<Role> roles = new HashSet<>();

    @Column(name = "is_active")
    private boolean isActive = true;

    @Column(name = "profile_image_url")
    private String profileImageUrl;

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<Address> addresses = new ArrayList<>();

    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<Order> orders = new ArrayList<>();

    // ============= Helper Methods =============

    /**
     * Verifica se o usuário possui uma role específica
     * @param roleName Nome da role (ex: "ADMIN", "CUSTOMER")
     * @return true se o usuário possui a role
     */
    public boolean hasRole(String roleName) {
        return roles.stream()
                .anyMatch(role -> role.getName().equalsIgnoreCase(roleName));
    }

    /**
     * Verifica se o usuário possui qualquer uma das roles especificadas
     * @param roleNames Nomes das roles
     * @return true se o usuário possui pelo menos uma das roles
     */
    public boolean hasAnyRole(String... roleNames) {
        for (String roleName : roleNames) {
            if (hasRole(roleName)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Verifica se o usuário possui uma permissão específica
     * @param permissionName Nome da permissão (ex: "ORDER_CREATE")
     * @return true se o usuário possui a permissão
     */
    public boolean hasPermission(String permissionName) {
        return roles.stream()
                .flatMap(role -> role.getPermissions().stream())
                .anyMatch(permission -> permission.getName().equalsIgnoreCase(permissionName));
    }

    /**
     * Retorna todas as permissões do usuário (através das suas roles)
     * @return Set com todas as permissões
     */
    public Set<Permission> getAllPermissions() {
        return roles.stream()
                .flatMap(role -> role.getPermissions().stream())
                .collect(Collectors.toSet());
    }

    /**
     * Retorna os nomes de todas as permissões do usuário
     * @return Set com nomes das permissões
     */
    public Set<String> getPermissionNames() {
        return getAllPermissions().stream()
                .map(Permission::getName)
                .collect(Collectors.toSet());
    }

    /**
     * Adiciona uma role ao usuário
     * @param role Role a ser adicionada
     */
    public void addRole(Role role) {
        this.roles.add(role);
        role.getUsers().add(this);
    }

    /**
     * Remove uma role do usuário
     * @param role Role a ser removida
     */
    public void removeRole(Role role) {
        this.roles.remove(role);
        role.getUsers().remove(this);
    }
}
