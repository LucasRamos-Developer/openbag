package com.openbag.association.partnership.service;

import com.openbag.association.core.entity.MembershipStatus;
import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.platform.web.exception.ResourceNotFoundException;
import com.openbag.association.partnership.dto.AssociationReportDTO;
import com.openbag.delivery.courier.entity.DeliveryPerson;
import com.openbag.association.partnership.entity.RestaurantPartnership;
import com.openbag.delivery.courier.repository.DeliveryPersonRepository;
import com.openbag.association.partnership.repository.RestaurantPartnershipRepository;
import com.openbag.order.core.entity.Order;
import com.openbag.order.core.repository.OrderRepository;
import com.openbag.order.incident.entity.IncidentType;
import com.openbag.order.incident.repository.OrderIncidentRepository;
import com.openbag.order.incident.repository.OrderIncidentRepository.RestaurantTypeCount;
import com.openbag.association.core.entity.AssociationMembership;
import com.openbag.association.core.entity.Organization;
import com.openbag.association.core.repository.AssociationMembershipRepository;
import com.openbag.association.core.repository.OrganizationRepository;
import com.openbag.restaurant.store.entity.Restaurant;
import com.openbag.account.entity.User;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Relatórios da associação: entregas e ganhos dos cooperados no período, por dia, por cooperado e por loja,
 * e as ocorrências relatadas por tipo e por loja.
 * Usa a associação registrada no pedido, então quem trocou de associação não leva o histórico junto.
 */
@Service
@Transactional(readOnly = true)
public class AssociationReportService {

    private static final int MAX_PERIOD_DAYS = 92;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private OrganizationRepository organizationRepository;

    @Autowired
    private AssociationMembershipRepository membershipRepository;

    @Autowired
    private RestaurantPartnershipRepository partnershipRepository;

    @Autowired
    private DeliveryPersonRepository deliveryPersonRepository;

    @Autowired
    private OrderIncidentRepository incidentRepository;

    @Autowired
    private Clock clock;

    /** Relatório completo, para o gestor (padrão: últimos 30 dias) */
    public AssociationReportDTO forManager(Long organizationId, LocalDate from, LocalDate to) {
        Organization organization = organizationRepository.findById(organizationId)
                .orElseThrow(() -> new ResourceNotFoundException("Associação não encontrada"));
        Period period = Period.of(from, to, LocalDate.now(clock));
        List<Order> orders = delivered(organizationId, period);
        AssociationReportDTO report = build(organization, period, orders);
        report.setByMember(byMember(organizationId, orders));
        return report;
    }

