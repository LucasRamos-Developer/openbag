package com.openbag.modules.delivery.service;

import com.openbag.enums.CourierPolicy;
import com.openbag.enums.DeliveryFeeMode;
import com.openbag.enums.OrganizationStatus;
import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.platform.web.exception.ConflictException;
import com.openbag.modules.delivery.dto.RestaurantDeliverySettingsRequest;
import com.openbag.modules.delivery.entity.RestaurantPartnership;
import com.openbag.modules.delivery.repository.RestaurantCourierLinkRepository;
import com.openbag.modules.delivery.repository.RestaurantPartnershipRepository;
import com.openbag.modules.organization.entity.DeliveryRate;
import com.openbag.modules.organization.entity.Organization;
import com.openbag.restaurant.store.entity.Restaurant;
import com.openbag.restaurant.store.repository.RestaurantRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class RestaurantDeliveryServiceTest {

    @Mock
    private RestaurantRepository restaurantRepository;

    @Mock
    private RestaurantPartnershipRepository partnershipRepository;

    @Mock
    private RestaurantCourierLinkRepository linkRepository;

    @Mock
    private DeliveryFeeQuoteService deliveryFeeQuoteService;

    @InjectMocks
    private RestaurantDeliveryService service;

    private Restaurant restaurant;
    private Organization expensive;

    @BeforeEach
    void setUp() {
        restaurant = new Restaurant();
        restaurant.setId(1L);
        restaurant.setDeliveryFee(new BigDecimal("6.00"));

        expensive = new Organization();
        expensive.setId(10L);
        expensive.setTradingName("Coop Cara");
        expensive.setStatus(OrganizationStatus.ACTIVE);
        expensive.setDeliveryRate(new DeliveryRate(new BigDecimal("8.00"), new BigDecimal("3"), BigDecimal.ONE));

        lenient().when(restaurantRepository.findById(1L)).thenReturn(Optional.of(restaurant));
        lenient().when(restaurantRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
    }

    @Test
    void agreedRateCountsWhenCheckingPartnersAgainstTheFee() {
        // A tabela padrão (R$ 8,00) passa da taxa, mas a combinada com a loja (R$ 6,00) cabe
        RestaurantPartnership partnership = new RestaurantPartnership();
        partnership.setOrganization(expensive);
        partnership.setAgreedRate(new DeliveryRate(new BigDecimal("6.00"), new BigDecimal("3"), BigDecimal.ONE));
        restaurant.setCoversDeliveryDifference(true);
        when(partnershipRepository.findActiveByRestaurant(1L)).thenReturn(List.of(partnership));

        RestaurantDeliverySettingsRequest request = new RestaurantDeliverySettingsRequest();
        request.setCourierPolicy(CourierPolicy.PARTNERS_ONLY);
        request.setCoversDeliveryDifference(false);
        service.updateSettings(1L, request);

        assertThat(restaurant.isCoversDeliveryDifference()).isFalse();
        assertThat(restaurant.getCourierPolicy()).isEqualTo(CourierPolicy.PARTNERS_ONLY);
    }

    @Test
    void cannotStopCoveringWhileExpensivePartnerExists() {
        restaurant.setCoversDeliveryDifference(true);
        RestaurantPartnership partnership = new RestaurantPartnership();
        partnership.setOrganization(expensive);
        when(partnershipRepository.findActiveByRestaurant(1L)).thenReturn(List.of(partnership));

        RestaurantDeliverySettingsRequest request = new RestaurantDeliverySettingsRequest();
        request.setCourierPolicy(CourierPolicy.OPEN);
        request.setCoversDeliveryDifference(false);

        assertThatThrownBy(() -> service.updateSettings(1L, request)).isInstanceOf(ConflictException.class);
        assertThat(restaurant.isCoversDeliveryDifference()).isTrue();
    }

    @Test
    void partnersOnlyRequiresAtLeastOnePartner() {
        when(partnershipRepository.findActiveByRestaurant(1L)).thenReturn(List.of());
        RestaurantDeliverySettingsRequest request = new RestaurantDeliverySettingsRequest();
        request.setCourierPolicy(CourierPolicy.PARTNERS_ONLY);

        assertThatThrownBy(() -> service.updateSettings(1L, request)).isInstanceOf(BadRequestException.class);
    }

    @Test
    void loweringDeliveryFeeBelowPartnerBaseIsBlocked() {
        RestaurantPartnership partnership = new RestaurantPartnership();
        Organization cheap = new Organization();
        cheap.setTradingName("Coop");
        cheap.setDeliveryRate(new DeliveryRate(new BigDecimal("5.00"), new BigDecimal("3"), BigDecimal.ZERO));
        partnership.setOrganization(cheap);
        when(partnershipRepository.findActiveByRestaurant(1L)).thenReturn(List.of(partnership));

        service.assertDeliveryFeeCovered(restaurant, new BigDecimal("5.00"));
        assertThatThrownBy(() -> service.assertDeliveryFeeCovered(restaurant, new BigDecimal("4.99")))
                .isInstanceOf(ConflictException.class);
    }

    @Test
    void passingTheFeeToTheCustomerNeedsNoCoverForExpensivePartners() {
        RestaurantPartnership partnership = new RestaurantPartnership();
        partnership.setOrganization(expensive);
        partnership.setRestaurant(restaurant);
        when(partnershipRepository.findActiveByRestaurant(1L)).thenReturn(List.of(partnership));

        RestaurantDeliverySettingsRequest request = new RestaurantDeliverySettingsRequest();
        request.setCourierPolicy(CourierPolicy.PARTNERS_ONLY);
        request.setDeliveryFeeMode(DeliveryFeeMode.PASS_THROUGH);
        service.updateSettings(1L, request);

        assertThat(restaurant.passesDeliveryFee()).isTrue();
        // E a taxa fixa pode baixar à vontade: ela não é cobrada
        service.assertDeliveryFeeCovered(restaurant, BigDecimal.ZERO);
    }
}
