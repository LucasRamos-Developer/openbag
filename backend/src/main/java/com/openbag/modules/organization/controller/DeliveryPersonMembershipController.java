package com.openbag.modules.organization.controller;

import com.openbag.modules.organization.dto.JoinAssociationRequest;
import com.openbag.modules.organization.dto.MemberDTO;
import com.openbag.modules.organization.dto.ReasonRequest;
import com.openbag.modules.organization.service.MembershipService;
import com.openbag.modules.user.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

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

    @PostMapping("/leave")
    @Operation(summary = "Sair da associação (ou cancelar solicitação pendente)")
    public ResponseEntity<MemberDTO> leave(@Valid @RequestBody(required = false) ReasonRequest request) {
        String reason = request != null ? request.getReason() : null;
        return ResponseEntity.ok(membershipService.leave(userService.getCurrentUser(), reason));
    }
}
