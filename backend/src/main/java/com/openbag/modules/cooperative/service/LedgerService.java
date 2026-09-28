package com.openbag.modules.cooperative.service;

import com.openbag.enums.InvoiceLineType;
import com.openbag.enums.InvoiceStatus;
import com.openbag.enums.LedgerAccount;
import com.openbag.enums.LedgerCategory;
import com.openbag.enums.LedgerDirection;
import com.openbag.enums.ManualEntryKind;
import com.openbag.exception.BadRequestException;
import com.openbag.exception.ResourceNotFoundException;
import com.openbag.modules.cooperative.dto.FinanceSummaryDTO;
import com.openbag.modules.cooperative.dto.LedgerEntryDTO;
import com.openbag.modules.cooperative.dto.LedgerEntryRequest;
import com.openbag.modules.cooperative.dto.SolidarityFundDTO;
import com.openbag.modules.cooperative.entity.LedgerEntry;
import com.openbag.modules.cooperative.entity.MemberInvoice;
import com.openbag.modules.cooperative.entity.MemberInvoiceLine;
import com.openbag.modules.cooperative.repository.LedgerEntryRepository;
import com.openbag.modules.cooperative.repository.MemberInvoiceRepository;
import com.openbag.modules.organization.entity.AssociationMembership;
import com.openbag.modules.organization.entity.Organization;
import com.openbag.modules.organization.repository.AssociationMembershipRepository;
import com.openbag.modules.organization.service.AssociationService;
import com.openbag.modules.user.entity.User;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.text.NumberFormat;
import java.time.Clock;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.TreeMap;

/**
 * Livro-caixa da associação: lançamentos das faturas pagas e lançamentos manuais do gestor (despesas, outras
 * entradas, contribuições avulsas e auxílios da caixinha). Duas contas: o caixa geral e a caixinha solidária.
 */
@Service
@Transactional
public class LedgerService {

    private static final DateTimeFormatter MONTH = DateTimeFormatter.ofPattern("MM/yyyy");

    @Autowired
    private LedgerEntryRepository ledgerRepository;

    @Autowired
    private MemberInvoiceRepository invoiceRepository;

    @Autowired
    private AssociationMembershipRepository membershipRepository;

    @Autowired
    private AssociationService associationService;

    @Autowired
    private Clock clock;

    /**
     * Baixa da fatura: mensalidade e adicionais entram no caixa geral e a contribuição, na caixinha solidária
     */
    public void recordInvoicePayment(MemberInvoice invoice, User by) {
        AssociationMembership membership = invoice.getMembership();
        String who = membership.getDeliveryPerson().getUser().getFullName()
                + (membership.getMemberNumber() != null ? " (nº " + membership.getMemberNumber() + ")" : "");
        String month = invoice.getMonth().format(MONTH);
        for (MemberInvoiceLine line : invoice.getLines()) {
            if (line.getAmount().signum() <= 0) {
                continue;
            }
            LedgerEntry entry = new LedgerEntry();
            entry.setOrganization(invoice.getOrganization());
            entry.setAccount(line.getType() == InvoiceLineType.SOLIDARITY
                    ? LedgerAccount.SOLIDARITY_FUND : LedgerAccount.GENERAL);
            entry.setDirection(LedgerDirection.IN);
            entry.setCategory(switch (line.getType()) {
                case FEE -> LedgerCategory.MEMBERSHIP_FEE;
                case ADDON -> LedgerCategory.ADDON;
                case SOLIDARITY -> LedgerCategory.CONTRIBUTION;
            });
            entry.setAmount(line.getAmount());
            entry.setDate(invoice.getPaidOn());
            entry.setDescription(truncate(line.getDescription() + " " + month + " · " + who));
            entry.setMembership(membership);
            entry.setInvoice(invoice);
            entry.setCreatedBy(by);
            ledgerRepository.save(entry);
        }
    }

