package com.openbag.association.core.controller;

import com.openbag.association.core.entity.OrganizationStatus;
import com.openbag.association.core.dto.AssociationDTO;
import com.openbag.association.core.dto.ReasonRequest;
import com.openbag.association.core.service.AssociationService;
import com.openbag.account.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/admin/associations")
@SecurityRequirement(name = "bearerAuth")
@PreAuthorize("hasRole('ADMIN')")
@Tag(name = "Admin Associations", description = "Moderação de associações/cooperativas pelo ADMIN da plataforma")
public class AdminAssociationController {

    @Autowired
    private AssociationService associationService;

    @Autowired
    private UserService userService;

    @GetMapping
    @Operation(summary = "Listar associações", description = "Filtro opcional por status (ex: PENDING_APPROVAL)")
    public ResponseEntity<Page<AssociationDTO>> list(
            @Parameter(description = "Status da associação") @RequestParam(required = false) OrganizationStatus status,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        return ResponseEntity.ok(associationService.listForAdmin(status, pageable));
    }

    @PostMapping("/{id}/approve")
    @Operation(summary = "Aprovar (ou reativar) associação")
    public ResponseEntity<AssociationDTO> approve(@PathVariable Long id) {
        return ResponseEntity.ok(associationService.approve(id, userService.getCurrentUser()));
    }

    @PostMapping("/{id}/reject")
    @Operation(summary = "Recusar associação", description = "O motivo é obrigatório e fica visível para o gestor")
    public ResponseEntity<AssociationDTO> reject(@PathVariable Long id, @Valid @RequestBody ReasonRequest request) {
        return ResponseEntity.ok(associationService.reject(id, request.getReason(), userService.getCurrentUser()));
    }

    @PostMapping("/{id}/suspend")
    @Operation(summary = "Suspender associação")
    public ResponseEntity<AssociationDTO> suspend(@PathVariable Long id,
                                                  @Valid @RequestBody(required = false) ReasonRequest request) {
        String reason = request != null ? request.getReason() : null;
        return ResponseEntity.ok(associationService.suspend(id, reason, userService.getCurrentUser()));
    }
}
