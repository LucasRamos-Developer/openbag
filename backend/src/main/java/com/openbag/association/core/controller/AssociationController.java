package com.openbag.association.core.controller;

import com.openbag.platform.security.annotation.IsAssociationManager;
import com.openbag.association.core.dto.MemberBillingFilter;
import com.openbag.association.core.entity.MembershipStatus;
import com.openbag.delivery.courier.entity.VehicleType;
import com.openbag.association.core.dto.AssociationDTO;
import com.openbag.association.core.dto.AssociationStatsDTO;
import com.openbag.association.core.dto.AssociationUpdateRequest;
import com.openbag.association.core.dto.CreateInviteRequest;
import com.openbag.association.core.dto.CreateMemberRequest;
import com.openbag.association.core.dto.DeliveryRateDTO;
import com.openbag.association.core.dto.InviteDTO;
import com.openbag.association.core.dto.MemberDTO;
import com.openbag.association.core.dto.ReasonRequest;
import com.openbag.association.core.service.AssociationService;
import com.openbag.association.core.service.InviteService;
import com.openbag.association.core.service.MemberExportService;
import com.openbag.association.core.service.MembershipService;
import com.openbag.platform.util.CsvWriter;
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
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/associations")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Association", description = "Painel do gestor da associação/cooperativa")
public class AssociationController {

    @Autowired
    private AssociationService associationService;

    @Autowired
    private MembershipService membershipService;

    @Autowired
    private InviteService inviteService;

    @Autowired
    private MemberExportService memberExportService;

    @Autowired
    private UserService userService;

    // ============= Associação =============

    @GetMapping("/me")
    @PreAuthorize("hasRole('ASSOCIATION_MANAGER')")
    @Operation(summary = "Associação do gestor logado")
    public ResponseEntity<AssociationDTO> getMyAssociation() {
        return ResponseEntity.ok(associationService.getManagedAssociation(userService.getCurrentUser()));
    }

    @GetMapping("/{id}")
    @IsAssociationManager
    @Operation(summary = "Dados da associação")
    public ResponseEntity<AssociationDTO> getAssociation(@PathVariable Long id) {
        return ResponseEntity.ok(associationService.getAssociation(id));
    }

    @PutMapping("/{id}")
    @IsAssociationManager
    @Operation(summary = "Atualizar dados da associação",
            description = "Uma associação recusada volta para análise ao ser editada")
    public ResponseEntity<AssociationDTO> updateAssociation(@PathVariable Long id,
                                                            @Valid @RequestBody AssociationUpdateRequest request) {
        return ResponseEntity.ok(associationService.update(id, request));
    }

    @PostMapping(value = "/{id}/logo", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @IsAssociationManager
    @Operation(summary = "Atualizar logo da associação")
    public ResponseEntity<AssociationDTO> updateLogo(@PathVariable Long id, @RequestParam("file") MultipartFile file) {
        return ResponseEntity.ok(associationService.updateLogo(id, file));
    }

    @PutMapping("/{id}/delivery-rate")
    @IsAssociationManager
    @Operation(summary = "Definir a tabela de valores de entrega",
            description = "Valor base até X km e adicional por km acima disso (zero = sem adicional)")
    public ResponseEntity<AssociationDTO> updateDeliveryRate(@PathVariable Long id,
                                                             @Valid @RequestBody DeliveryRateDTO request) {
        return ResponseEntity.ok(associationService.updateDeliveryRate(id, request));
    }

    @GetMapping("/{id}/stats")
    @IsAssociationManager
    @Operation(summary = "Estatísticas da associação")
    public ResponseEntity<AssociationStatsDTO> getStats(@PathVariable Long id) {
        return ResponseEntity.ok(associationService.getStats(id));
    }

    // ============= Associados =============

    @GetMapping("/{id}/members")
    @IsAssociationManager
    @Operation(summary = "Listar associados", description = "Filtro opcional por status e busca por nome, email ou CPF")
    public ResponseEntity<Page<MemberDTO>> listMembers(
            @PathVariable Long id,
            @Parameter(description = "Status do vínculo") @RequestParam(required = false) MembershipStatus status,
            @Parameter(description = "Tipo do veículo em uso") @RequestParam(required = false) VehicleType vehicleType,
            @Parameter(description = "Mensalidade: OPEN (com fatura em aberto) ou UP_TO_DATE")
            @RequestParam(required = false) MemberBillingFilter billing,
            @Parameter(description = "Busca por nome, email ou CPF") @RequestParam(required = false) String q,
            @PageableDefault(size = 20, sort = "requestedAt", direction = Sort.Direction.DESC) Pageable pageable) {
        return ResponseEntity.ok(membershipService.listMembers(id, status, vehicleType, billing, q, pageable));
    }

    @GetMapping(value = "/{id}/members/export", produces = CsvWriter.MEDIA_TYPE)
    @IsAssociationManager
    @Operation(summary = "Exportar associados (CSV)", description = "Mesmos filtros da listagem; abre direto no Excel")
    public ResponseEntity<byte[]> exportMembers(
            @PathVariable Long id,
            @RequestParam(required = false) MembershipStatus status,
            @RequestParam(required = false) VehicleType vehicleType,
            @RequestParam(required = false) MemberBillingFilter billing,
            @RequestParam(required = false) String q) {
        String filename = "associados-" + LocalDate.now() + ".csv";
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, ContentDisposition.attachment().filename(filename).build().toString())
                .contentType(MediaType.parseMediaType(CsvWriter.MEDIA_TYPE))
                .body(memberExportService.exportCsv(id, status, vehicleType, billing, q));
    }

