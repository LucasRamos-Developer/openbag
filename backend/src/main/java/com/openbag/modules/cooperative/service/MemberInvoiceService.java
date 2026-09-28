package com.openbag.modules.cooperative.service;

import com.openbag.enums.InvoiceStatus;
import com.openbag.enums.MembershipFeeMode;
import com.openbag.enums.MembershipStatus;
import com.openbag.enums.OrganizationStatus;
import com.openbag.exception.BadRequestException;
import com.openbag.exception.ResourceNotFoundException;
import com.openbag.modules.cooperative.dto.FeePolicyDTO;
import com.openbag.modules.cooperative.dto.InvoiceDTO;
import com.openbag.modules.cooperative.dto.InvoiceMonthDTO;
import com.openbag.modules.cooperative.dto.PayInvoiceRequest;
import com.openbag.modules.cooperative.entity.AddonPlan;
import com.openbag.modules.cooperative.entity.MemberInvoice;
import com.openbag.modules.cooperative.entity.MemberInvoiceLine;
import com.openbag.modules.cooperative.repository.MemberInvoiceRepository;
import com.openbag.modules.order.repository.OrderRepository;
import com.openbag.modules.organization.entity.AssociationMembership;
import com.openbag.modules.organization.entity.MembershipFeePolicy;
import com.openbag.modules.organization.entity.Organization;
import com.openbag.modules.organization.repository.AssociationMembershipRepository;
import com.openbag.modules.organization.repository.OrganizationRepository;
import com.openbag.modules.organization.service.AssociationService;
import com.openbag.modules.user.entity.User;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Clock;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Predicate;

/**
 * Cobrança dos cooperados: a política (fixa ou percentual com teto), as faturas mensais e a baixa manual.
 *
 * O mês em andamento aparece como prévia (calculada na hora). No dia 1 as faturas do mês anterior são geradas
 * sozinhas; o gestor também pode gerar as que faltam. Cada fatura tem a mensalidade, os adicionais ativos e a
 * contribuição do cooperado para a caixinha. O entregador continua recebendo 100% de cada entrega: a mensalidade
 * é cobrada à parte.
 */
@Service
@Transactional
@Slf4j
public class MemberInvoiceService {

    /** Quem entra na fatura do mês: os cooperados ativos ou suspensos e quem fez entregas no mês */
    private static final Set<MembershipStatus> BILLED = EnumSet.of(MembershipStatus.ACTIVE, MembershipStatus.SUSPENDED);

    @Autowired
    private MemberInvoiceRepository invoiceRepository;

    @Autowired
    private AssociationMembershipRepository membershipRepository;

    @Autowired
    private OrganizationRepository organizationRepository;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private AssociationService associationService;

    @Autowired
    private AddonService addonService;

    @Autowired
    private LedgerService ledgerService;

    @Autowired
    private MemberContext memberContext;

    @Autowired
    private Clock clock;

    // ============= Política =============

    @Transactional(readOnly = true)
    public FeePolicyDTO getPolicy(Long organizationId) {
        return FeePolicyDTO.from(associationService.findById(organizationId).getFeePolicy());
    }

    public FeePolicyDTO updatePolicy(Long organizationId, FeePolicyDTO request) {
        Organization organization = associationService.findOperational(organizationId);
        MembershipFeePolicy policy = request.toEntity();
        if (!policy.isConfigured()) {
            throw new BadRequestException(request.mode() == MembershipFeeMode.FIXED
                    ? "Informe o valor da mensalidade"
                    : "Informe o percentual dos ganhos");
        }
        organization.setFeePolicy(policy);
        organizationRepository.save(organization);
        log.info("Associação {} mudou a cobrança: {}", organizationId, policy);
        return FeePolicyDTO.from(policy);
    }

    // ============= Faturas (gestor) =============

