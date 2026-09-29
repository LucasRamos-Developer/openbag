package com.openbag.association.member.controller;

import com.openbag.association.community.dto.AssociationDocumentDTO;
import com.openbag.association.community.dto.BenefitDTO;
import com.openbag.association.finance.dto.MemberAddonDTO;
import com.openbag.association.community.dto.PollDTO;
import com.openbag.association.finance.dto.SolidarityFundDTO;
import com.openbag.association.finance.service.AddonService;
import com.openbag.association.community.service.AssociationDocumentService;
import com.openbag.association.community.service.BenefitService;
import com.openbag.association.community.service.PollService;
import com.openbag.association.finance.service.LedgerService;
import com.openbag.association.member.service.MemberContext;
import com.openbag.association.finance.service.MemberInvoiceService;
import com.openbag.account.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import com.openbag.association.community.controller.AssociationCommunityController;

/**
 * O que a associação deixa disponível para o cooperado: faturas, adicionais, caixinha solidária, convênios,
 * enquetes e documentos (atas)
 */
@RestController
@RequestMapping("/me/association")
@PreAuthorize("hasRole('DELIVERY_PERSON')")
@SecurityRequirement(name = "bearerAuth")
@Validated
@Tag(name = "Member Area", description = "Área do cooperado: faturas, adicionais e caixinha")
public class MemberCooperativeController {

    @Autowired
    private MemberInvoiceService invoiceService;

    @Autowired
    private AddonService addonService;

    @Autowired
    private LedgerService ledgerService;

    @Autowired
    private MemberContext memberContext;

    @Autowired
    private BenefitService benefitService;

    @Autowired
    private PollService pollService;

    @Autowired
    private AssociationDocumentService documentService;

    @Autowired
    private UserService userService;

    @GetMapping("/invoices")
    @Operation(summary = "Minhas faturas", description = "Prévia do mês em andamento e o histórico")
    public ResponseEntity<MemberInvoiceService.MyInvoices> myInvoices() {
        return ResponseEntity.ok(invoiceService.mine(userService.getCurrentUser()));
    }

    @GetMapping("/addons")
    @Operation(summary = "Meus adicionais", description = "Propostos pela associação, ativos e encerrados")
    public ResponseEntity<List<MemberAddonDTO>> myAddons() {
        return ResponseEntity.ok(addonService.mine(userService.getCurrentUser()));
    }

    @PostMapping("/addons/{memberAddonId}/{action:accept|decline|cancel}")
    @Operation(summary = "Aceitar, recusar ou cancelar um adicional")
    public ResponseEntity<MemberAddonDTO> answerAddon(@PathVariable Long memberAddonId, @PathVariable String action) {
        return ResponseEntity.ok(addonService.answer(userService.getCurrentUser(), memberAddonId, action));
    }

    @GetMapping("/solidarity-fund")
    @Operation(summary = "Caixinha solidária", description = "Saldo, entradas e saídas (auxílios sem nomes)")
    public ResponseEntity<SolidarityFundDTO> solidarityFund() {
        return ResponseEntity.ok(ledgerService.fundForMember(memberContext.current(userService.getCurrentUser())));
    }

    @PutMapping("/solidarity-contribution")
    @Operation(summary = "Minha contribuição mensal para a caixinha", description = "Entra na próxima fatura; zero = nada")
    public ResponseEntity<Map<String, BigDecimal>> setContribution(@Valid @RequestBody ContributionRequest request) {
        BigDecimal amount = invoiceService.setSolidarityContribution(userService.getCurrentUser(), request.amount());
        return ResponseEntity.ok(Map.of("amount", amount != null ? amount : BigDecimal.ZERO));
    }

    // ============= Convênios, enquetes e documentos =============

    @GetMapping("/benefits")
    @Operation(summary = "Convênios disponíveis", description = "Oficinas, idiomas, descontos e outros parceiros")
    public ResponseEntity<List<BenefitDTO>> benefits() {
        return ResponseEntity.ok(benefitService.forMember(userService.getCurrentUser()));
    }

    @GetMapping("/polls")
    @Operation(summary = "Enquetes", description = "O resultado aparece depois de votar ou quando encerra")
    public ResponseEntity<List<PollDTO>> polls() {
        return ResponseEntity.ok(pollService.forMember(userService.getCurrentUser()));
    }

    @PostMapping("/polls/{pollId}/vote")
    @Operation(summary = "Votar", description = "Uma vez por enquete; o voto é secreto")
    public ResponseEntity<PollDTO> vote(@PathVariable Long pollId, @Valid @RequestBody VoteRequest request) {
        return ResponseEntity.ok(pollService.vote(userService.getCurrentUser(), pollId, request.optionId()));
    }

    @GetMapping("/documents")
    @Operation(summary = "Atas e documentos da associação")
    public ResponseEntity<List<AssociationDocumentDTO>> documents() {
        return ResponseEntity.ok(documentService.forMember(userService.getCurrentUser()));
    }

    @GetMapping("/documents/{documentId}/file")
    @Operation(summary = "Baixar documento")
    public ResponseEntity<byte[]> downloadDocument(@PathVariable Long documentId) {
        return AssociationCommunityController.pdf(documentService.fileForMember(userService.getCurrentUser(), documentId));
    }

    public record VoteRequest(@NotNull(message = "Escolha uma opção") Long optionId) {
    }

    public record ContributionRequest(@DecimalMin(value = "0.00", message = "O valor não pode ser negativo")
                                      BigDecimal amount) {
    }
}