    @GetMapping("/{id}/members/{membershipId}")
    @IsAssociationManager
    @Operation(summary = "Detalhes do associado")
    public ResponseEntity<MemberDTO> getMember(@PathVariable Long id, @PathVariable Long membershipId) {
        return ResponseEntity.ok(membershipService.getMember(id, membershipId));
    }

    @PostMapping("/{id}/members")
    @IsAssociationManager
    @Operation(summary = "Cadastrar associado", description = "O gestor cria a conta do entregador, que já entra ativo")
    public ResponseEntity<MemberDTO> createMember(@PathVariable Long id, @Valid @RequestBody CreateMemberRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(membershipService.createMember(id, request, userService.getCurrentUser()));
    }

    @PostMapping("/{id}/members/{membershipId}/approve")
    @IsAssociationManager
    @Operation(summary = "Aprovar solicitação de entrada")
    public ResponseEntity<MemberDTO> approveMember(@PathVariable Long id, @PathVariable Long membershipId) {
        return ResponseEntity.ok(membershipService.approve(id, membershipId, userService.getCurrentUser()));
    }

    @PostMapping("/{id}/members/{membershipId}/reject")
    @IsAssociationManager
    @Operation(summary = "Recusar solicitação de entrada")
    public ResponseEntity<MemberDTO> rejectMember(@PathVariable Long id, @PathVariable Long membershipId,
                                                  @Valid @RequestBody(required = false) ReasonRequest request) {
        return ResponseEntity.ok(membershipService.reject(id, membershipId, reasonOf(request), userService.getCurrentUser()));
    }

    @PostMapping("/{id}/members/{membershipId}/suspend")
    @IsAssociationManager
    @Operation(summary = "Suspender associado")
    public ResponseEntity<MemberDTO> suspendMember(@PathVariable Long id, @PathVariable Long membershipId,
                                                   @Valid @RequestBody(required = false) ReasonRequest request) {
        return ResponseEntity.ok(membershipService.suspend(id, membershipId, reasonOf(request), userService.getCurrentUser()));
    }

    @PostMapping("/{id}/members/{membershipId}/reactivate")
    @IsAssociationManager
    @Operation(summary = "Reativar associado suspenso")
    public ResponseEntity<MemberDTO> reactivateMember(@PathVariable Long id, @PathVariable Long membershipId) {
        return ResponseEntity.ok(membershipService.reactivate(id, membershipId, userService.getCurrentUser()));
    }

    @PostMapping("/{id}/members/{membershipId}/remove")
    @IsAssociationManager
    @Operation(summary = "Desligar associado")
    public ResponseEntity<MemberDTO> removeMember(@PathVariable Long id, @PathVariable Long membershipId,
                                                  @Valid @RequestBody(required = false) ReasonRequest request) {
        return ResponseEntity.ok(membershipService.remove(id, membershipId, reasonOf(request), userService.getCurrentUser()));
    }

    // ============= Convites =============

    @GetMapping("/{id}/invites")
    @IsAssociationManager
    @Operation(summary = "Listar convites")
    public ResponseEntity<List<InviteDTO>> listInvites(@PathVariable Long id) {
        return ResponseEntity.ok(inviteService.listInvites(id));
    }

    @PostMapping("/{id}/invites")
    @IsAssociationManager
    @Operation(summary = "Gerar código de convite")
    public ResponseEntity<InviteDTO> createInvite(@PathVariable Long id,
                                                  @Valid @RequestBody(required = false) CreateInviteRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(inviteService.createInvite(id, request, userService.getCurrentUser()));
    }

    @DeleteMapping("/{id}/invites/{inviteId}")
    @IsAssociationManager
    @Operation(summary = "Revogar convite")
    public ResponseEntity<InviteDTO> revokeInvite(@PathVariable Long id, @PathVariable Long inviteId) {
        return ResponseEntity.ok(inviteService.revokeInvite(id, inviteId));
    }

    private String reasonOf(ReasonRequest request) {
        return request != null ? request.getReason() : null;
    }
}
