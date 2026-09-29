package com.openbag.association.finance.service;

import com.openbag.association.finance.entity.AddonPricing;
import com.openbag.association.finance.entity.InvoiceStatus;
import com.openbag.association.finance.entity.MemberPaymentMethod;
import com.openbag.association.core.entity.MembershipFeeMode;
import com.openbag.association.core.entity.MembershipStatus;
import com.openbag.association.core.entity.OrganizationStatus;
import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.association.finance.dto.InvoiceMonthDTO;
import com.openbag.association.finance.dto.PayInvoiceRequest;
import com.openbag.association.finance.entity.AddonPlan;
import com.openbag.association.finance.entity.MemberInvoice;
import com.openbag.association.finance.repository.MemberInvoiceRepository;
import com.openbag.delivery.courier.entity.DeliveryPerson;
import com.openbag.order.core.repository.OrderRepository;
import com.openbag.association.core.entity.AssociationMembership;
import com.openbag.association.core.entity.MembershipFeePolicy;
import com.openbag.association.core.entity.Organization;
import com.openbag.association.core.repository.AssociationMembershipRepository;
import com.openbag.association.core.repository.OrganizationRepository;
import com.openbag.association.core.service.AssociationService;
import com.openbag.account.entity.User;
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
import java.time.YearMonth;
import java.time.ZoneId;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;
import com.openbag.association.member.service.MemberContext;

@ExtendWith(MockitoExtension.class)
class MemberInvoiceServiceTest {

    private static final ZoneId ZONE = ZoneId.of("America/Sao_Paulo");
    private static final LocalDateTime NOW = LocalDateTime.of(2026, 9, 28, 10, 0);

    @Mock private MemberInvoiceRepository invoiceRepository;
    @Mock private AssociationMembershipRepository membershipRepository;
    @Mock private OrganizationRepository organizationRepository;
    @Mock private OrderRepository orderRepository;
    @Mock private AssociationService associationService;
    @Mock private AddonService addonService;
    @Mock private LedgerService ledgerService;
    @Mock private MemberContext memberContext;
    @Spy private Clock clock = Clock.fixed(NOW.atZone(ZONE).toInstant(), ZONE);

    @InjectMocks
    private MemberInvoiceService service;

    private Organization organization;
    private AssociationMembership ana;
    private AssociationMembership bruno;

