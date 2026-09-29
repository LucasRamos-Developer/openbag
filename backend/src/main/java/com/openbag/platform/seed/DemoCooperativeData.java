package com.openbag.platform.seed;

import com.openbag.enums.AddonPricing;
import com.openbag.enums.AssociationDocumentType;
import com.openbag.enums.BenefitCategory;
import com.openbag.enums.DeliveryFeeMode;
import com.openbag.enums.InvoiceStatus;
import com.openbag.enums.ManualEntryKind;
import com.openbag.enums.MemberAddonStatus;
import com.openbag.enums.MemberPaymentMethod;
import com.openbag.enums.MembershipFeeMode;
import com.openbag.enums.PollStatus;
import com.openbag.enums.VehicleType;
import com.openbag.association.finance.dto.AddonPlanRequest;
import com.openbag.association.community.dto.BenefitRequest;
import com.openbag.association.finance.dto.LedgerEntryRequest;
import com.openbag.association.finance.entity.AddonPlan;
import com.openbag.association.community.entity.AssociationDocument;
import com.openbag.association.finance.entity.MemberAddon;
import com.openbag.association.finance.entity.MemberInvoice;
import com.openbag.association.finance.entity.MemberInvoiceLine;
import com.openbag.association.community.entity.Poll;
import com.openbag.association.community.entity.PollOption;
import com.openbag.association.community.entity.PollVote;
import com.openbag.association.finance.repository.AddonPlanRepository;
import com.openbag.association.community.repository.AssociationDocumentRepository;
import com.openbag.association.community.repository.BenefitRepository;
import com.openbag.association.finance.repository.MemberAddonRepository;
import com.openbag.association.finance.repository.MemberInvoiceRepository;
import com.openbag.association.community.repository.PollRepository;
import com.openbag.association.community.repository.PollVoteRepository;
import com.openbag.association.finance.service.AddonService;
import com.openbag.association.community.service.BenefitService;
import com.openbag.association.finance.service.LedgerService;
import com.openbag.association.finance.service.MembershipFeeCalculator;
import com.openbag.association.core.dto.AccountRequest;
import com.openbag.association.core.dto.CreateMemberRequest;
import com.openbag.association.core.dto.DeliveryPersonDataRequest;
import com.openbag.association.core.entity.AssociationMembership;
import com.openbag.association.core.entity.MembershipFeePolicy;
import com.openbag.association.core.entity.Organization;
import com.openbag.association.core.repository.AssociationMembershipRepository;
import com.openbag.association.core.repository.OrganizationRepository;
import com.openbag.association.core.service.MembershipService;
import com.openbag.restaurant.store.entity.Restaurant;
import com.openbag.restaurant.store.repository.RestaurantRepository;
import com.openbag.platform.files.FileStorageService;
import com.openbag.modules.user.entity.User;
import com.openbag.modules.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionTemplate;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Gestão da Cooperativa Demo para testar e tirar as capturas de tela: cobrança percentual com teto, seguro de vida,
 * três cooperados fictícios, faturas pagas e em aberto dos dois últimos meses, caixinha com um auxílio, convênios,
 * enquetes (uma aberta, para a conta demo votar) e atas em PDF. A Cantina Demo passa a repassar a taxa ao cliente.
 *
 * Só roda com app.demo.enabled=true, depois da {@link DemoDataInitializer}. Cada parte só é criada se ainda não
 * existir.
 */
@Component
@Order(3)
@Slf4j
@RequiredArgsConstructor
public class DemoCooperativeData implements ApplicationRunner {

    /** Cooperados fictícios: nome, e-mail, telefone, base do CPF (9 dígitos), veículo, modelo, placa */
    private static final List<String[]> MEMBERS = List.of(
            new String[]{"Ana Souza", "ana.demo@openbag.local", "00000000011", "123456789", "MOTORCYCLE", "Yamaha Factor 150", "ANA2B34"},
            new String[]{"Bruno Lima", "bruno.demo@openbag.local", "00000000012", "234567891", "MOTORCYCLE", "Honda Biz 125", "BRU3C45"},
            new String[]{"Carla Dias", "carla.demo@openbag.local", "00000000013", "345678912", "BICYCLE", null, null});

