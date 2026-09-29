package com.openbag.association.member.controller;

import com.openbag.association.partnership.dto.AssociationReportDTO;
import com.openbag.association.partnership.service.AssociationReportService;
import com.openbag.association.core.dto.JoinAssociationRequest;
import com.openbag.association.core.dto.MemberDTO;
import com.openbag.association.core.dto.ReasonRequest;
import com.openbag.association.core.service.MembershipService;
import com.openbag.account.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@RequestMapping("/me/association")
@SecurityRequirement(name = "bearerAuth")
@PreAuthorize("hasRole('DELIVERY_PERSON')")
@Tag(name = "Delivery Person Membership", description = "Vínculo do entregador logado com sua associação")
public class DeliveryPersonMembershipController {

    @Autowired
    private MembershipService membershipService;

    @Autowired
    private UserService userService;

    @Autowired
    private AssociationReportService reportService;

    @GetMapping
    @Operation(summary = "Meu vínculo atual", description = "Retorna 204 se o entregador não tiver vínculo ativo ou pendente")
    public ResponseEntity<MemberDTO> getMyMembership() {
        return membershipService.getMyMembership(userService.getCurrentUser())
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.noContent().build());
    }

    @PostMapping("/request")
    @Operation(summary = "Solicitar entrada em uma associação",
            description = "Com código de convite entra ativo; informando só a associação, fica aguardando aprovação")
    public ResponseEntity<MemberDTO> requestToJoin(@RequestBody JoinAssociationRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(membershipService.requestToJoin(userService.getCurrentUser(), request));
    }

    @GetMapping("/report")
    @Operation(summary = "Resumo da minha associação",
            description = "Entregas e ganhos da associação no período, por loja, e a minha parte. "
                    + "Não mostra os ganhos dos outros cooperados")
    public ResponseEntity<AssociationReportDTO> report(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ResponseEntity.ok(reportService.forMember(userService.getCurrentUser(), from, to));
    }

    @PostMapping("/leave")
    @Operation(summary = "Sair da associação (ou cancelar solicitação pendente)")
    public ResponseEntity<MemberDTO> leave(@Valid @RequestBody(required = false) ReasonRequest request) {
        String reason = request != null ? request.getReason() : null;
        return ResponseEntity.ok(membershipService.leave(userService.getCurrentUser(), reason));
    }
}
