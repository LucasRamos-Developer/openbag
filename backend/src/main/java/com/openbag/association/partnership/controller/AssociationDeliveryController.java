package com.openbag.association.partnership.controller;

import com.openbag.platform.security.annotation.IsAssociationManager;
import com.openbag.association.partnership.entity.PartnershipSide;
import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.association.partnership.dto.AssociationPartnershipDTO;
import com.openbag.association.partnership.dto.AssociationReportDTO;
import com.openbag.association.partnership.dto.InviteRestaurantRequest;
import com.openbag.association.partnership.dto.RateProposalRequest;
import com.openbag.association.partnership.entity.RestaurantPartnership;
import com.openbag.association.partnership.service.AssociationReportService;
import com.openbag.association.partnership.service.PartnershipService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

/**
 * Lado da associação nas entregas: parcerias com lojas, tabela especial (acordo) e relatórios dos cooperados
 */
@RestController
@RequestMapping("/associations/{id}")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Association Delivery", description = "Parcerias com lojas, acordos e relatórios da associação")
public class AssociationDeliveryController {

    private static final PartnershipSide SIDE = PartnershipSide.ASSOCIATION;

    @Autowired
    private PartnershipService partnershipService;

    @Autowired
    private AssociationReportService reportService;

    // ============= Parcerias =============

    @GetMapping("/partnerships")
    @IsAssociationManager
    @Operation(summary = "Parcerias da associação", description = "Pedidos pendentes, parcerias ativas e histórico")
    public ResponseEntity<List<AssociationPartnershipDTO>> listPartnerships(@PathVariable Long id) {
        return ResponseEntity.ok(partnershipService.listForAssociation(id).stream()
                .map(AssociationPartnershipDTO::from)
                .toList());
    }

    @PostMapping("/partnerships")
    @IsAssociationManager
    @Operation(summary = "Convidar uma loja para ser parceira",
            description = "Vale depois do aceite da loja (ou na hora, se a loja já tinha pedido). Pode já propor "
                    + "uma tabela especial; a loja aceita, recusa ou manda uma contraproposta")
    public ResponseEntity<AssociationPartnershipDTO> invite(@PathVariable Long id,
                                                            @Valid @RequestBody InviteRestaurantRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(dto(partnershipService.requestByAssociation(id, request.restaurantId(),
                        request.rate() != null ? request.rate().toEntity() : null)));
    }

    @PostMapping("/partnerships/{partnershipId}/{action:accept|decline|end|rate-accept|rate-decline|rate-cancel}")
    @IsAssociationManager
    @Operation(summary = "Responder ou encerrar uma parceria",
            description = "accept/decline: pedido de uma loja; end: encerrar ou cancelar o convite; "
                    + "rate-accept/rate-decline: proposta de tabela da loja; rate-cancel: desistir da própria")
    public ResponseEntity<AssociationPartnershipDTO> action(@PathVariable Long id, @PathVariable Long partnershipId,
                                                            @PathVariable String action) {
        RestaurantPartnership partnership = switch (action) {
            case "accept" -> partnershipService.accept(partnershipId, SIDE, id);
            case "decline" -> partnershipService.decline(partnershipId, SIDE, id);
            case "end" -> partnershipService.end(partnershipId, SIDE, id);
            case "rate-accept" -> partnershipService.acceptRate(partnershipId, SIDE, id);
            case "rate-decline" -> partnershipService.declineRate(partnershipId, SIDE, id);
            case "rate-cancel" -> partnershipService.cancelRate(partnershipId, SIDE, id);
            default -> throw new BadRequestException("Ação inválida");
        };
        return ResponseEntity.ok(dto(partnership));
    }

    @PostMapping("/partnerships/{partnershipId}/rate-proposal")
    @IsAssociationManager
    @Operation(summary = "Propor tabela especial à loja",
            description = "Vale só depois do aceite da loja. Sem tabela (ou toDefault) = voltar à tabela padrão")
    public ResponseEntity<AssociationPartnershipDTO> proposeRate(@PathVariable Long id,
                                                                 @PathVariable Long partnershipId,
                                                                 @Valid @RequestBody RateProposalRequest request) {
        return ResponseEntity.ok(dto(partnershipService.proposeRate(partnershipId, SIDE, id, request)));
    }

    // ============= Relatórios =============

    @GetMapping("/reports")
    @IsAssociationManager
    @Operation(summary = "Relatório da associação",
            description = "Entregas e ganhos dos cooperados no período (padrão: últimos 30 dias, até 92 dias), "
                    + "por dia, por cooperado e por loja")
    public ResponseEntity<AssociationReportDTO> report(
            @PathVariable Long id,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ResponseEntity.ok(reportService.forManager(id, from, to));
    }

    private static AssociationPartnershipDTO dto(RestaurantPartnership partnership) {
        return AssociationPartnershipDTO.from(partnership);
    }
}
