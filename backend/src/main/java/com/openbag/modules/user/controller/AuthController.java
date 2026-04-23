package com.openbag.modules.user.controller;

import com.openbag.modules.user.dto.RegisterRequest;
import com.openbag.modules.user.dto.LoginRequest;
import com.openbag.modules.user.dto.JwtAuthenticationResponse;
import com.openbag.modules.user.dto.CheckEmailResponse;
import com.openbag.modules.user.dto.UserPermissionsResponse;
import com.openbag.modules.user.dto.RoleDTO;
import com.openbag.modules.user.dto.PermissionDTO;
import com.openbag.modules.user.entity.User;
import com.openbag.modules.user.repository.UserRepository;
import com.openbag.security.JwtTokenProvider;
import com.openbag.modules.user.service.RoleService;
import com.openbag.modules.restaurant.dto.RestaurantOnboardingRequest;
import com.openbag.modules.restaurant.dto.RestaurantOnboardingResponse;
import com.openbag.modules.restaurant.service.RestaurantOnboardingService;
import com.openbag.modules.restaurant.entity.Restaurant;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/auth")
@Tag(name = "Autenticação", description = "Endpoints para autenticação de usuários")
public class AuthController {

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtTokenProvider tokenProvider;

    @Autowired
    private RoleService roleService;

    @Autowired
    private RestaurantOnboardingService restaurantOnboardingService;

    @PostMapping("/login")
    @Operation(summary = "Login do usuário", description = "Autentica um usuário e retorna um token JWT com roles e permissões")
    public ResponseEntity<?> authenticateUser(@Valid @RequestBody LoginRequest loginRequest) {
        try {
            Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                    loginRequest.getEmail(),
                    loginRequest.getPassword()
                )
            );

            SecurityContextHolder.getContext().setAuthentication(authentication);
            String jwt = tokenProvider.generateToken(authentication);

            User user = userRepository.findById(((com.openbag.security.CustomUserDetailsService.CustomUserPrincipal) authentication.getPrincipal()).getId())
                .orElseThrow(() -> new RuntimeException("Usuário não encontrado"));

            JwtAuthenticationResponse.UserDto userDto = new JwtAuthenticationResponse.UserDto(user);
            
            // Adiciona roles e permissões à resposta
            List<RoleDTO> roles = user.getRoles().stream()
                    .map(RoleDTO::simple)
                    .collect(Collectors.toList());
            
            List<String> permissions = user.getPermissionNames().stream().toList();
            
            return ResponseEntity.ok(new JwtAuthenticationResponse(jwt, userDto, roles, permissions));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(Map.of("error", "Credenciais inválidas"));
        }
    }

    @PostMapping("/register")
    @Operation(summary = "Registro de usuário", description = "Registra um novo usuário no sistema")
    public ResponseEntity<?> registerUser(@Valid @RequestBody RegisterRequest signUpRequest) {
        try {
            if (userRepository.existsByEmail(signUpRequest.getEmail())) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "Email já está em uso"));
            }

            if (userRepository.existsByPhoneNumber(signUpRequest.getPhoneNumber())) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "Telefone já está em uso"));
            }

            // Criar novo usuário
            User user = new User();
            user.setFullName(signUpRequest.getFullName());
            user.setEmail(signUpRequest.getEmail());
            user.setPhoneNumber(signUpRequest.getPhoneNumber());
            user.setPassword(passwordEncoder.encode(signUpRequest.getPassword()));
            
            // Mantém userType para compatibilidade
            if (signUpRequest.getUserType() != null) {
                user.setUserType(signUpRequest.getUserType());
            }

            User result = userRepository.save(user);

            // Processa roles
            List<String> rolesToAdd = new ArrayList<>();
            if (signUpRequest.getRoles() != null && !signUpRequest.getRoles().isEmpty()) {
                // Valida que não está tentando se registrar como ADMIN via API pública
                for (String roleName : signUpRequest.getRoles()) {
                    if ("ADMIN".equalsIgnoreCase(roleName)) {
                        return ResponseEntity.badRequest()
                            .body(Map.of("error", "Não é possível registrar-se como ADMIN via API pública"));
                    }
                    rolesToAdd.add(roleName.toUpperCase());
                }
            }
            
            // Sempre adiciona CUSTOMER se não tiver nenhuma role
            if (rolesToAdd.isEmpty()) {
                rolesToAdd.add("CUSTOMER");
            } else if (!rolesToAdd.contains("CUSTOMER")) {
                rolesToAdd.add("CUSTOMER"); // Garante que sempre tem CUSTOMER
            }

            // Adiciona as roles ao usuário
            roleService.addRolesToUser(result.getId(), rolesToAdd);

            return ResponseEntity.ok(Map.of(
                "message", "Usuário registrado com sucesso",
                "userId", result.getId()
            ));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Erro ao registrar usuário: " + e.getMessage()));
        }
    }

    @GetMapping("/me")
    @Operation(summary = "Perfil do usuário", description = "Retorna informações do usuário autenticado com roles e permissões")
    public ResponseEntity<?> getCurrentUser(Authentication authentication) {
        try {
            String email = authentication.getName();
            User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Usuário não encontrado"));

            JwtAuthenticationResponse.UserDto userDto = new JwtAuthenticationResponse.UserDto(user);
            
            // Adiciona roles e permissões
            List<RoleDTO> roles = user.getRoles().stream()
                    .map(RoleDTO::simple)
                    .collect(Collectors.toList());
            
            List<String> permissions = user.getPermissionNames().stream().toList();
            
            return ResponseEntity.ok(Map.of(
                "user", userDto,
                "roles", roles,
                "permissions", permissions
            ));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(Map.of("error", "Usuário não encontrado"));
        }
    }

    @GetMapping("/check-email")
    @Operation(summary = "Verificar disponibilidade de e-mail", description = "Verifica se um e-mail está disponível para cadastro")
    public ResponseEntity<CheckEmailResponse> checkEmailAvailability(@RequestParam String email) {
        boolean available = !userRepository.existsByEmail(email);
        return ResponseEntity.ok(new CheckEmailResponse(available));
    }

    @PostMapping("/register/restaurant")
    @Operation(summary = "Registro completo de restaurante", description = "Registra um novo restaurante com owner, endereço, horários e configurações")
    public ResponseEntity<?> registerRestaurant(@Valid @RequestBody RestaurantOnboardingRequest request) {
        try {
            Restaurant restaurant = restaurantOnboardingService.completeOnboarding(request);
            
            RestaurantOnboardingResponse response = new RestaurantOnboardingResponse(
                restaurant.getId(),
                "Restaurante cadastrado com sucesso!"
            );
            
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (com.openbag.exception.BadRequestException e) {
            return ResponseEntity.badRequest()
                .body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Erro ao cadastrar restaurante: " + e.getMessage()));
        }
    }
}