    @BeforeEach
    void setUp() {
        organization = new Organization();
        organization.setId(10L);
        organization.setStatus(OrganizationStatus.ACTIVE);
        organization.setFeePolicy(new MembershipFeePolicy(MembershipFeeMode.PERCENTAGE, null, new BigDecimal("5"),
                new BigDecimal("100.00"), 10));

        ana = membership(1L, 100L, "Ana", 1, MembershipStatus.ACTIVE);
        ana.setSolidarityContribution(new BigDecimal("15.00"));
        bruno = membership(2L, 200L, "Bruno", 2, MembershipStatus.ACTIVE);

        lenient().when(associationService.findById(10L)).thenReturn(organization);
        lenient().when(associationService.findOperational(10L)).thenReturn(organization);
        lenient().when(membershipRepository.findByOrganizationId(10L)).thenReturn(List.of(ana, bruno));
        lenient().when(orderRepository.sumCourierEarningsByCourier(eq(10L), any(), any())).thenReturn(List.<Object[]>of(
                new Object[]{100L, new BigDecimal("3000.00"), 120L},
                new Object[]{200L, new BigDecimal("800.00"), 40L}));
        AddonPlan insurance = new AddonPlan();
        insurance.setName("Seguro de vida");
        insurance.setPricing(AddonPricing.PERCENT_OF_FEE);
        insurance.setValue(new BigDecimal("10"));
        lenient().when(addonService.activeByMembership(10L)).thenReturn(Map.of(1L, List.of(insurance)));
        lenient().when(invoiceRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
    }

    private AssociationMembership membership(Long id, Long courierId, String name, int number, MembershipStatus status) {
        User user = new User();
        user.setFullName(name);
        DeliveryPerson courier = new DeliveryPerson();
        courier.setId(courierId);
        courier.setUser(user);
        AssociationMembership membership = new AssociationMembership();
        membership.setId(id);
        membership.setOrganization(organization);
        membership.setDeliveryPerson(courier);
        membership.setMemberNumber(number);
        membership.setStatus(status);
        membership.setRequestedAt(NOW.minusMonths(3));
        return membership;
    }

    @Test
    void generatesTheMissingInvoicesOfAClosedMonthWithoutDuplicating() {
        YearMonth august = YearMonth.of(2026, 8);
        // Bruno já tem a fatura de agosto
        when(invoiceRepository.existsByMembershipIdAndMonth(anyLong(), any()))
                .thenAnswer(inv -> inv.getArgument(0).equals(2L));

        service.generate(10L, august);

        ArgumentCaptor<MemberInvoice> saved = ArgumentCaptor.forClass(MemberInvoice.class);
        verify(invoiceRepository, times(1)).save(saved.capture());
        MemberInvoice invoice = saved.getValue();
        assertThat(invoice.getMembership()).isSameAs(ana);
        assertThat(invoice.getMonth()).isEqualTo(LocalDate.of(2026, 8, 1));
        assertThat(invoice.getDeliveries()).isEqualTo(120);
        // 5% de 3.000 = 150 → teto 100; seguro 10% = 10; caixinha 15
        assertThat(invoice.getTotal()).isEqualByComparingTo("125.00");
        assertThat(invoice.getDueDate()).isEqualTo(LocalDate.of(2026, 9, 10));
        assertThat(invoice.getStatus()).isEqualTo(InvoiceStatus.OPEN);
    }

    @Test
    void currentMonthIsAPreviewThatIsNeverSaved() {
        InvoiceMonthDTO month = service.listMonth(10L, YearMonth.of(2026, 9));

        assertThat(month.preview()).isTrue();
        assertThat(month.invoices()).hasSize(2);
        assertThat(month.invoices().get(1).total()).isEqualByComparingTo("40.00");
        verify(invoiceRepository, never()).save(any());
        assertThatThrownBy(() -> service.generate(10L, YearMonth.of(2026, 9)))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("depois que ele termina");
    }

    @Test
    void zeroInvoicesAndMonthsBeforeJoiningAreNotBilled() {
        when(orderRepository.sumCourierEarningsByCourier(eq(10L), any(), any())).thenReturn(List.<Object[]>of(
                new Object[]{100L, BigDecimal.ZERO, 0L}));
        ana.setSolidarityContribution(null);
        when(addonService.activeByMembership(10L)).thenReturn(Map.of());
        bruno.setRequestedAt(LocalDateTime.of(2026, 9, 2, 8, 0));

        service.generate(10L, YearMonth.of(2026, 8));

        // Ana ficou com fatura zerada; Bruno entrou em setembro e não paga agosto
        verify(invoiceRepository, never()).save(any());
        assertThat(service.drafts(organization, YearMonth.of(2026, 8))).extracting(MemberInvoice::getMembership)
                .containsExactly(ana);
    }

    @Test
    void cannotGenerateWithoutAFeePolicy() {
        organization.setFeePolicy(null);

        assertThatThrownBy(() -> service.generate(10L, YearMonth.of(2026, 8)))
                .hasMessageContaining("Defina como cobrar");
    }

    @Test
    void memberWhoLeftIsBilledOnlyForTheFeeOfTheDeliveriesHeMade() {
        bruno.setStatus(MembershipStatus.LEFT);
        bruno.setSolidarityContribution(new BigDecimal("20.00"));
        when(addonService.activeByMembership(10L)).thenReturn(Map.of(2L, List.of(new AddonPlan())));

        List<MemberInvoice> drafts = service.drafts(organization, YearMonth.of(2026, 8));

        MemberInvoice brunos = drafts.stream().filter(d -> d.getMembership() == bruno).findFirst().orElseThrow();
        assertThat(brunos.getLines()).hasSize(1);
        assertThat(brunos.getTotal()).isEqualByComparingTo("40.00");
    }

    @Test
    void paymentIsRecordedInTheLedgerAndReopeningRemovesIt() {
        MemberInvoice invoice = new MemberInvoice();
        invoice.setId(7L);
        invoice.setOrganization(organization);
        invoice.setMembership(ana);
        invoice.setMonth(LocalDate.of(2026, 8, 1));
        invoice.setDueDate(LocalDate.of(2026, 9, 10));
        invoice.setEarnings(BigDecimal.ZERO);
        invoice.setTotal(new BigDecimal("125.00"));
        invoice.setStatus(InvoiceStatus.OPEN);
        when(invoiceRepository.findByIdAndOrganizationForUpdate(7L, 10L)).thenReturn(Optional.of(invoice));
        User manager = new User();

        service.pay(10L, 7L, new PayInvoiceRequest(MemberPaymentMethod.PIX, null, null), manager);

        assertThat(invoice.getStatus()).isEqualTo(InvoiceStatus.PAID);
        assertThat(invoice.getPaidOn()).isEqualTo(NOW.toLocalDate());
        verify(ledgerService).recordInvoicePayment(invoice, manager);
        assertThatThrownBy(() -> service.pay(10L, 7L, new PayInvoiceRequest(MemberPaymentMethod.PIX, null, null), manager))
                .hasMessageContaining("não está em aberto");

        service.reopen(10L, 7L);

        assertThat(invoice.getStatus()).isEqualTo(InvoiceStatus.OPEN);
        assertThat(invoice.getPaidOn()).isNull();
        verify(ledgerService).removeInvoiceEntries(invoice);
    }

    @Test
    void paymentDateCannotBeInTheFuture() {
        MemberInvoice invoice = new MemberInvoice();
        invoice.setStatus(InvoiceStatus.OPEN);
        when(invoiceRepository.findByIdAndOrganizationForUpdate(anyLong(), anyLong())).thenReturn(Optional.of(invoice));

        assertThatThrownBy(() -> service.pay(10L, 7L,
                new PayInvoiceRequest(MemberPaymentMethod.CASH, NOW.toLocalDate().plusDays(1), null), new User()))
                .hasMessageContaining("futuro");
    }

    @Test
    void dueDateFitsShortMonths() {
        MembershipFeePolicy policy = new MembershipFeePolicy(MembershipFeeMode.FIXED, BigDecimal.TEN, null, null, 28);

        assertThat(MemberInvoiceService.dueDate(YearMonth.of(2027, 1), policy)).isEqualTo(LocalDate.of(2027, 2, 28));
    }
}
