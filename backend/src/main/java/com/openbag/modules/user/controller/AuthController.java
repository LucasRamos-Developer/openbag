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
import com.openbag.modules.user.service.AccountService;
import com.openbag.modules.organization.dto.AccountRequest;
import com.openbag.enums.UserType;
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
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/auth")
@Tag(name = "Autenticação", description = "Endpoints para autenticação de usuários")
public class AuthController {

    @Autowired
    private com.fasterxml.jackson.databind.ObjectMapper objectMapper;

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

    @Autowired
    private AccountService accountService;

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
        // O cadastro público sempre cria um cliente: o tipo e as roles nunca vêm do pedido.
        // Loja, associação e entregador têm cadastros próprios
        AccountRequest account = new AccountRequest(signUpRequest.getFullName(), signUpRequest.getEmail(),
                signUpRequest.getPhoneNumber(), signUpRequest.getPassword());
        User result = accountService.createAccount(account, UserType.CUSTOMER, "CUSTOMER");

        return ResponseEntity.ok(Map.of(
            "message", "Usuário registrado com sucesso",
            "userId", result.getId()
        ));
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

    @PostMapping(value = "/register/restaurant", consumes = {"application/json"})
    @Operation(
        summary = "Registro de restaurante (JSON)",
        description = "Registra um novo restaurante sem upload de imagens usando JSON"
    )
    public ResponseEntity<?> registerRestaurantJson(@Valid @RequestBody RestaurantOnboardingRequest request) {
        try {
            Restaurant restaurant = restaurantOnboardingService.completeOnboarding(request, null, null);
            
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

    @PostMapping(value = "/register/restaurant", consumes = {"multipart/form-data"})
    @Operation(
        summary = "Registro completo de restaurante (com imagens)",
        description = "Registra um novo restaurante com owner, endereço, horários, configurações e upload de logo/banner"
    )
    public ResponseEntity<?> registerRestaurantMultipart(
            @RequestPart("data") String dataJson,
            @RequestPart(value = "logo", required = false) MultipartFile logo,
            @RequestPart(value = "banner", required = false) MultipartFile banner) {
        try {
            // Parse manual do JSON da parte "data" (mapper do Spring: entende LocalTime dos horários)
            RestaurantOnboardingRequest request = objectMapper.readValue(dataJson, RestaurantOnboardingRequest.class);
            
            Restaurant restaurant = restaurantOnboardingService.completeOnboarding(request, logo, banner);
            
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
