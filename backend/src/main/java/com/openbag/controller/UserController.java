package com.openbag.controller;

import com.openbag.dto.AddressDTO;
import com.openbag.entity.User;
import com.openbag.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.List;

@RestController
@RequestMapping("/api/users")
@Tag(name = "User", description = "API de gerenciamento de usuários")
@SecurityRequirement(name = "bearerAuth")
public class UserController {

    @Autowired
    private UserService userService;

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
}
