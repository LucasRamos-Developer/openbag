package com.openbag.modules.cooperative.controller;

import com.openbag.annotation.IsAssociationManager;
import com.openbag.enums.LedgerAccount;
import com.openbag.modules.cooperative.dto.*;
import com.openbag.modules.cooperative.service.AddonService;
import com.openbag.modules.cooperative.service.LedgerService;
import com.openbag.modules.cooperative.service.MemberInvoiceService;
import com.openbag.modules.organization.dto.ReasonRequest;
import com.openbag.modules.user.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.YearMonth;
import java.util.List;
import java.util.Map;

/**
 * Financeiro da associação: cobrança dos cooperados (política, adicionais e faturas), livro-caixa, caixinha
 * solidária e painel financeiro
 */
@RestController
@RequestMapping("/associations/{id}")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Association Finance", description = "Mensalidades, adicionais, faturas, livro-caixa e caixinha solidária")
public class AssociationFinanceController {

    @Autowired
    private MemberInvoiceService invoiceService;

    @Autowired
    private AddonService addonService;

    @Autowired
    private LedgerService ledgerService;

    @Autowired
    private UserService userService;

    // ============= Cobrança =============

    @GetMapping("/fee-policy")
    @IsAssociationManager
    @Operation(summary = "Como a mensalidade é cobrada")
    public ResponseEntity<FeePolicyDTO> getFeePolicy(@PathVariable Long id) {
        return ResponseEntity.ok(invoiceService.getPolicy(id));
    }

    @PutMapping("/fee-policy")
    @IsAssociationManager
    @Operation(summary = "Definir a cobrança da mensalidade",
            description = "Valor fixo ou percentual dos ganhos até o teto (depois do teto só os adicionais)")
    public ResponseEntity<FeePolicyDTO> updateFeePolicy(@PathVariable Long id, @Valid @RequestBody FeePolicyDTO request) {
        return ResponseEntity.ok(invoiceService.updatePolicy(id, request));
    }

    // ============= Adicionais =============

    @GetMapping("/addon-plans")
    @IsAssociationManager
    @Operation(summary = "Adicionais oferecidos (ex: seguro de vida)")
    public ResponseEntity<List<AddonPlanDTO>> listAddonPlans(@PathVariable Long id) {
        return ResponseEntity.ok(addonService.listPlans(id));
    }

    @PostMapping("/addon-plans")
    @IsAssociationManager
    @Operation(summary = "Cadastrar adicional")
    public ResponseEntity<AddonPlanDTO> createAddonPlan(@PathVariable Long id,
                                                        @Valid @RequestBody AddonPlanRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(addonService.createPlan(id, request));
    }

    @PutMapping("/addon-plans/{planId}")
    @IsAssociationManager
    @Operation(summary = "Alterar adicional", description = "Desativar para de oferecer; quem já tem continua")
    public ResponseEntity<AddonPlanDTO> updateAddonPlan(@PathVariable Long id, @PathVariable Long planId,
                                                        @Valid @RequestBody AddonPlanRequest request) {
        return ResponseEntity.ok(addonService.updatePlan(id, planId, request));
    }

    @PostMapping("/addon-plans/{planId}/propose")
    @IsAssociationManager
    @Operation(summary = "Propor o adicional aos cooperados",
            description = "Aos escolhidos ou, sem lista, a todos os ativos. Cada um aceita ou recusa no painel dele.")
    public ResponseEntity<Map<String, Integer>> proposeAddon(@PathVariable Long id, @PathVariable Long planId,
                                                             @RequestBody(required = false) ProposeAddonRequest request) {
        int proposed = addonService.propose(id, planId, request != null ? request.membershipIds() : null);
        return ResponseEntity.ok(Map.of("proposed", proposed));
    }

    @GetMapping("/members/{membershipId}/addons")
    @IsAssociationManager
    @Operation(summary = "Adicionais de um cooperado")
    public ResponseEntity<List<MemberAddonDTO>> memberAddons(@PathVariable Long id, @PathVariable Long membershipId) {
        return ResponseEntity.ok(addonService.listForMember(id, membershipId));
    }

    @PostMapping("/member-addons/{memberAddonId}/cancel")
    @IsAssociationManager
    @Operation(summary = "Cancelar o adicional de um cooperado")
    public ResponseEntity<MemberAddonDTO> cancelMemberAddon(@PathVariable Long id, @PathVariable Long memberAddonId) {
        return ResponseEntity.ok(addonService.cancelByAssociation(id, memberAddonId));
    }

