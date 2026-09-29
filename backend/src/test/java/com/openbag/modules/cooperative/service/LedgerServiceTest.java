package com.openbag.modules.cooperative.service;

import com.openbag.enums.InvoiceLineType;
import com.openbag.enums.InvoiceStatus;
import com.openbag.enums.LedgerAccount;
import com.openbag.enums.LedgerCategory;
import com.openbag.enums.LedgerDirection;
import com.openbag.enums.ManualEntryKind;
import com.openbag.modules.cooperative.dto.FinanceSummaryDTO;
import com.openbag.modules.cooperative.dto.LedgerEntryRequest;
import com.openbag.modules.cooperative.dto.SolidarityFundDTO;
import com.openbag.modules.cooperative.entity.LedgerEntry;
import com.openbag.modules.cooperative.entity.MemberInvoice;
import com.openbag.modules.cooperative.entity.MemberInvoiceLine;
import com.openbag.modules.cooperative.repository.LedgerEntryRepository;
import com.openbag.modules.cooperative.repository.MemberInvoiceRepository;
import com.openbag.delivery.courier.entity.DeliveryPerson;
import com.openbag.modules.organization.entity.AssociationMembership;
import com.openbag.modules.organization.entity.Organization;
import com.openbag.modules.organization.repository.AssociationMembershipRepository;
import com.openbag.modules.organization.service.AssociationService;
import com.openbag.modules.user.entity.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class LedgerServiceTest {

    private static final ZoneId ZONE = ZoneId.of("America/Sao_Paulo");
    private static final LocalDateTime NOW = LocalDateTime.of(2026, 9, 28, 10, 0);

    @Mock private LedgerEntryRepository ledgerRepository;
    @Mock private MemberInvoiceRepository invoiceRepository;
    @Mock private AssociationMembershipRepository membershipRepository;
    @Mock private AssociationService associationService;
    @Mock private com.openbag.modules.organization.repository.OrganizationRepository organizationRepository;
    @Spy private Clock clock = Clock.fixed(NOW.atZone(ZONE).toInstant(), ZONE);

    @InjectMocks
    private LedgerService service;

    private Organization organization;
    private AssociationMembership ana;

    @BeforeEach
    void setUp() {
        organization = new Organization();
        organization.setId(10L);
        User user = new User();
        user.setFullName("Ana Souza");
        DeliveryPerson courier = new DeliveryPerson();
        courier.setUser(user);
        ana = new AssociationMembership();
        ana.setId(1L);
        ana.setOrganization(organization);
        ana.setDeliveryPerson(courier);
        ana.setMemberNumber(12);
        lenient().when(associationService.findOperational(10L)).thenReturn(organization);
        lenient().when(associationService.findById(10L)).thenReturn(organization);
        lenient().when(membershipRepository.findByIdAndOrganizationId(1L, 10L)).thenReturn(Optional.of(ana));
        lenient().when(ledgerRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
    }

    private static LedgerEntry entry(LedgerAccount account, LedgerDirection direction, LedgerCategory category,
                                     String amount, LocalDate date) {
        LedgerEntry entry = new LedgerEntry();
        entry.setAccount(account);
        entry.setDirection(direction);
        entry.setCategory(category);
        entry.setAmount(new BigDecimal(amount));
        entry.setDate(date);
        entry.setDescription("x");
        return entry;
    }

    @Test
    void paidInvoiceGoesToTheGeneralAccountAndTheContributionToTheFund() {
        MemberInvoice invoice = new MemberInvoice();
        invoice.setOrganization(organization);
        invoice.setMembership(ana);
        invoice.setMonth(LocalDate.of(2026, 8, 1));
        invoice.setPaidOn(LocalDate.of(2026, 9, 5));
        invoice.setStatus(InvoiceStatus.PAID);
        invoice.addLine(new MemberInvoiceLine(InvoiceLineType.FEE, "Mensalidade", new BigDecimal("100.00")));
        invoice.addLine(new MemberInvoiceLine(InvoiceLineType.ADDON, "Seguro de vida", new BigDecimal("10.00")));
        invoice.addLine(new MemberInvoiceLine(InvoiceLineType.SOLIDARITY, "Caixinha solidária", new BigDecimal("15.00")));

        service.recordInvoicePayment(invoice, new User());

        ArgumentCaptor<LedgerEntry> saved = ArgumentCaptor.forClass(LedgerEntry.class);
        verify(ledgerRepository, times(3)).save(saved.capture());
        assertThat(saved.getAllValues()).extracting(LedgerEntry::getAccount)
                .containsExactly(LedgerAccount.GENERAL, LedgerAccount.GENERAL, LedgerAccount.SOLIDARITY_FUND);
        assertThat(saved.getAllValues()).extracting(LedgerEntry::getCategory)
                .containsExactly(LedgerCategory.MEMBERSHIP_FEE, LedgerCategory.ADDON, LedgerCategory.CONTRIBUTION);
        assertThat(saved.getAllValues().get(0).getDescription()).isEqualTo("Mensalidade 08/2026 · Ana Souza (nº 12)");
        assertThat(saved.getAllValues()).allMatch(e -> e.getDate().equals(LocalDate.of(2026, 9, 5)));
    }

    @Test
    void aidCannotLeaveTheFundNegativeAndNeedsAMember() {
        when(ledgerRepository.balance(10L, LedgerAccount.SOLIDARITY_FUND)).thenReturn(new BigDecimal("300.00"));

        assertThatThrownBy(() -> service.create(10L,
                new LedgerEntryRequest(ManualEntryKind.AID, new BigDecimal("500.00"), null, "Conserto da moto", 1L),
                new User()))
                .hasMessageContaining("Saldo insuficiente");
        assertThatThrownBy(() -> service.create(10L,
                new LedgerEntryRequest(ManualEntryKind.AID, new BigDecimal("50.00"), null, "Remédio", null),
                new User()))
                .hasMessageContaining("Escolha o cooperado");

        var created = service.create(10L,
                new LedgerEntryRequest(ManualEntryKind.AID, new BigDecimal("300.00"), null, "Conserto da moto", 1L),
                new User());
        assertThat(created.account()).isEqualTo(LedgerAccount.SOLIDARITY_FUND);
        assertThat(created.direction()).isEqualTo(LedgerDirection.OUT);
        assertThat(created.date()).isEqualTo(NOW.toLocalDate());
    }

    @Test
    void entriesFromInvoicesAreOnlyRemovedByReopeningTheInvoice() {
        LedgerEntry fromInvoice = entry(LedgerAccount.GENERAL, LedgerDirection.IN, LedgerCategory.MEMBERSHIP_FEE,
                "100", NOW.toLocalDate());
        fromInvoice.setInvoice(new MemberInvoice());
        when(ledgerRepository.findByIdAndOrganizationId(5L, 10L)).thenReturn(Optional.of(fromInvoice));

        assertThatThrownBy(() -> service.delete(10L, 5L)).hasMessageContaining("desfaça a baixa");
        verify(ledgerRepository, never()).delete(any());
    }

    @Test
    void memberSeesTheFundWithoutTheNamesOfWhoReceivedAid() {
        LedgerEntry aid = entry(LedgerAccount.SOLIDARITY_FUND, LedgerDirection.OUT, LedgerCategory.AID, "200",
                LocalDate.of(2026, 9, 20));
        aid.setDescription("Conserto da moto do Bruno");
        LedgerEntry contribution = entry(LedgerAccount.SOLIDARITY_FUND, LedgerDirection.IN,
                LedgerCategory.CONTRIBUTION, "500", LocalDate.of(2026, 9, 5));
        when(ledgerRepository.findRecent(eq(10L), eq(LedgerAccount.SOLIDARITY_FUND), any()))
                .thenReturn(List.of(aid, contribution));
        when(ledgerRepository.contributedBy(1L)).thenReturn(new BigDecimal("45.00"));

        SolidarityFundDTO fund = service.fundForMember(ana);

        assertThat(fund.balance()).isEqualByComparingTo("300.00");
        assertThat(fund.aids()).isEqualTo(1);
        assertThat(fund.myContribution()).isEqualByComparingTo("45.00");
        assertThat(fund.recent()).extracting(SolidarityFundDTO.Movement::description)
                .containsExactly("Auxílio a um cooperado", "Contribuição")
                .noneMatch(d -> d.contains("Bruno"));
    }

    @Test
    void summaryShowsCollectedSpentReceivableAndBalances() {
        when(ledgerRepository.findBetween(eq(10L), any(), any())).thenReturn(List.of(
                entry(LedgerAccount.GENERAL, LedgerDirection.IN, LedgerCategory.MEMBERSHIP_FEE, "1000", LocalDate.of(2026, 8, 10)),
                entry(LedgerAccount.GENERAL, LedgerDirection.OUT, LedgerCategory.EXPENSE, "250", LocalDate.of(2026, 9, 2)),
                entry(LedgerAccount.SOLIDARITY_FUND, LedgerDirection.IN, LedgerCategory.CONTRIBUTION, "150", LocalDate.of(2026, 9, 5)),
                entry(LedgerAccount.SOLIDARITY_FUND, LedgerDirection.OUT, LedgerCategory.AID, "100", LocalDate.of(2026, 9, 20))));
        when(invoiceRepository.sumByStatus(10L, InvoiceStatus.OPEN)).thenReturn(new BigDecimal("380.00"));
        when(invoiceRepository.sumOverdue(10L, NOW.toLocalDate())).thenReturn(new BigDecimal("120.00"));
        when(ledgerRepository.balance(10L, LedgerAccount.GENERAL)).thenReturn(new BigDecimal("750.00"));
        when(ledgerRepository.balance(10L, LedgerAccount.SOLIDARITY_FUND)).thenReturn(new BigDecimal("50.00"));

        FinanceSummaryDTO summary = service.summary(10L, null, null);

        assertThat(summary.from()).isEqualTo(LocalDate.of(2026, 4, 1));
        assertThat(summary.collected()).isEqualByComparingTo("1150");
        assertThat(summary.spent()).isEqualByComparingTo("350");
        assertThat(summary.receivable()).isEqualByComparingTo("380.00");
        assertThat(summary.overdue()).isEqualByComparingTo("120.00");
        assertThat(summary.fundBalance()).isEqualByComparingTo("50.00");
        assertThat(summary.months()).hasSize(6);
        FinanceSummaryDTO.Month september = summary.months().get(5);
        assertThat(september.in()).isEqualByComparingTo("150");
        assertThat(september.out()).isEqualByComparingTo("350");
        assertThat(september.fundOut()).isEqualByComparingTo("100");
    }
}