    private final UserRepository userRepository;
    private final OrganizationRepository organizationRepository;
    private final AssociationMembershipRepository membershipRepository;
    private final RestaurantRepository restaurantRepository;
    private final MembershipService membershipService;
    private final AddonService addonService;
    private final AddonPlanRepository planRepository;
    private final MemberAddonRepository memberAddonRepository;
    private final MemberInvoiceRepository invoiceRepository;
    private final LedgerService ledgerService;
    private final BenefitService benefitService;
    private final BenefitRepository benefitRepository;
    private final PollRepository pollRepository;
    private final PollVoteRepository voteRepository;
    private final AssociationDocumentRepository documentRepository;
    private final FileStorageService fileStorageService;
    private final TransactionTemplate transactionTemplate;

    @Value("${app.demo.enabled:false}")
    private boolean enabled;

    @Override
    public void run(ApplicationArguments args) {
        if (!enabled) {
            return;
        }
        try {
            transactionTemplate.executeWithoutResult(status -> ensurePassThroughStore());
            transactionTemplate.executeWithoutResult(status -> ensureFeePolicy());
            transactionTemplate.executeWithoutResult(status -> ensureMembers());
            transactionTemplate.executeWithoutResult(status -> ensureAddons());
            transactionTemplate.executeWithoutResult(status -> ensureInvoices());
            transactionTemplate.executeWithoutResult(status -> ensureBenefits());
            transactionTemplate.executeWithoutResult(status -> ensurePolls());
            transactionTemplate.executeWithoutResult(status -> ensureDocuments());
        } catch (RuntimeException e) {
            log.error("Não foi possível criar a gestão da Cooperativa Demo: {}", e.getMessage(), e);
        }
    }

    private User demoUser() {
        return userRepository.findByEmail(DemoDataInitializer.DEMO_EMAIL)
                .orElseThrow(() -> new IllegalStateException("Usuário demo não encontrado"));
    }

    private Organization organization() {
        return organizationRepository.findByAdminUserId(demoUser().getId()).stream().findFirst()
                .orElseThrow(() -> new IllegalStateException("Cooperativa demo não encontrada"));
    }

    /** Membros por e-mail (a conta demo e os fictícios) */
    private Map<String, AssociationMembership> members() {
        return membershipRepository.findByOrganizationId(organization().getId()).stream()
                .collect(Collectors.toMap(m -> m.getDeliveryPerson().getUser().getEmail(), Function.identity(),
                        (a, b) -> a));
    }

    private void ensurePassThroughStore() {
        restaurantRepository.findByOwnerIdOrderByNameAsc(demoUser().getId()).stream()
                .filter(r -> DemoDataInitializer.DEMO_SLUG.equals(r.getSlug()))
                .filter(r -> r.getDeliveryFeeMode() == DeliveryFeeMode.ASSUME && !r.isCoversDeliveryDifference())
                .findFirst()
                .ifPresent(restaurant -> {
                    restaurant.setDeliveryFeeMode(DeliveryFeeMode.PASS_THROUGH);
                    restaurantRepository.save(restaurant);
                    log.info("Demo: {} repassa a taxa ao cliente", restaurant.getName());
                });
    }

    private void ensureFeePolicy() {
        Organization organization = organization();
        if (organization.isFeePolicyConfigured()) {
            return;
        }
        organization.setFeePolicy(new MembershipFeePolicy(MembershipFeeMode.PERCENTAGE, null, new BigDecimal("5"),
                new BigDecimal("100.00"), 10));
        organizationRepository.save(organization);
    }

    private void ensureMembers() {
        Organization organization = organization();
        User manager = demoUser();
        for (String[] m : MEMBERS) {
            if (userRepository.existsByEmail(m[1])) {
                continue;
            }
            VehicleType vehicle = VehicleType.valueOf(m[4]);
            membershipService.createMember(organization.getId(), new CreateMemberRequest(
                    new AccountRequest(m[0], m[1], m[2], UUID.randomUUID().toString()),
                    new DeliveryPersonDataRequest(cpf(m[3]), "1" + m[3].substring(0, 8) + "00", vehicle, m[6], m[5],
                            vehicle == VehicleType.BICYCLE ? null : "Preta")), manager);
            log.info("Demo: cooperado {} criado", m[0]);
        }
    }

