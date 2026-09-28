package com.openbag.modules.delivery.service;

import com.openbag.enums.CourierPolicy;
import com.openbag.enums.DeliveryFeeMode;
import com.openbag.enums.OrganizationStatus;
import com.openbag.enums.PartnershipStatus;
import com.openbag.modules.delivery.entity.RestaurantPartnership;
import com.openbag.modules.delivery.repository.RestaurantPartnershipRepository;
import com.openbag.modules.organization.entity.DeliveryRate;
import com.openbag.modules.organization.entity.Organization;
import com.openbag.modules.organization.repository.OrganizationRepository;
import com.openbag.modules.restaurant.entity.Restaurant;
import com.openbag.modules.shared.service.GeocodingService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DeliveryFeeQuoteServiceTest {

    @Mock
    private RestaurantPartnershipRepository partnershipRepository;

    @Mock
    private OrganizationRepository organizationRepository;

    @Mock
    private GeocodingService geocodingService;

    @InjectMocks
    private DeliveryFeeQuoteService service;

    private Restaurant restaurant;
    private Organization centro;
    private Organization norte;

    @BeforeEach
    void setUp() {
        restaurant = new Restaurant();
        restaurant.setId(1L);
        restaurant.setDeliveryFee(new BigDecimal("6.00"));
        restaurant.setDeliveryFeeMode(DeliveryFeeMode.PASS_THROUGH);

        // O exemplo do usuário: R$ 10 até 5 km e R$ 1 por km acima
        centro = organization(10L, "10.00", "5", "1.00");
        norte = organization(20L, "9.00", "3", "1.50");

        lenient().when(organizationRepository.findByStatusOrderByTradingNameAsc(OrganizationStatus.ACTIVE))
                .thenReturn(List.of(centro, norte));
        lenient().when(partnershipRepository.findActiveByRestaurantIds(any())).thenReturn(List.of());
    }

    private static Organization organization(Long id, String base, String km, String extra) {
        Organization organization = new Organization();
        organization.setId(id);
        organization.setStatus(OrganizationStatus.ACTIVE);
        organization.setDeliveryRate(new DeliveryRate(new BigDecimal(base), new BigDecimal(km), new BigDecimal(extra)));
        return organization;
    }

    private RestaurantPartnership partnership(Organization organization, DeliveryRate agreed) {
        RestaurantPartnership partnership = new RestaurantPartnership();
        partnership.setRestaurant(restaurant);
        partnership.setOrganization(organization);
        partnership.setStatus(PartnershipStatus.ACTIVE);
        partnership.setAgreedRate(agreed);
        return partnership;
    }

    @Test
    void eightKilometersWithTheTenPlusOnePerKmTableCostsThirteen() {
        restaurant.setCourierPolicy(CourierPolicy.PARTNERS_ONLY);
        lenient().when(partnershipRepository.findActiveByRestaurantIds(any()))
                .thenReturn(List.of(partnership(centro, null)));

        assertThat(service.customerFee(restaurant, 8.0)).isEqualByComparingTo("13.00");
        assertThat(service.customerFee(restaurant, 4.0)).isEqualByComparingTo("10.00");
    }

    @Test
    void customerAlwaysPaysTheHighestTableAmongWhoCanDeliver() {
        // Aberto a qualquer entregador: vale a maior entre todas as associações
        // 8 km: centro = 10 + 3 × 1 = 13; norte = 9 + 5 × 1,50 = 16,50
        assertThat(service.customerFee(restaurant, 8.0)).isEqualByComparingTo("16.50");
        // 2 km: centro = 10; norte = 9
        assertThat(service.customerFee(restaurant, 2.0)).isEqualByComparingTo("10.00");
    }

    @Test
    void agreedRateOfAPartnerReplacesItsDefaultTable() {
        DeliveryRate special = new DeliveryRate(new BigDecimal("8.00"), new BigDecimal("5"), new BigDecimal("0.50"));
        lenient().when(partnershipRepository.findActiveByRestaurantIds(any()))
                .thenReturn(List.of(partnership(norte, special)));

        // 8 km: centro = 13; norte com a tabela especial = 8 + 3 × 0,50 = 9,50
        assertThat(service.customerFee(restaurant, 8.0)).isEqualByComparingTo("13.00");
    }

    @Test
    void storefrontShowsTheLowestPossibleValueAsFrom() {
        // "A partir de": a maior base entre as tabelas (o mínimo que o cliente pode pagar)
        Map<Long, BigDecimal> fees = service.shownFees(List.of(restaurant));

        assertThat(fees.get(1L)).isEqualByComparingTo("10.00");
    }

    @Test
    void storeThatAssumesTheFeeKeepsItsFixedFee() {
        restaurant.setDeliveryFeeMode(DeliveryFeeMode.ASSUME);

        assertThat(service.customerFee(restaurant, 8.0)).isEqualByComparingTo("6.00");
        assertThat(service.shownFees(List.of(restaurant)).get(1L)).isEqualByComparingTo("6.00");
        verifyNoInteractions(partnershipRepository);
    }

    @Test
    void withoutAnyTableTheFixedFeeIsUsed() {
        restaurant.setCourierPolicy(CourierPolicy.PARTNERS_ONLY);

        assertThat(service.customerFee(restaurant, 8.0)).isEqualByComparingTo("6.00");
    }

    @Test
    void quoteMeasuresTheStraightLineDistanceFromTheStore() {
        restaurant.setLatitude(new BigDecimal("-23.5505"));
        restaurant.setLongitude(new BigDecimal("-46.6333"));

        DeliveryFeeQuoteService.Quote quote = service.quote(restaurant, -23.5505, -46.5553);

        assertThat(quote.distanceKm()).isBetween(7.9, 8.0);
        assertThat(quote.byDistance()).isTrue();
        assertThat(quote.fee()).isGreaterThan(new BigDecimal("13.00"));
    }

    @Test
    void typedAddressIsLocatedOnTheMapAndUnknownAddressPaysTheFromValue() {
        restaurant.setLatitude(new BigDecimal("-23.5505"));
        restaurant.setLongitude(new BigDecimal("-46.6333"));
        var found = new GeocodingService.AddressQuery("Rua A", "10", "Centro", "São Paulo", "SP", null);
        var unknown = new GeocodingService.AddressQuery("Rua Inexistente", "1", "Centro", "São Paulo", "SP", null);
        when(geocodingService.locate(found)).thenReturn(Optional.of(new GeocodingService.Coordinates(-23.5505, -46.5553)));
        when(geocodingService.locate(unknown)).thenReturn(Optional.empty());

        DeliveryFeeQuoteService.Quote located = service.quote(restaurant, found, null, null);
        DeliveryFeeQuoteService.Quote notLocated = service.quote(restaurant, unknown, null, null);

        assertThat(located.latitude()).isEqualTo(-23.5505);
        assertThat(located.distanceKm()).isBetween(7.9, 8.0);
        assertThat(notLocated.distanceKm()).isNull();
        assertThat(notLocated.fee()).isEqualByComparingTo("10.00");
    }
}