    /** Faturas do mês; o mês em andamento (ou futuro) é prévia */
    @Transactional(readOnly = true)
    public InvoiceMonthDTO listMonth(Long organizationId, YearMonth month) {
        Organization organization = associationService.findById(organizationId);
        YearMonth target = month != null ? month : YearMonth.now(clock);
        LocalDate today = LocalDate.now(clock);

        if (!target.isBefore(YearMonth.now(clock))) {
            List<InvoiceDTO> preview = drafts(organization, target).stream()
                    .map(InvoiceDTO::preview)
                    .sorted(byMember())
                    .toList();
            return new InvoiceMonthDTO(target.atDay(1), true, 0, preview, totals(preview));
        }

        List<InvoiceDTO> invoices = invoiceRepository.findByOrganizationAndMonth(organizationId, target.atDay(1)).stream()
                .map(invoice -> InvoiceDTO.from(invoice, today))
                .sorted(byMember())
                .toList();
        int missing = (int) drafts(organization, target).stream()
                .filter(d -> d.getTotal().signum() > 0)
                .filter(d -> invoices.stream().noneMatch(i -> i.membershipId().equals(d.getMembership().getId())))
                .count();
        return new InvoiceMonthDTO(target.atDay(1), false, missing, invoices, totals(invoices));
    }

    /**
     * Gera as faturas que faltam de um mês já fechado (pode ser chamado de novo sem duplicar). Devolve o mês.
     */
    public InvoiceMonthDTO generate(Long organizationId, YearMonth month) {
        Organization organization = associationService.findOperational(organizationId);
        if (!organization.isFeePolicyConfigured()) {
            throw new BadRequestException("Defina como cobrar a mensalidade antes de gerar as faturas");
        }
        YearMonth target = month != null ? month : YearMonth.now(clock).minusMonths(1);
        if (!target.isBefore(YearMonth.now(clock))) {
            throw new BadRequestException("As faturas de um mês são geradas depois que ele termina");
        }
        int created = generateMissing(organization, target);
        log.info("Associação {}: {} fatura(s) de {} gerada(s)", organizationId, created, target);
        return listMonth(organizationId, target);
    }

    public InvoiceDTO pay(Long organizationId, Long invoiceId, PayInvoiceRequest request, User by) {
        MemberInvoice invoice = findInvoice(organizationId, invoiceId);
        if (invoice.getStatus() != InvoiceStatus.OPEN) {
            throw new BadRequestException("Esta fatura não está em aberto");
        }
        LocalDate today = LocalDate.now(clock);
        LocalDate paidOn = request.paidOn() != null ? request.paidOn() : today;
        if (paidOn.isAfter(today)) {
            throw new BadRequestException("A data do pagamento não pode ser no futuro");
        }
        invoice.setStatus(InvoiceStatus.PAID);
        invoice.setPaidOn(paidOn);
        invoice.setPaymentMethod(request.method());
        invoice.setRegisteredBy(by);
        invoice.setNotes(blankToNull(request.notes()));
        ledgerService.recordInvoicePayment(invoice, by);
        return InvoiceDTO.from(invoiceRepository.save(invoice), today);
    }

    /** Dispensa a fatura (ex: cooperado afastado), com o motivo */
    public InvoiceDTO waive(Long organizationId, Long invoiceId, String reason, User by) {
        MemberInvoice invoice = findInvoice(organizationId, invoiceId);
        if (invoice.getStatus() != InvoiceStatus.OPEN) {
            throw new BadRequestException("Esta fatura não está em aberto");
        }
        invoice.setStatus(InvoiceStatus.WAIVED);
        invoice.setRegisteredBy(by);
        invoice.setNotes(blankToNull(reason));
        return InvoiceDTO.from(invoiceRepository.save(invoice), LocalDate.now(clock));
    }

    /** Desfaz a baixa ou a dispensa (lançamento errado): a fatura volta a ficar em aberto */
    public InvoiceDTO reopen(Long organizationId, Long invoiceId) {
        MemberInvoice invoice = findInvoice(organizationId, invoiceId);
        if (invoice.getStatus() == InvoiceStatus.OPEN) {
            throw new BadRequestException("Esta fatura já está em aberto");
        }
        if (invoice.getStatus() == InvoiceStatus.PAID) {
            ledgerService.removeInvoiceEntries(invoice);
        }
        invoice.setStatus(InvoiceStatus.OPEN);
        invoice.setPaidOn(null);
        invoice.setPaymentMethod(null);
        invoice.setRegisteredBy(null);
        return InvoiceDTO.from(invoiceRepository.save(invoice), LocalDate.now(clock));
    }

