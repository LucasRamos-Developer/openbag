package com.openbag.modules.delivery.service;

import com.openbag.enums.CourierPolicy;
import com.openbag.enums.OrganizationStatus;
import com.openbag.modules.delivery.entity.RestaurantPartnership;
import com.openbag.modules.delivery.repository.RestaurantPartnershipRepository;
import com.openbag.modules.organization.entity.DeliveryRate;
import com.openbag.modules.organization.entity.Organization;
import com.openbag.modules.organization.repository.OrganizationRepository;
import com.openbag.modules.restaurant.entity.Restaurant;
import com.openbag.modules.shared.service.GeocodingService;
import com.openbag.modules.shared.util.GeoUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Taxa de entrega cobrada do cliente.
 *
 * Loja que assume ({@code ASSUME}): a taxa fixa que ela definiu.
 * Loja que repassa ({@code PASS_THROUGH}): o cliente paga pela distância, sempre pela <b>maior</b> tabela entre as
 * associações que podem levar o pedido, e o entregador recebe esse valor inteiro. Assim nenhum entregador recebe
 * menos que a própria tabela. Quem pode levar:
 * <ul>
 *   <li>só parceiras: as associações parceiras (com a tabela especial, se houver);</li>
 *   <li>qualquer entregador (ou fixos com volta ao modo livre): todas as associações ativas, e nas parceiras
 *       vale a tabela especial.</li>
 * </ul>
 * Na vitrine aparece "a partir de" com o menor valor possível: a maior base entre essas tabelas.
 */
@Service
@Transactional(readOnly = true)
public class DeliveryFeeQuoteService {

    @Autowired
    private RestaurantPartnershipRepository partnershipRepository;

    @Autowired
    private OrganizationRepository organizationRepository;

    @Autowired
    private GeocodingService geocodingService;

    /** Distância e taxa do cliente para um endereço de entrega (com as coordenadas usadas, se houver) */
    public record Quote(Double latitude, Double longitude, Double distanceKm, BigDecimal fee, boolean byDistance) {
    }

    public Quote quote(Restaurant restaurant, Double latitude, Double longitude) {
        Double km = distanceKm(restaurant, latitude, longitude);
        return new Quote(latitude, longitude, km, customerFee(restaurant, km), restaurant.passesDeliveryFee());
    }

    /**
     * Taxa para um endereço digitado: sem coordenadas, localiza o endereço no mapa. Se não achar, a loja que repassa
     * cobra o valor "a partir de" (e o entregador recebe esse valor inteiro).
     */
    public Quote quote(Restaurant restaurant, GeocodingService.AddressQuery address, Double latitude, Double longitude) {
        GeocodingService.Coordinates point = locate(address, latitude, longitude);
        return point != null
                ? quote(restaurant, point.latitude(), point.longitude())
                : quote(restaurant, null, null);
    }

    /** As coordenadas informadas ou, sem elas, as do endereço no mapa (null se não achar) */
    public GeocodingService.Coordinates locate(GeocodingService.AddressQuery address, Double latitude, Double longitude) {
        if (latitude != null && longitude != null) {
            return new GeocodingService.Coordinates(latitude, longitude);
        }
        return address != null ? geocodingService.locate(address).orElse(null) : null;
    }

    /** Taxa do cliente para a distância (sem distância conhecida, o valor "a partir de") */
    public BigDecimal customerFee(Restaurant restaurant, Double distanceKm) {
        return restaurant.passesDeliveryFee() ? passThroughFee(restaurant, distanceKm) : fixedFee(restaurant);
    }

    /** Quanto o cliente pagaria se a loja repassasse a taxa (simulação no painel da loja) */
    public BigDecimal passThroughFee(Restaurant restaurant, Double distanceKm) {
        return highest(referenceRates(restaurant, activeOrganizations(), agreedRates(List.of(restaurant.getId()))
                .getOrDefault(restaurant.getId(), Map.of())), distanceKm, restaurant);
    }

    /** Valor mostrado na vitrine: taxa fixa ou "a partir de", para várias lojas de uma vez */
    public Map<Long, BigDecimal> shownFees(Collection<Restaurant> restaurants) {
        List<Restaurant> passing = restaurants.stream().filter(Restaurant::passesDeliveryFee).toList();
        Map<Long, BigDecimal> fees = new HashMap<>();
        restaurants.forEach(r -> fees.put(r.getId(), fixedFee(r)));
        if (passing.isEmpty()) {
            return fees;
        }

        List<Organization> organizations = activeOrganizations();
        Map<Long, Map<Long, DeliveryRate>> agreed = agreedRates(passing.stream().map(Restaurant::getId).toList());
        for (Restaurant restaurant : passing) {
            fees.put(restaurant.getId(), highest(referenceRates(restaurant, organizations,
                    agreed.getOrDefault(restaurant.getId(), Map.of())), null, restaurant));
        }
        return fees;
    }

    public BigDecimal shownFee(Restaurant restaurant) {
        return shownFees(List.of(restaurant)).get(restaurant.getId());
    }

    /** Distância em linha reta da loja até o endereço (a mesma do despacho) */
    public static Double distanceKm(Restaurant restaurant, Double latitude, Double longitude) {
        if (restaurant.getLatitude() == null || restaurant.getLongitude() == null
                || latitude == null || longitude == null) {
            return null;
        }
        double km = GeoUtils.haversineKm(restaurant.getLatitude().doubleValue(), restaurant.getLongitude().doubleValue(),
                latitude, longitude);
        return BigDecimal.valueOf(km).setScale(2, RoundingMode.HALF_UP).doubleValue();
    }

    // ============= Auxiliares =============

    static List<DeliveryRate> referenceRates(Restaurant restaurant, List<Organization> organizations,
                                             Map<Long, DeliveryRate> agreed) {
        if (restaurant.getCourierPolicy() == CourierPolicy.PARTNERS_ONLY) {
            return agreed.values().stream().filter(DeliveryRate::isConfigured).toList();
        }
        return organizations.stream()
                .map(org -> agreed.getOrDefault(org.getId(), org.getDeliveryRate()))
                .filter(rate -> rate != null && rate.isConfigured())
                .toList();
    }

    /** O maior valor entre as tabelas; sem nenhuma tabela, a taxa fixa da loja */
    static BigDecimal highest(List<DeliveryRate> rates, Double distanceKm, Restaurant restaurant) {
        return rates.stream()
                .map(rate -> DeliveryRateCalculator.courierFee(rate, distanceKm))
                .max(BigDecimal::compareTo)
                .orElse(fixedFee(restaurant));
    }

    private static BigDecimal fixedFee(Restaurant restaurant) {
        return restaurant.getDeliveryFee() != null ? restaurant.getDeliveryFee() : BigDecimal.ZERO;
    }

    private List<Organization> activeOrganizations() {
        return organizationRepository.findByStatusOrderByTradingNameAsc(OrganizationStatus.ACTIVE);
    }

    /** Tabela efetiva de cada parceria ativa, por loja e associação */
    private Map<Long, Map<Long, DeliveryRate>> agreedRates(Collection<Long> restaurantIds) {
        return partnershipRepository.findActiveByRestaurantIds(restaurantIds).stream()
                .collect(Collectors.groupingBy(p -> p.getRestaurant().getId(),
                        Collectors.toMap(p -> p.getOrganization().getId(), RestaurantPartnership::getEffectiveRate,
                                (a, b) -> a)));
    }
}