    /** Baixa desfeita: some com os lançamentos que ela criou */
    public void removeInvoiceEntries(MemberInvoice invoice) {
        ledgerRepository.deleteByInvoice(invoice.getId());
    }

    // ============= Gestor =============

    @Transactional(readOnly = true)
    public Page<LedgerEntryDTO> list(Long organizationId, LedgerAccount account, LocalDate from, LocalDate to,
                                     Pageable pageable) {
        associationService.findById(organizationId);
        Period period = Period.of(from, to, LocalDate.now(clock));
        return ledgerRepository.search(organizationId, account == null,
                        account != null ? account : LedgerAccount.GENERAL, period.from(), period.to(),
                        PageRequest.of(pageable.getPageNumber(), pageable.getPageSize(),
                                Sort.by(Sort.Direction.DESC, "date", "id")))
                .map(LedgerEntryDTO::from);
    }

    /** Lançamento manual. O auxílio não pode deixar a caixinha negativa. */
    public LedgerEntryDTO create(Long organizationId, LedgerEntryRequest request, User by) {
        Organization organization = associationService.findOperational(organizationId);
        ManualEntryKind kind = request.kind();
        LocalDate today = LocalDate.now(clock);
        LocalDate date = request.date() != null ? request.date() : today;
        if (date.isAfter(today)) {
            throw new BadRequestException("A data do lançamento não pode ser no futuro");
        }

        AssociationMembership membership = null;
        if (request.membershipId() != null) {
            membership = membershipRepository.findByIdAndOrganizationId(request.membershipId(), organizationId)
                    .orElseThrow(() -> new ResourceNotFoundException("Associado não encontrado"));
        } else if (kind == ManualEntryKind.AID) {
            throw new BadRequestException("Escolha o cooperado que recebe o auxílio");
        }
        if (kind.getDirection() == LedgerDirection.OUT) {
            BigDecimal balance = ledgerRepository.balance(organizationId, kind.getAccount());
            if (balance.compareTo(request.amount()) < 0) {
                throw new BadRequestException(String.format("Saldo insuficiente em %s (%s)",
                        kind.getAccount().getDisplayName().toLowerCase(), money(balance)));
            }
        }

        LedgerEntry entry = new LedgerEntry();
        entry.setOrganization(organization);
        entry.setAccount(kind.getAccount());
        entry.setDirection(kind.getDirection());
        entry.setCategory(kind.getCategory());
        entry.setAmount(request.amount().setScale(2, RoundingMode.HALF_UP));
        entry.setDate(date);
        entry.setDescription(truncate(request.description().trim()));
        entry.setMembership(membership);
        entry.setCreatedBy(by);
        return LedgerEntryDTO.from(ledgerRepository.save(entry));
    }

    /** Apaga um lançamento manual; os das faturas saem desfazendo a baixa */
    public void delete(Long organizationId, Long entryId) {
        LedgerEntry entry = ledgerRepository.findByIdAndOrganizationId(entryId, organizationId)
                .orElseThrow(() -> new ResourceNotFoundException("Lançamento não encontrado"));
        if (entry.getInvoice() != null) {
            throw new BadRequestException("Este lançamento veio de uma fatura: desfaça a baixa da fatura");
        }
        ledgerRepository.delete(entry);
    }

