package com.openbag.controller;

import com.openbag.dto.AddressDTO;
import com.openbag.dto.RoleDTO;
import com.openbag.dto.UserPermissionsResponse;
import com.openbag.entity.Permission;
import com.openbag.entity.Role;
import com.openbag.entity.User;
import com.openbag.repository.UserRepository;
import com.openbag.service.PermissionService;
import com.openbag.service.RoleService;
import com.openbag.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/users")
@Tag(name = "User", description = "API de gerenciamento de usuários")
@SecurityRequirement(name = "bearerAuth")
public class UserController {

    @Autowired
    private UserService userService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RoleService roleService;

    @Autowired
    private PermissionService permissionService;

    @GetMapping("/profile")
    @Operation(summary = "Buscar perfil do usuário atual")
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<User> getCurrentUserProfile() {
        User user = userService.getCurrentUser();
        return ResponseEntity.ok(user);
    }

    @PutMapping("/profile")
    @Operation(summary = "Atualizar perfil do usuário")
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<User> updateProfile(@Valid @RequestBody User userDetails) {
        User updatedUser = userService.updateUser(userDetails);
        return ResponseEntity.ok(updatedUser);
    }

    @GetMapping("/addresses")
    @Operation(summary = "Listar endereços do usuário")
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<List<AddressDTO>> getUserAddresses() {
        List<AddressDTO> addresses = userService.getUserAddresses();
        return ResponseEntity.ok(addresses);
    }

    @PostMapping("/addresses")
    @Operation(summary = "Adicionar novo endereço")
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<AddressDTO> addAddress(@Valid @RequestBody AddressDTO addressDTO) {
        AddressDTO savedAddress = userService.addAddress(addressDTO);
        return ResponseEntity.ok(savedAddress);
    }

    @PutMapping("/addresses/{addressId}")
    @Operation(summary = "Atualizar endereço")
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<AddressDTO> updateAddress(
            @PathVariable Long addressId,
            @Valid @RequestBody AddressDTO addressDTO) {
        AddressDTO updatedAddress = userService.updateAddress(addressId, addressDTO);
        return ResponseEntity.ok(updatedAddress);
    }

    @DeleteMapping("/addresses/{addressId}")
    @Operation(summary = "Remover endereço")
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<Void> deleteAddress(@PathVariable Long addressId) {
        userService.deleteAddress(addressId);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/profile")
    @Operation(summary = "Desativar conta do usuário")
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<Void> deactivateAccount() {
        userService.deactivateUser();
        return ResponseEntity.noContent().build();
    }

    // ============= Endpoints de Gerenciamento de Roles/Permissões =============

    @PostMapping("/{id}/roles")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Adicionar role a usuário", description = "Adiciona uma role a um usuário (somente ADMIN)")
    public ResponseEntity<?> addRoleToUser(@PathVariable Long id, @RequestBody Map<String, String> request) {
        try {
            String roleName = request.get("roleName");
            if (roleName == null || roleName.isBlank()) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "Nome da role é obrigatório"));
            }

            roleService.addRoleToUser(id, roleName.toUpperCase());

            return ResponseEntity.ok(Map.of(
                "message", "Role adicionada com sucesso",
                "userId", id,
                "roleName", roleName
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(Map.of("error", e.getMessage()));
        }
    }

    @DeleteMapping("/{id}/roles/{roleName}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Remover role de usuário", description = "Remove uma role de um usuário (somente ADMIN)")
    public ResponseEntity<?> removeRoleFromUser(@PathVariable Long id, @PathVariable String roleName) {
        try {
            roleService.removeRoleFromUser(id, roleName.toUpperCase());

            return ResponseEntity.ok(Map.of(
                "message", "Role removida com sucesso",
                "userId", id,
                "roleName", roleName
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/{id}/roles")
    @PreAuthorize("hasRole('ADMIN') or #id == principal.id")
    @Operation(summary = "Listar roles de usuário", description = "Lista todas as roles de um usuário")
    public ResponseEntity<?> getUserRoles(@PathVariable Long id) {
        try {
            List<Role> roles = roleService.getUserRoles(id);
            List<RoleDTO> roleDTOs = roles.stream()
                    .map(RoleDTO::simple)
                    .collect(Collectors.toList());

            return ResponseEntity.ok(Map.of(
                "userId", id,
                "roles", roleDTOs
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/{id}/permissions")
    @PreAuthorize("hasRole('ADMIN') or #id == principal.id")
    @Operation(summary = "Listar permissões de usuário", description = "Lista todas as permissões de um usuário")
    public ResponseEntity<?> getUserPermissions(@PathVariable Long id) {
        try {
            List<Permission> permissions = roleService.getUserPermissions(id);
            List<String> permissionNames = permissions.stream()
                    .map(Permission::getName)
                    .collect(Collectors.toList());

            return ResponseEntity.ok(Map.of(
                "userId", id,
                "permissions", permissionNames
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/me/permissions")
    @Operation(summary = "Minhas permissões", description = "Retorna roles e permissões do usuário logado")
    public ResponseEntity<?> getMyPermissions(Authentication authentication) {
        try {
            var principal = (com.openbag.security.CustomUserDetailsService.CustomUserPrincipal) authentication.getPrincipal();
            Long userId = principal.getId();

            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new RuntimeException("Usuário não encontrado"));

            UserPermissionsResponse response = UserPermissionsResponse.fromUser(user);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(Map.of("error", e.getMessage()));
        }
    }

    @PutMapping("/{id}/roles")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Substituir roles de usuário", description = "Substitui todas as roles de um usuário (somente ADMIN)")
    public ResponseEntity<?> setUserRoles(@PathVariable Long id, @RequestBody Map<String, List<String>> request) {
        try {
            List<String> roleNames = request.get("roleNames");
            if (roleNames == null || roleNames.isEmpty()) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "Lista de roles é obrigatória"));
            }

            // Converte para uppercase
            List<String> upperRoleNames = roleNames.stream()
                    .map(String::toUpperCase)
                    .collect(Collectors.toList());

            roleService.setUserRoles(id, upperRoleNames);

            return ResponseEntity.ok(Map.of(
                "message", "Roles atualizadas com sucesso",
                "userId", id,
                "roleNames", upperRoleNames
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(Map.of("error", e.getMessage()));
        }
    }
}