    /** Faturas em aberto por cooperado: [quantidade, total] (lista de associados e exportação) */
    @Transactional(readOnly = true)
    public Map<Long, OpenBalance> openByMembership(Long organizationId) {
        Map<Long, OpenBalance> result = new HashMap<>();
        for (Object[] row : invoiceRepository.openByMembership(organizationId)) {
            result.put((Long) row[0], new OpenBalance(((Number) row[1]).intValue(), (BigDecimal) row[2]));
        }
        return result;
    }

    public record OpenBalance(int invoices, BigDecimal total) {
    }

    // ============= Cooperado =============

    /** Prévia do mês em andamento e o histórico de faturas do cooperado logado */
    @Transactional(readOnly = true)
    public MyInvoices mine(User user) {
        AssociationMembership membership = memberContext.current(user);
        Organization organization = membership.getOrganization();
        LocalDate today = LocalDate.now(clock);
        InvoiceDTO current = drafts(organization, YearMonth.now(clock)).stream()
                .filter(d -> d.getMembership().getId().equals(membership.getId()))
                .findFirst()
                .map(InvoiceDTO::preview)
                .orElse(null);
        List<InvoiceDTO> history = invoiceRepository.findByMembership(membership.getId()).stream()
                .map(invoice -> InvoiceDTO.from(invoice, today))
                .toList();
        return new MyInvoices(FeePolicyDTO.from(organization.getFeePolicy()), current, history,
                membership.getSolidarityContribution());
    }

    public record MyInvoices(FeePolicyDTO policy, InvoiceDTO current, List<InvoiceDTO> history,
                             BigDecimal solidarityContribution) {
    }

    /** O cooperado escolhe quanto dar por mês à caixinha (zero = nada); vale a partir da próxima fatura */
    public BigDecimal setSolidarityContribution(User user, BigDecimal amount) {
        if (amount != null && amount.signum() < 0) {
            throw new BadRequestException("O valor não pode ser negativo");
        }
        AssociationMembership membership = memberContext.current(user);
        membership.setSolidarityContribution(amount != null && amount.signum() > 0 ? amount : null);
        membershipRepository.save(membership);
        return membership.getSolidarityContribution();
    }

    // ============= Geração automática =============

    /** Dia 1, de madrugada: gera as faturas do mês que terminou em todas as associações com cobrança definida */
    @Scheduled(cron = "${app.cooperative.invoice-cron:0 0 3 1 * *}", zone = "America/Sao_Paulo")
    public void generatePreviousMonthForAll() {
        YearMonth previous = YearMonth.now(clock).minusMonths(1);
        for (Organization organization : organizationRepository.findByStatusOrderByTradingNameAsc(OrganizationStatus.ACTIVE)) {
            if (organization.isFeePolicyConfigured()) {
                int created = generateMissing(organization, previous);
                if (created > 0) {
                    log.info("Associação {}: {} fatura(s) de {} geradas automaticamente", organization.getId(),
                            created, previous);
                }
            }
        }
    }

    // ============= Auxiliares =============

    private int generateMissing(Organization organization, YearMonth month) {
        int created = 0;
        for (MemberInvoice draft : drafts(organization, month)) {
            // Fatura zerada (percentual sem ganhos e sem adicionais) não é gerada
            if (draft.getTotal().signum() > 0 && !invoiceRepository.existsByMembershipIdAndMonth(draft.getMembership().getId(), draft.getMonth())) {
                invoiceRepository.save(draft);
                created++;
            }
        }
        return created;
    }