    /** Seguro de vida (+10% na mensalidade): ativo para a conta demo e para a Ana, proposto ao Bruno */
    private void ensureAddons() {
        Organization organization = organization();
        Map<String, AssociationMembership> members = members();
        AssociationMembership demo = members.get(DemoDataInitializer.DEMO_EMAIL);
        if (demo == null || !memberAddonRepository.findByMembership(demo.getId()).isEmpty()) {
            return;
        }
        AddonPlan plan = planRepository.findByOrganizationIdOrderByNameAsc(organization.getId()).stream()
                .filter(p -> p.getName().equals("Seguro de vida"))
                .findFirst()
                .orElse(null);
        if (plan == null) {
            addonService.createPlan(organization.getId(), new AddonPlanRequest("Seguro de vida",
                    "Cobertura por morte ou invalidez em serviço, pela seguradora parceira da cooperativa.",
                    AddonPricing.PERCENT_OF_FEE, new BigDecimal("10"), true));
            plan = planRepository.findByOrganizationIdOrderByNameAsc(organization.getId()).stream()
                    .filter(p -> p.getName().equals("Seguro de vida"))
                    .findFirst()
                    .orElseThrow();
        }

        addon(members.get(DemoDataInitializer.DEMO_EMAIL), plan, MemberAddonStatus.ACTIVE);
        addon(members.get("ana.demo@openbag.local"), plan, MemberAddonStatus.ACTIVE);
        addon(members.get("bruno.demo@openbag.local"), plan, MemberAddonStatus.PROPOSED);

        contribution(members.get(DemoDataInitializer.DEMO_EMAIL), "15.00");
        contribution(members.get("ana.demo@openbag.local"), "20.00");
    }

    private void addon(AssociationMembership membership, AddonPlan plan, MemberAddonStatus status) {
        if (membership == null) {
            return;
        }
        MemberAddon addon = new MemberAddon();
        addon.setMembership(membership);
        addon.setPlan(plan);
        addon.setStatus(status);
        if (status == MemberAddonStatus.ACTIVE) {
            addon.setDecidedAt(LocalDateTime.now().minusMonths(2));
        }
        memberAddonRepository.save(addon);
    }

    private void contribution(AssociationMembership membership, String amount) {
        if (membership != null) {
            membership.setSolidarityContribution(new BigDecimal(amount));
            membershipRepository.save(membership);
        }
    }

    /**
     * Faturas dos dois últimos meses (pagas, e duas em aberto no último), despesas da sede e um auxílio da caixinha
     */
    private void ensureInvoices() {
        Organization organization = organization();
        YearMonth last = YearMonth.now().minusMonths(1);
        YearMonth before = last.minusMonths(1);
        if (!invoiceRepository.findByOrganizationAndMonth(organization.getId(), before.atDay(1)).isEmpty()) {
            return;
        }
        Map<String, AssociationMembership> members = members();
        User manager = demoUser();
        List<AddonPlan> insurance = planRepository.findByOrganizationIdOrderByNameAsc(organization.getId()).stream()
                .filter(p -> p.getName().equals("Seguro de vida"))
                .toList();

        // Ganhos do mês de cada um: [mês retrasado, mês passado]
        Map<String, String[]> earnings = Map.of(
                DemoDataInitializer.DEMO_EMAIL, new String[]{"1480.00", "1620.50"},
                "ana.demo@openbag.local", new String[]{"2310.00", "2540.00"},
                "bruno.demo@openbag.local", new String[]{"960.00", "1105.00"},
                "carla.demo@openbag.local", new String[]{"520.00", "610.00"});
        Map<String, Boolean> withInsurance = Map.of(DemoDataInitializer.DEMO_EMAIL, true, "ana.demo@openbag.local", true);

        for (Map.Entry<String, String[]> entry : earnings.entrySet()) {
            AssociationMembership membership = members.get(entry.getKey());
            if (membership == null) {
                continue;
            }
            List<AddonPlan> addons = withInsurance.getOrDefault(entry.getKey(), false) ? insurance : List.of();
            invoice(organization, membership, before, entry.getValue()[0], addons, true, manager);
            boolean paidLast = entry.getKey().equals(DemoDataInitializer.DEMO_EMAIL)
                    || entry.getKey().equals("ana.demo@openbag.local");
            invoice(organization, membership, last, entry.getValue()[1], addons, paidLast, manager);
        }

        LocalDate beforeDay = before.atDay(12);
        LocalDate lastDay = last.atDay(15);
        ledgerService.create(organization.getId(), new LedgerEntryRequest(ManualEntryKind.EXPENSE,
                new BigDecimal("120.00"), beforeDay, "Impressão de material de divulgação", null), manager);
        ledgerService.create(organization.getId(), new LedgerEntryRequest(ManualEntryKind.CONTRIBUTION,
                new BigDecimal("200.00"), beforeDay.plusDays(3), "Rifa beneficente", null), manager);
        ledgerService.create(organization.getId(), new LedgerEntryRequest(ManualEntryKind.EXPENSE,
                new BigDecimal("180.00"), lastDay, "Honorários do contador", null), manager);
        AssociationMembership carla = members.get("carla.demo@openbag.local");
        if (carla != null) {
            ledgerService.create(organization.getId(), new LedgerEntryRequest(ManualEntryKind.AID,
                    new BigDecimal("180.00"), lastDay.plusDays(2), "Conserto da bicicleta depois de um acidente",
                    carla.getId()), manager);
        }
        log.info("Demo: faturas, despesas e caixinha da cooperativa criadas");
    }

