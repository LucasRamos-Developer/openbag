package com.openbag.modules.organization.service;

import com.openbag.enums.MemberBillingFilter;
import com.openbag.enums.MembershipStatus;
import com.openbag.enums.VehicleType;
import com.openbag.modules.delivery.entity.DeliveryPerson;
import com.openbag.modules.delivery.entity.Vehicle;
import com.openbag.modules.delivery.repository.VehicleRepository;
import com.openbag.modules.organization.entity.AssociationMembership;
import com.openbag.modules.organization.repository.AssociationMembershipRepository;
import com.openbag.platform.util.CsvWriter;
import com.openbag.modules.user.entity.User;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Comparator;
import java.util.EnumSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.stream.Collectors;

/**
 * Exportação da lista de associados em CSV (abre no Excel), com os mesmos filtros da tela
 */
@Service
@Transactional(readOnly = true)
public class MemberExportService {

    /** Limite de segurança: uma associação real fica muito abaixo disso */
    private static final int MAX_ROWS = 10_000;

    private static final DateTimeFormatter DATE = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    @Autowired
    private AssociationService associationService;

    @Autowired
    private AssociationMembershipRepository membershipRepository;

    @Autowired
    private VehicleRepository vehicleRepository;

    public byte[] exportCsv(Long organizationId, MembershipStatus status, VehicleType vehicleType,
                            MemberBillingFilter billing, String query) {
        associationService.findById(organizationId);
        Set<MembershipStatus> statuses = status != null ? EnumSet.of(status) : EnumSet.allOf(MembershipStatus.class);
        List<AssociationMembership> memberships = membershipRepository.search(organizationId, statuses,
                        vehicleType == null, vehicleType != null ? vehicleType : VehicleType.MOTORCYCLE,
                        (billing != null ? billing : MemberBillingFilter.ALL).name(),
                        query != null ? query.trim() : "", PageRequest.of(0, MAX_ROWS))
                .getContent().stream()
                .sorted(Comparator.comparing(AssociationMembership::getMemberNumber,
                                Comparator.nullsLast(Comparator.naturalOrder()))
                        .thenComparing(m -> m.getDeliveryPerson().getUser().getFullName()))
                .toList();

        Map<Long, List<Vehicle>> vehicles = vehicleRepository.findByDeliveryPersonIdInAndArchivedFalseOrderByCreatedAtAsc(
                        memberships.stream().map(m -> m.getDeliveryPerson().getId()).toList())
                .stream()
                .collect(Collectors.groupingBy(v -> v.getDeliveryPerson().getId()));

        Map<Long, Object[]> open = membershipRepository.openInvoicesByMembership(organizationId).stream()
                .collect(Collectors.toMap(row -> (Long) row[0], row -> row));
        Map<Long, String> addons = membershipRepository.activeAddonNames(organizationId).stream()
                .collect(Collectors.groupingBy(row -> (Long) row[0], TreeMap::new,
                        Collectors.mapping(row -> (String) row[1], Collectors.joining(", "))));

        CsvWriter csv = new CsvWriter().row("Número", "Nome", "CPF", "CNH", "Telefone", "E-mail", "Situação",
                "Solicitado em", "Veículo em uso", "Veículos cadastrados", "Entregas", "Faturas em aberto",
                "Valor em aberto", "Adicionais", "Caixinha por mês");
        for (AssociationMembership membership : memberships) {
            DeliveryPerson courier = membership.getDeliveryPerson();
            User user = courier.getUser();
            csv.row(
                    membership.getMemberNumber(),
                    user.getFullName(),
                    formatCpf(courier.getDocumentNumber()),
                    courier.getDriverLicense(),
                    user.getPhoneNumber(),
                    user.getEmail(),
                    membership.getStatus().getDisplayName(),
                    formatDate(membership.getRequestedAt()),
                    describe(courier.getActiveVehicle()),
                    vehicles.getOrDefault(courier.getId(), List.of()).stream()
                            .map(MemberExportService::describe)
                            .collect(Collectors.joining(" | ")),
                    courier.getTotalDeliveries(),
                    open.containsKey(membership.getId()) ? ((Number) open.get(membership.getId())[1]).intValue() : 0,
                    money(open.containsKey(membership.getId()) ? (BigDecimal) open.get(membership.getId())[2] : null),
                    addons.getOrDefault(membership.getId(), ""),
                    money(membership.getSolidarityContribution()));
        }
        return csv.toBytes();
    }

    static String describe(Vehicle vehicle) {
        if (vehicle == null) return "";
        StringBuilder text = new StringBuilder(vehicle.getType().getDisplayName());
        if (vehicle.getModel() != null && !vehicle.getModel().isBlank()) text.append(' ').append(vehicle.getModel());
        if (vehicle.getColor() != null && !vehicle.getColor().isBlank()) text.append(' ').append(vehicle.getColor());
        if (vehicle.getPlate() != null && !vehicle.getPlate().isBlank()) text.append(" (").append(vehicle.getPlate()).append(')');
        return text.toString();
    }

    /** Valor no formato do Excel em português: 1234,50 (vazio = zero) */
    static String money(BigDecimal value) {
        return (value != null ? value : BigDecimal.ZERO).setScale(2, RoundingMode.HALF_UP).toPlainString().replace('.', ',');
    }

    private static String formatCpf(String cpf) {
        if (cpf == null || cpf.length() != 11) return cpf;
        return cpf.substring(0, 3) + "." + cpf.substring(3, 6) + "." + cpf.substring(6, 9) + "-" + cpf.substring(9);
    }

    private static String formatDate(LocalDateTime dateTime) {
        return dateTime != null ? dateTime.format(DATE) : "";
    }
}