    /** Resumo da associação para o cooperado ativo, com a parte dele e sem os ganhos dos colegas */
    public AssociationReportDTO forMember(User user, LocalDate from, LocalDate to) {
        DeliveryPerson courier = deliveryPersonRepository.findByUserId(user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Perfil de entregador não encontrado"));
        AssociationMembership membership = membershipRepository
                .findByDeliveryPersonIdAndStatusIn(courier.getId(), EnumSet.of(MembershipStatus.ACTIVE)).stream()
                .findFirst()
                .orElseThrow(() -> new ResourceNotFoundException("Você não faz parte de uma associação"));

        Organization organization = membership.getOrganization();
        Period period = Period.of(from, to, LocalDate.now(clock));
        List<Order> orders = delivered(organization.getId(), period);
        AssociationReportDTO report = build(organization, period, orders);
        List<Order> mine = orders.stream()
                .filter(o -> o.getDeliveryPerson().getId().equals(courier.getId()))
                .toList();
        report.setMine(new AssociationReportDTO.Mine(mine.size(), sum(mine, Order::getCourierFee)));
        return report;
    }

    private AssociationReportDTO build(Organization organization, Period period, List<Order> orders) {
        return AssociationReportDTO.builder()
                .organizationId(organization.getId())
                .associationName(organization.getTradingName())
                .from(period.start())
                .to(period.end())
                .summary(summary(orders))
                .daily(daily(orders, period.start(), period.end()))
                .byRestaurant(byRestaurant(organization.getId(), orders))
                .incidents(incidents(incidentRepository.countByRestaurantAndType(organization.getId(),
                        period.start().atStartOfDay(), period.end().plusDays(1).atStartOfDay())))
                .build();
    }

    private List<Order> delivered(Long organizationId, Period period) {
        return orderRepository.findDeliveredByOrganizationBetween(organizationId, period.start().atStartOfDay(),
                period.end().plusDays(1).atStartOfDay());
    }

    /** Período do relatório (padrão: últimos 30 dias até hoje), de até {@value #MAX_PERIOD_DAYS} dias */
    private record Period(LocalDate start, LocalDate end) {

        static Period of(LocalDate from, LocalDate to, LocalDate today) {
            LocalDate end = to != null ? to : today;
            LocalDate start = from != null ? from : end.minusDays(29);
            if (start.isAfter(end)) {
                throw new BadRequestException("A data inicial deve ser anterior à final");
            }
            if (ChronoUnit.DAYS.between(start, end) >= MAX_PERIOD_DAYS) {
                throw new BadRequestException("Escolha um período de até " + MAX_PERIOD_DAYS + " dias");
            }
            return new Period(start, end);
        }
    }

    static AssociationReportDTO.Summary summary(List<Order> orders) {
        return new AssociationReportDTO.Summary(orders.size(), sum(orders, Order::getCourierFee), km(orders),
                orders.stream().map(o -> o.getDeliveryPerson().getId()).distinct().count(),
                orders.stream().map(o -> o.getRestaurant().getId()).distinct().count(),
                sum(orders, Order::getRestaurantDeliverySubsidy));
    }

    static List<AssociationReportDTO.Day> daily(List<Order> orders, LocalDate start, LocalDate end) {
        Map<LocalDate, List<Order>> byDay = orders.stream()
                .collect(Collectors.groupingBy(o -> o.getDeliveredAt().toLocalDate()));
        List<AssociationReportDTO.Day> daily = new ArrayList<>();
        for (LocalDate day = start; !day.isAfter(end); day = day.plusDays(1)) {
            List<Order> dayOrders = byDay.getOrDefault(day, List.of());
            daily.add(new AssociationReportDTO.Day(day, sum(dayOrders, Order::getCourierFee), dayOrders.size()));
        }
        return daily;
    }

    private List<AssociationReportDTO.MemberLine> byMember(Long organizationId, List<Order> orders) {
        // Número de associado: o do vínculo mais recente de cada entregador com esta associação
        Map<Long, Integer> memberNumbers = new HashMap<>();
        membershipRepository.findByOrganizationId(organizationId).stream()
                .sorted(Comparator.comparing(AssociationMembership::getRequestedAt,
                        Comparator.nullsFirst(Comparator.naturalOrder())))
                .forEach(m -> {
                    if (m.getMemberNumber() != null) {
                        memberNumbers.put(m.getDeliveryPerson().getId(), m.getMemberNumber());
                    }
                });

        return orders.stream()
                .collect(Collectors.groupingBy(o -> o.getDeliveryPerson().getId(), LinkedHashMap::new,
                        Collectors.toList()))
                .entrySet().stream()
                .map(entry -> {
                    DeliveryPerson courier = entry.getValue().get(0).getDeliveryPerson();
                    return new AssociationReportDTO.MemberLine(courier.getId(), courier.getUser().getFullName(),
                            memberNumbers.get(entry.getKey()), entry.getValue().size(),
                            sum(entry.getValue(), Order::getCourierFee), km(entry.getValue()));
                })
                .sorted(Comparator.comparing(AssociationReportDTO.MemberLine::earnings).reversed())
                .toList();
    }

    private List<AssociationReportDTO.RestaurantLine> byRestaurant(Long organizationId, List<Order> orders) {
        Set<Long> withAgreement = partnershipRepository.findActiveByOrganization(organizationId).stream()
                .filter(RestaurantPartnership::hasAgreedRate)
                .map(p -> p.getRestaurant().getId())
                .collect(Collectors.toSet());
        Map<Long, List<Order>> grouped = orders.stream()
                .collect(Collectors.groupingBy(o -> o.getRestaurant().getId()));
        Map<Long, Restaurant> restaurants = orders.stream()
                .map(Order::getRestaurant)
                .collect(Collectors.toMap(Restaurant::getId, Function.identity(), (a, b) -> a));

        return grouped.entrySet().stream()
                .map(entry -> {
                    Restaurant restaurant = restaurants.get(entry.getKey());
                    return new AssociationReportDTO.RestaurantLine(restaurant.getId(), restaurant.getName(),
                            restaurant.getSlug(), restaurant.getLogoUrl(), entry.getValue().size(),
                            sum(entry.getValue(), Order::getCourierFee),
                            sum(entry.getValue(), Order::getRestaurantDeliverySubsidy),
                            withAgreement.contains(restaurant.getId()));
                })
                .sorted(Comparator.comparing(AssociationReportDTO.RestaurantLine::deliveries).reversed())
                .toList();
    }

    /** Junta as contagens por loja e tipo: total, por tipo e por loja, do mais citado para o menos */
    static AssociationReportDTO.Incidents incidents(List<RestaurantTypeCount> rows) {
        Map<IncidentType, Long> byType = rows.stream()
                .collect(Collectors.groupingBy(RestaurantTypeCount::type, () -> new EnumMap<>(IncidentType.class),
                        Collectors.summingLong(RestaurantTypeCount::count)));
        List<AssociationReportDTO.RestaurantIncidents> byRestaurant = rows.stream()
                .collect(Collectors.groupingBy(RestaurantTypeCount::restaurantId, LinkedHashMap::new,
                        Collectors.toList()))
                .values().stream()
                .map(lines -> {
                    RestaurantTypeCount first = lines.get(0);
                    return new AssociationReportDTO.RestaurantIncidents(first.restaurantId(), first.name(),
                            first.slug(), first.logoUrl(), lines.stream().mapToLong(RestaurantTypeCount::count).sum(),
                            typeCounts(lines.stream().collect(Collectors.toMap(RestaurantTypeCount::type,
                                    RestaurantTypeCount::count))));
                })
                .sorted(Comparator.comparingLong(AssociationReportDTO.RestaurantIncidents::total).reversed()
                        .thenComparing(AssociationReportDTO.RestaurantIncidents::name))
                .toList();
        return new AssociationReportDTO.Incidents(byType.values().stream().mapToLong(Long::longValue).sum(),
                typeCounts(byType), byRestaurant);
    }

    private static List<AssociationReportDTO.TypeCount> typeCounts(Map<IncidentType, Long> counts) {
        return counts.entrySet().stream()
                .map(e -> new AssociationReportDTO.TypeCount(e.getKey(), e.getValue()))
                .sorted(Comparator.comparingLong(AssociationReportDTO.TypeCount::count).reversed()
                        .thenComparing(AssociationReportDTO.TypeCount::type))
                .toList();
    }

    private static BigDecimal sum(List<Order> orders, Function<Order, BigDecimal> value) {
        return orders.stream().map(value).filter(Objects::nonNull).reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private static double km(List<Order> orders) {
        double total = orders.stream().map(Order::getDeliveryDistanceKm).filter(Objects::nonNull)
                .mapToDouble(Double::doubleValue).sum();
        return Math.round(total * 10) / 10.0;
    }
}