    // ============= Faturas =============

    @GetMapping("/invoices")
    @IsAssociationManager
    @Operation(summary = "Faturas do mês", description = "O mês em andamento vem como prévia, calculada na hora")
    public ResponseEntity<InvoiceMonthDTO> listInvoices(@PathVariable Long id,
            @RequestParam(required = false) @DateTimeFormat(pattern = "yyyy-MM") YearMonth month) {
        return ResponseEntity.ok(invoiceService.listMonth(id, month));
    }

    @PostMapping("/invoices/generate")
    @IsAssociationManager
    @Operation(summary = "Gerar as faturas que faltam de um mês fechado",
            description = "Sem mês, o anterior. Pode ser chamado de novo sem duplicar.")
    public ResponseEntity<InvoiceMonthDTO> generateInvoices(@PathVariable Long id,
            @RequestParam(required = false) @DateTimeFormat(pattern = "yyyy-MM") YearMonth month) {
        return ResponseEntity.ok(invoiceService.generate(id, month));
    }

    @PostMapping("/invoices/{invoiceId}/pay")
    @IsAssociationManager
    @Operation(summary = "Dar baixa na fatura", description = "Registra o pagamento e lança no livro-caixa")
    public ResponseEntity<InvoiceDTO> payInvoice(@PathVariable Long id, @PathVariable Long invoiceId,
                                                 @Valid @RequestBody PayInvoiceRequest request) {
        return ResponseEntity.ok(invoiceService.pay(id, invoiceId, request, userService.getCurrentUser()));
    }

    @PostMapping("/invoices/{invoiceId}/waive")
    @IsAssociationManager
    @Operation(summary = "Dispensar a fatura")
    public ResponseEntity<InvoiceDTO> waiveInvoice(@PathVariable Long id, @PathVariable Long invoiceId,
                                                   @Valid @RequestBody(required = false) ReasonRequest request) {
        return ResponseEntity.ok(invoiceService.waive(id, invoiceId, request != null ? request.getReason() : null,
                userService.getCurrentUser()));
    }

    @PostMapping("/invoices/{invoiceId}/reopen")
    @IsAssociationManager
    @Operation(summary = "Desfazer a baixa ou a dispensa", description = "Os lançamentos da baixa saem do livro-caixa")
    public ResponseEntity<InvoiceDTO> reopenInvoice(@PathVariable Long id, @PathVariable Long invoiceId) {
        return ResponseEntity.ok(invoiceService.reopen(id, invoiceId));
    }

    // ============= Livro-caixa =============

    @GetMapping("/finance/summary")
    @IsAssociationManager
    @Operation(summary = "Painel financeiro",
            description = "Arrecadado, gasto, a receber e saldos no período (padrão: últimos 6 meses)")
    public ResponseEntity<FinanceSummaryDTO> financeSummary(@PathVariable Long id,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ResponseEntity.ok(ledgerService.summary(id, from, to));
    }

    @GetMapping("/ledger")
    @IsAssociationManager
    @Operation(summary = "Lançamentos do livro-caixa", description = "Filtro por conta e período (padrão: mês atual)")
    public ResponseEntity<Page<LedgerEntryDTO>> ledger(@PathVariable Long id,
            @RequestParam(required = false) LedgerAccount account,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @PageableDefault(size = 30) Pageable pageable) {
        return ResponseEntity.ok(ledgerService.list(id, account, from, to, pageable));
    }

    @PostMapping("/ledger")
    @IsAssociationManager
    @Operation(summary = "Lançamento manual",
            description = "Despesa, outra entrada, contribuição avulsa para a caixinha ou auxílio a um cooperado")
    public ResponseEntity<LedgerEntryDTO> createLedgerEntry(@PathVariable Long id,
                                                            @Valid @RequestBody LedgerEntryRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ledgerService.create(id, request, userService.getCurrentUser()));
    }

    @DeleteMapping("/ledger/{entryId}")
    @IsAssociationManager
    @Operation(summary = "Apagar lançamento manual")
    public ResponseEntity<Void> deleteLedgerEntry(@PathVariable Long id, @PathVariable Long entryId) {
        ledgerService.delete(id, entryId);
        return ResponseEntity.noContent().build();
    }
}
