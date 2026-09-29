package com.openbag.delivery.courier.controller;

import com.openbag.delivery.courier.dto.CourierEarningsDTO;
import com.openbag.delivery.link.dto.CourierLinkDTO;
import com.openbag.delivery.courier.dto.CourierProfileDTO;
import com.openbag.delivery.courier.dto.CourierProfileUpdateRequest;
import com.openbag.delivery.link.dto.LinkTargetRequest;
import com.openbag.delivery.courier.dto.VehicleDTO;
import com.openbag.delivery.courier.dto.VehicleRequest;
import com.openbag.delivery.courier.dto.WorkHistoryDTO;
import com.openbag.delivery.courier.service.CourierEarningsService;
import com.openbag.delivery.link.service.CourierLinkService;
import com.openbag.delivery.courier.service.CourierProfileService;
import com.openbag.account.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/me/courier")
@SecurityRequirement(name = "bearerAuth")
@PreAuthorize("hasRole('DELIVERY_PERSON')")
@Tag(name = "Courier", description = "Perfil e veículos do entregador logado")
public class CourierController {

    @Autowired
    private CourierProfileService profileService;

    @Autowired
    private CourierLinkService linkService;

    @Autowired
    private CourierEarningsService earningsService;

    @Autowired
    private UserService userService;

    @GetMapping
    @Operation(summary = "Meu perfil de entregador")
    public ResponseEntity<CourierProfileDTO> getProfile() {
        return ResponseEntity.ok(profileService.getMyProfile(userService.getCurrentUser()));
    }

    @PutMapping
    @Operation(summary = "Atualizar perfil (nome, telefone, bio, redes sociais, visibilidade)")
    public ResponseEntity<CourierProfileDTO> updateProfile(@Valid @RequestBody CourierProfileUpdateRequest request) {
        return ResponseEntity.ok(profileService.updateProfile(userService.getCurrentUser(), request));
    }

    @PostMapping(value = "/photo", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Atualizar foto do perfil")
    public ResponseEntity<CourierProfileDTO> updatePhoto(@RequestParam("file") MultipartFile file) {
        return ResponseEntity.ok(profileService.updatePhoto(userService.getCurrentUser(), file));
    }

    // ============= Veículos =============

    @GetMapping("/vehicles")
    @Operation(summary = "Meus veículos")
    public ResponseEntity<List<VehicleDTO>> listVehicles() {
        return ResponseEntity.ok(profileService.listVehicles(userService.getCurrentUser()));
    }

    @PostMapping("/vehicles")
    @Operation(summary = "Cadastrar veículo", description = "O primeiro veículo cadastrado já fica em uso")
    public ResponseEntity<VehicleDTO> createVehicle(@Valid @RequestBody VehicleRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(profileService.createVehicle(userService.getCurrentUser(), request));
    }

    @PutMapping("/vehicles/{vehicleId}")
    @Operation(summary = "Editar veículo")
    public ResponseEntity<VehicleDTO> updateVehicle(@PathVariable Long vehicleId,
                                                    @Valid @RequestBody VehicleRequest request) {
        return ResponseEntity.ok(profileService.updateVehicle(userService.getCurrentUser(), vehicleId, request));
    }

    @PostMapping(value = "/vehicles/{vehicleId}/photo", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Atualizar foto do veículo")
    public ResponseEntity<VehicleDTO> updateVehiclePhoto(@PathVariable Long vehicleId,
                                                         @RequestParam("file") MultipartFile file) {
        return ResponseEntity.ok(profileService.updateVehiclePhoto(userService.getCurrentUser(), vehicleId, file));
    }

    @PostMapping("/vehicles/{vehicleId}/activate")
    @Operation(summary = "Usar este veículo")
    public ResponseEntity<List<VehicleDTO>> activateVehicle(@PathVariable Long vehicleId) {
        return ResponseEntity.ok(profileService.activateVehicle(userService.getCurrentUser(), vehicleId));
    }

    @DeleteMapping("/vehicles/{vehicleId}")
    @Operation(summary = "Remover veículo", description = "O veículo é arquivado; o último veículo não pode ser removido")
    public ResponseEntity<List<VehicleDTO>> archiveVehicle(@PathVariable Long vehicleId) {
        return ResponseEntity.ok(profileService.archiveVehicle(userService.getCurrentUser(), vehicleId));
    }

    // ============= Restaurantes (entregador fixo) =============

    @GetMapping("/restaurants")
    @Operation(summary = "Restaurantes em que sou fixo, pedidos e convites")
    public ResponseEntity<List<CourierLinkDTO>> listRestaurants() {
        return ResponseEntity.ok(linkService.listMine(userService.getCurrentUser()));
    }

    @PostMapping("/restaurants/link")
    @Operation(summary = "Pedir para ser entregador fixo", description = "Pelo link da página do restaurante (/r/...)")
    public ResponseEntity<CourierLinkDTO> requestLink(@Valid @RequestBody LinkTargetRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(linkService.request(userService.getCurrentUser(), request.slug()));
    }

    @PostMapping("/restaurants/{linkId}/accept")
    @Operation(summary = "Aceitar convite do restaurante")
    public ResponseEntity<CourierLinkDTO> acceptLink(@PathVariable Long linkId) {
        return ResponseEntity.ok(linkService.accept(userService.getCurrentUser(), linkId));
    }

    @PostMapping("/restaurants/{linkId}/decline")
    @Operation(summary = "Recusar convite do restaurante")
    public ResponseEntity<CourierLinkDTO> declineLink(@PathVariable Long linkId) {
        return ResponseEntity.ok(linkService.decline(userService.getCurrentUser(), linkId));
    }

    @PostMapping("/restaurants/{linkId}/end")
    @Operation(summary = "Deixar de ser fixo (ou cancelar pedido)")
    public ResponseEntity<CourierLinkDTO> endLink(@PathVariable Long linkId) {
        return ResponseEntity.ok(linkService.endByCourier(userService.getCurrentUser(), linkId));
    }

    // ============= Ganhos e histórico =============

    @GetMapping("/earnings")
    @Operation(summary = "Ganhos", description = "Hoje, semana e mês, mais a série diária e as entregas do período (padrão: 7 dias)")
    public ResponseEntity<CourierEarningsDTO> getEarnings(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ResponseEntity.ok(earningsService.getEarnings(userService.getCurrentUser(), from, to));
    }

    @GetMapping("/history")
    @Operation(summary = "Onde trabalhei: restaurantes e turnos recentes")
    public ResponseEntity<WorkHistoryDTO> getHistory() {
        return ResponseEntity.ok(earningsService.getHistory(userService.getCurrentUser()));
    }
}