    /** Faturas do mês calculadas (sem gravar): uma por cooperado cobrado */
    List<MemberInvoice> drafts(Organization organization, YearMonth month) {
        Long organizationId = organization.getId();
        Map<Long, Integer> deliveriesByCourier = new HashMap<>();
        Map<Long, BigDecimal> earningsByCourier = new HashMap<>();
        for (Object[] row : orderRepository.sumCourierEarningsByCourier(organizationId,
                month.atDay(1).atStartOfDay(), month.plusMonths(1).atDay(1).atStartOfDay())) {
            Long courierId = (Long) row[0];
            earningsByCourier.put(courierId, (BigDecimal) row[1]);
            deliveriesByCourier.put(courierId, ((Number) row[2]).intValue());
        }

        // Um vínculo por entregador: o aberto, ou o mais recente se ele saiu e fez entregas no mês.
        // Quem entrou depois do mês não paga por ele.
        LocalDateTime monthEnd = month.plusMonths(1).atDay(1).atStartOfDay();
        Map<Long, AssociationMembership> byCourier = new LinkedHashMap<>();
        membershipRepository.findByOrganizationId(organizationId).stream()
                .filter(m -> m.getRequestedAt() == null || m.getRequestedAt().isBefore(monthEnd))
                .filter(m -> BILLED.contains(m.getStatus()) || earningsByCourier.containsKey(m.getDeliveryPerson().getId()))
                .sorted(Comparator.comparing((AssociationMembership m) -> BILLED.contains(m.getStatus()))
                        .thenComparing(AssociationMembership::getRequestedAt,
                                Comparator.nullsFirst(Comparator.naturalOrder())))
                .forEach(m -> byCourier.put(m.getDeliveryPerson().getId(), m));

        Map<Long, List<AddonPlan>> addons = addonService.activeByMembership(organizationId);
        MembershipFeePolicy policy = organization.getFeePolicy();
        LocalDate dueDate = dueDate(month, policy);

        List<MemberInvoice> drafts = new ArrayList<>();
        for (AssociationMembership membership : byCourier.values()) {
            Long courierId = membership.getDeliveryPerson().getId();
            BigDecimal earnings = earningsByCourier.getOrDefault(courierId, BigDecimal.ZERO);
            List<MemberInvoiceLine> lines = MembershipFeeCalculator.lines(policy, earnings,
                    BILLED.contains(membership.getStatus()) ? addons.getOrDefault(membership.getId(), List.of()) : List.of(),
                    BILLED.contains(membership.getStatus()) ? membership.getSolidarityContribution() : null);

            MemberInvoice invoice = new MemberInvoice();
            invoice.setOrganization(organization);
            invoice.setMembership(membership);
            invoice.setMonth(month.atDay(1));
            invoice.setEarnings(earnings.setScale(2, RoundingMode.HALF_UP));
            invoice.setDeliveries(deliveriesByCourier.getOrDefault(courierId, 0));
            invoice.setStatus(InvoiceStatus.OPEN);
            invoice.setDueDate(dueDate);
            lines.forEach(invoice::addLine);
            invoice.setTotal(MembershipFeeCalculator.total(lines));
            drafts.add(invoice);
        }
        return drafts;
    }

    /** Vence no dia escolhido do mês seguinte ao de referência */
    static LocalDate dueDate(YearMonth month, MembershipFeePolicy policy) {
        YearMonth next = month.plusMonths(1);
        int day = policy != null ? policy.getDueDayOrDefault() : MembershipFeePolicy.DEFAULT_DUE_DAY;
        return next.atDay(Math.min(day, next.lengthOfMonth()));
    }

    private static InvoiceMonthDTO.Totals totals(List<InvoiceDTO> invoices) {
        return new InvoiceMonthDTO.Totals(invoices.size(),
                sum(invoices, i -> true),
                sum(invoices, i -> i.status() == InvoiceStatus.PAID),
                sum(invoices, i -> i.status() == InvoiceStatus.OPEN),
                sum(invoices, InvoiceDTO::overdue),
                sum(invoices, i -> i.status() == InvoiceStatus.WAIVED));
    }

    private static BigDecimal sum(List<InvoiceDTO> invoices, Predicate<InvoiceDTO> filter) {
        return invoices.stream().filter(filter).map(InvoiceDTO::total).reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private static Comparator<InvoiceDTO> byMember() {
        return Comparator.comparing(InvoiceDTO::memberNumber, Comparator.nullsLast(Comparator.naturalOrder()))
                .thenComparing(InvoiceDTO::memberName);
    }

    private MemberInvoice findInvoice(Long organizationId, Long invoiceId) {
        return invoiceRepository.findByIdAndOrganization(invoiceId, organizationId)
                .orElseThrow(() -> new ResourceNotFoundException("Fatura não encontrada"));
    }

    private static String blankToNull(String text) {
        return text != null && !text.isBlank() ? text.trim() : null;
    }
}