    /** Painel financeiro do período (padrão: os últimos 6 meses) */
    @Transactional(readOnly = true)
    public FinanceSummaryDTO summary(Long organizationId, LocalDate from, LocalDate to) {
        associationService.findById(organizationId);
        LocalDate today = LocalDate.now(clock);
        LocalDate end = to != null ? to : today;
        LocalDate start = from != null ? from : YearMonth.from(end).minusMonths(5).atDay(1);
        if (start.isAfter(end)) {
            throw new BadRequestException("O início do período deve ser antes do fim");
        }
        List<LedgerEntry> entries = ledgerRepository.findBetween(organizationId, start, end);

        Map<YearMonth, BigDecimal[]> byMonth = new TreeMap<>();
        for (YearMonth m = YearMonth.from(start); !m.isAfter(YearMonth.from(end)); m = m.plusMonths(1)) {
            byMonth.put(m, zeros());
        }
        BigDecimal[] totals = zeros();
        for (LedgerEntry e : entries) {
            BigDecimal[] month = byMonth.computeIfAbsent(YearMonth.from(e.getDate()), k -> zeros());
            int index = (e.getDirection() == LedgerDirection.IN ? 0 : 1)
                    + (e.getAccount() == LedgerAccount.SOLIDARITY_FUND ? 2 : 0);
            month[index] = month[index].add(e.getAmount());
            totals[index] = totals[index].add(e.getAmount());
        }

        return new FinanceSummaryDTO(start, end,
                totals[0].add(totals[2]),
                totals[1].add(totals[3]),
                invoiceRepository.sumByStatus(organizationId, InvoiceStatus.OPEN),
                invoiceRepository.sumOverdue(organizationId, today),
                ledgerRepository.balance(organizationId, LedgerAccount.GENERAL),
                ledgerRepository.balance(organizationId, LedgerAccount.SOLIDARITY_FUND),
                totals[2], totals[3],
                byMonth.entrySet().stream()
                        .map(m -> new FinanceSummaryDTO.Month(m.getKey().atDay(1), m.getValue()[0].add(m.getValue()[2]),
                                m.getValue()[1].add(m.getValue()[3]), m.getValue()[2], m.getValue()[3]))
                        .toList());
    }

    // ============= Cooperado =============

    /** A caixinha para o cooperado: saldo, entradas, saídas e as últimas movimentações, sem nomes */
    @Transactional(readOnly = true)
    public SolidarityFundDTO fundForMember(AssociationMembership membership) {
        Long organizationId = membership.getOrganization().getId();
        List<LedgerEntry> all = ledgerRepository.findRecent(organizationId, LedgerAccount.SOLIDARITY_FUND,
                Pageable.unpaged());
        BigDecimal in = sum(all, LedgerDirection.IN);
        BigDecimal out = sum(all, LedgerDirection.OUT);
        List<SolidarityFundDTO.Movement> recent = all.stream()
                .limit(RECENT_MOVEMENTS)
                .map(e -> new SolidarityFundDTO.Movement(e.getDate(), e.getDirection() == LedgerDirection.IN,
                        e.getAmount(), e.getDirection() == LedgerDirection.IN
                        ? "Contribuição" : "Auxílio a um cooperado"))
                .toList();
        return new SolidarityFundDTO(in.subtract(out), in, out,
                all.stream().filter(e -> e.getCategory() == LedgerCategory.AID).count(),
                ledgerRepository.contributedBy(membership.getId()), recent);
    }

    // ============= Auxiliares =============

    private static final int RECENT_MOVEMENTS = 10;

    private static BigDecimal sum(List<LedgerEntry> entries, LedgerDirection direction) {
        return entries.stream().filter(e -> e.getDirection() == direction).map(LedgerEntry::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private static BigDecimal[] zeros() {
        return new BigDecimal[]{BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO};
    }

    private static String money(BigDecimal value) {
        return NumberFormat.getCurrencyInstance(Locale.of("pt", "BR")).format(value);
    }

    /** Período das listagens: padrão do início do mês até hoje; no máximo 1 ano */
    record Period(LocalDate from, LocalDate to) {
        static Period of(LocalDate from, LocalDate to, LocalDate today) {
            LocalDate end = to != null ? to : today;
            LocalDate start = from != null ? from : end.withDayOfMonth(1);
            if (start.isAfter(end)) {
                throw new BadRequestException("O início do período deve ser antes do fim");
            }
            if (start.plusYears(1).isBefore(end)) {
                throw new BadRequestException("Escolha um período de até 1 ano");
            }
            return new Period(start, end);
        }
    }

    static String truncate(String text) {
        return text.length() <= 200 ? text : text.substring(0, 197) + "...";
    }
}