    private void invoice(Organization organization, AssociationMembership membership, YearMonth month, String earned,
                         List<AddonPlan> addons, boolean paid, User manager) {
        BigDecimal earnings = new BigDecimal(earned);
        List<MemberInvoiceLine> lines = MembershipFeeCalculator.lines(organization.getFeePolicy(), earnings, addons,
                membership.getSolidarityContribution());
        MemberInvoice invoice = new MemberInvoice();
        invoice.setOrganization(organization);
        invoice.setMembership(membership);
        invoice.setMonth(month.atDay(1));
        invoice.setEarnings(earnings);
        invoice.setDeliveries(earnings.divide(new BigDecimal("9.50"), 0, java.math.RoundingMode.HALF_UP).intValue());
        invoice.setDueDate(month.plusMonths(1).atDay(organization.getFeePolicy().getDueDayOrDefault()));
        lines.forEach(invoice::addLine);
        invoice.setTotal(MembershipFeeCalculator.total(lines));
        invoice.setStatus(paid ? InvoiceStatus.PAID : InvoiceStatus.OPEN);
        if (paid) {
            invoice.setPaidOn(month.plusMonths(1).atDay(6));
            invoice.setPaymentMethod(MemberPaymentMethod.PIX);
            invoice.setRegisteredBy(manager);
        }
        invoiceRepository.save(invoice);
        if (paid) {
            ledgerService.recordInvoicePayment(invoice, manager);
        }
    }

    private void ensureBenefits() {
        Organization organization = organization();
        if (!benefitRepository.findByOrganizationIdOrderByPartnerNameAsc(organization.getId()).isEmpty()) {
            return;
        }
        benefitService.create(organization.getId(), new BenefitRequest("Oficina Duas Rodas", BenefitCategory.WORKSHOP,
                "15% em peças e mão de obra", "Revisão completa da moto com prioridade para cooperados. "
                + "Apresente a carteirinha da cooperativa.", "Rua XV de Novembro, 820 - Centro, Blumenau/SC",
                "4733221100", null, null, true));
        benefitService.create(organization.getId(), new BenefitRequest("Escola Fala Mais", BenefitCategory.LANGUAGES,
                "Inglês e espanhol com 30% de desconto", "Turmas à noite e aos sábados, pensadas para quem trabalha "
                + "com entregas.", "Rua Sete de Setembro, 1200 - Centro, Blumenau/SC", "4733445566",
                "https://example.com/falamais", null, true));
        benefitService.create(organization.getId(), new BenefitRequest("Posto Boa Viagem", BenefitCategory.FUEL,
                "R$ 0,15 a menos por litro", "Desconto na gasolina comum e na aditivada, todos os dias.",
                "Rua Amazonas, 45 - Garcia, Blumenau/SC", "4733887766", null, LocalDate.now().plusMonths(6), true));
    }

    /** Uma enquete aberta (a conta demo ainda não votou) e uma encerrada, com votos dos cooperados fictícios */
    private void ensurePolls() {
        Organization organization = organization();
        if (!pollRepository.findByOrganizationIdOrderByCreatedAtDesc(organization.getId()).isEmpty()) {
            return;
        }
        Map<String, AssociationMembership> members = members();
        LocalDateTime now = LocalDateTime.now();

        Poll closed = poll(organization, "Comprar capas de chuva coletivas com o dinheiro do caixa?",
                "Orçamento de R$ 1.200 para 20 capas, dividido pela cooperativa.", PollStatus.CLOSED,
                now.minusDays(20), List.of("Sim, comprar agora", "Não, esperar o próximo mês"));
        closed.setClosedAt(now.minusDays(13));
        pollRepository.save(closed);
        vote(closed, 0, members.get("ana.demo@openbag.local"));
        vote(closed, 0, members.get("bruno.demo@openbag.local"));
        vote(closed, 1, members.get("carla.demo@openbag.local"));
        vote(closed, 0, members.get(DemoDataInitializer.DEMO_EMAIL));

        Poll open = poll(organization, "Qual o melhor dia para a assembleia de outubro?",
                "A assembleia vai decidir o reajuste da tabela de entregas.", PollStatus.OPEN, now.minusDays(1),
                List.of("Sábado à tarde", "Domingo de manhã", "Segunda à noite"));
        open.setClosesAt(now.plusDays(6));
        pollRepository.save(open);
        vote(open, 0, members.get("ana.demo@openbag.local"));
        vote(open, 1, members.get("bruno.demo@openbag.local"));
    }

