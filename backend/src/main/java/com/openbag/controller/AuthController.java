package com.openbag.controller;

import com.openbag.dto.JwtAuthenticationResponse;
import com.openbag.dto.LoginRequest;
import com.openbag.dto.RegisterRequest;
import com.openbag.entity.User;
import com.openbag.repository.UserRepository;
import com.openbag.security.JwtTokenProvider;
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

import java.util.Map;

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

    @PostMapping("/login")
    @Operation(summary = "Login do usuário", description = "Autentica um usuário e retorna um token JWT")
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

            User user = userRepository.findByEmail(loginRequest.getEmail())
                .orElseThrow(() -> new RuntimeException("Usuário não encontrado"));

            JwtAuthenticationResponse.UserDto userDto = new JwtAuthenticationResponse.UserDto(user);
            
            return ResponseEntity.ok(new JwtAuthenticationResponse(jwt, userDto));
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
            user.setUserType(signUpRequest.getUserType());

            User result = userRepository.save(user);

            return ResponseEntity.ok(Map.of(
                "message", "Usuário registrado com sucesso",
                "userId", result.getId()
            ));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Erro interno do servidor"));
        }
    }

    @GetMapping("/me")
    @Operation(summary = "Perfil do usuário", description = "Retorna informações do usuário autenticado")
    public ResponseEntity<?> getCurrentUser(Authentication authentication) {
        try {
            String email = authentication.getName();
            User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Usuário não encontrado"));

            JwtAuthenticationResponse.UserDto userDto = new JwtAuthenticationResponse.UserDto(user);
            return ResponseEntity.ok(userDto);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(Map.of("error", "Usuário não encontrado"));
        }
    }
}
