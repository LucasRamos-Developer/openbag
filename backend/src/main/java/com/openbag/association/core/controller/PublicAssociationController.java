package com.openbag.association.core.controller;

import com.openbag.association.core.dto.AssociationSummaryDTO;
import com.openbag.association.core.service.AssociationService;
import com.openbag.association.core.service.InviteService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/public/associations")
@Tag(name = "Public Associations", description = "Consultas públicas de associações/cooperativas")
public class PublicAssociationController {

    @Autowired
    private AssociationService associationService;

    @Autowired
    private InviteService inviteService;

    @GetMapping
    @Operation(summary = "Listar associações ativas", description = "Associações aprovadas que aceitam novos associados")
    public ResponseEntity<List<AssociationSummaryDTO>> listActive() {
        return ResponseEntity.ok(associationService.listActiveAssociations());
    }

    @GetMapping("/invites/{code}")
    @Operation(summary = "Validar código de convite", description = "Retorna a associação do convite, se ele ainda for válido")
    public ResponseEntity<AssociationSummaryDTO> validateInvite(@PathVariable String code) {
        return ResponseEntity.ok(inviteService.validateInvite(code));
    }
}