    private Poll poll(Organization organization, String question, String description, PollStatus status,
                      LocalDateTime openedAt, List<String> options) {
        Poll poll = new Poll();
        poll.setOrganization(organization);
        poll.setQuestion(question);
        poll.setDescription(description);
        poll.setStatus(status);
        poll.setOpenedAt(openedAt);
        poll.setCreatedBy(demoUser());
        for (int i = 0; i < options.size(); i++) {
            PollOption option = new PollOption();
            option.setPoll(poll);
            option.setLabel(options.get(i));
            option.setPosition(i);
            poll.getOptions().add(option);
        }
        return pollRepository.save(poll);
    }

    private void vote(Poll poll, int option, AssociationMembership membership) {
        if (membership == null) {
            return;
        }
        PollVote vote = new PollVote();
        vote.setPoll(poll);
        vote.setOption(poll.getOptions().stream().sorted(Comparator.comparingInt(PollOption::getPosition))
                .toList().get(option));
        vote.setMembership(membership);
        voteRepository.save(vote);
    }

    private void ensureDocuments() {
        Organization organization = organization();
        if (!documentRepository.findByOrganizationIdOrderByDateDescCreatedAtDesc(organization.getId()).isEmpty()) {
            return;
        }
        LocalDate meeting = YearMonth.now().minusMonths(1).atDay(20);
        document(organization, "Ata da assembleia ordinária", AssociationDocumentType.MINUTES, meeting,
                "Aprovação das contas do trimestre e da contratação do seguro de vida.",
                "ata-assembleia.pdf", List.of(
                        "Cooperativa Demo de Entregadores",
                        "Data: " + meeting,
                        "Presentes: 18 cooperados.",
                        "1. Aprovadas as contas do trimestre.",
                        "2. Aprovada a contratação do seguro de vida (+10% na mensalidade, opcional).",
                        "3. A caixinha solidária passa a aceitar contribuições mensais na fatura.",
                        "Documento de demonstração do OpenBag."));
        document(organization, "Estatuto social", AssociationDocumentType.BYLAWS, LocalDate.now().minusYears(1),
                "Regras da cooperativa, direitos e deveres dos cooperados.", "estatuto.pdf", List.of(
                        "Estatuto da Cooperativa Demo de Entregadores",
                        "Art. 1 - A cooperativa reúne entregadores autônomos da região.",
                        "Art. 2 - O entregador recebe 100% do valor de cada entrega.",
                        "Documento de demonstração do OpenBag."));
    }

    private void document(Organization organization, String title, AssociationDocumentType type, LocalDate date,
                          String description, String fileName, List<String> lines) {
        byte[] pdf = SimplePdf.of(title, lines);
        AssociationDocument document = new AssociationDocument();
        document.setOrganization(organization);
        document.setTitle(title);
        document.setType(type);
        document.setDate(date);
        document.setDescription(description);
        document.setFilePath(fileStorageService.storeDocument(pdf, "associations/" + organization.getId()));
        document.setFileName(fileName);
        document.setFileSize(pdf.length);
        document.setUploadedBy(demoUser());
        documentRepository.save(document);
    }

    /** CPF fictício com dígitos verificadores válidos a partir de 9 dígitos */
    static String cpf(String base) {
        int d1 = checkDigit(base, 10);
        int d2 = checkDigit(base + d1, 11);
        return base + d1 + d2;
    }

    private static int checkDigit(String digits, int weight) {
        int sum = 0;
        for (int i = 0; i < digits.length(); i++) {
            sum += (digits.charAt(i) - '0') * (weight - i);
        }
        int rest = sum % 11;
        return rest < 2 ? 0 : 11 - rest;
    }
}
