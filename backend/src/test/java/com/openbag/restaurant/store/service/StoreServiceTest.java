package com.openbag.restaurant.store.service;

import com.openbag.restaurant.store.entity.AcceptanceMode;
import com.openbag.restaurant.store.entity.RestaurantThemePreset;
import com.openbag.platform.web.exception.ResourceNotFoundException;
import com.openbag.restaurant.catalog.entity.Category;
import com.openbag.restaurant.catalog.repository.CategoryRepository;
import com.openbag.delivery.dispatch.service.RestaurantDeliveryService;
import com.openbag.restaurant.store.dto.AppearanceRequest;
import com.openbag.restaurant.store.dto.RestaurantProfileRequest;
import com.openbag.restaurant.store.dto.StoreAddressRequest;
import com.openbag.restaurant.store.dto.StoreDTO;
import com.openbag.restaurant.store.dto.StoreSettingsRequest;
import com.openbag.restaurant.store.entity.LayoutConfig;
import com.openbag.restaurant.store.entity.Restaurant;
import com.openbag.restaurant.store.repository.RestaurantRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class StoreServiceTest {

    @Mock private RestaurantRepository restaurantRepository;
    @Mock private RestaurantDeliveryService restaurantDeliveryService;
    @Mock private CategoryRepository categoryRepository;
    @Spy private Clock clock = Clock.fixed(Instant.parse("2026-09-21T15:00:00Z"), ZoneId.of("America/Sao_Paulo"));

    @InjectMocks
    private StoreService storeService;

    private Restaurant restaurant;

    @BeforeEach
    void setUp() {
        restaurant = new Restaurant();
        restaurant.setId(1L);
        restaurant.setName("Burger da Vila");
        restaurant.setSlug("burger-da-vila");
        when(restaurantRepository.findById(1L)).thenReturn(Optional.of(restaurant));
        lenient().when(restaurantRepository.save(any(Restaurant.class))).thenAnswer(inv -> inv.getArgument(0));
    }

    @Test
    void createsLayoutConfigWhenMissing() {
        StoreDTO dto = storeService.updateAppearance(1L,
                new AppearanceRequest(RestaurantThemePreset.SUNSET_ORANGE, "#ff0000", "  Sabor de verdade  "));

        LayoutConfig layout = restaurant.getLayoutConfig();
        assertThat(layout).isNotNull();
        assertThat(layout.getRestaurant()).isSameAs(restaurant);
        assertThat(dto.getThemePreset()).isEqualTo(RestaurantThemePreset.SUNSET_ORANGE);
        assertThat(dto.getBrandColor()).isEqualTo("#FF0000");
        assertThat(dto.getSlogan()).isEqualTo("Sabor de verdade");
        // Colunas antigas (NOT NULL) seguem preenchidas com a cor efetiva
        assertThat(layout.getPrimaryColor()).isEqualTo("#FF0000");
        assertThat(layout.getSecondaryColor()).isEqualTo("#FF0000");
    }

    @Test
    void clearingBrandColorFallsBackToThemeColor() {
        storeService.updateAppearance(1L, new AppearanceRequest(RestaurantThemePreset.OCEAN_BLUE, "#123456", null));

        StoreDTO dto = storeService.updateAppearance(1L, new AppearanceRequest(RestaurantThemePreset.OCEAN_BLUE, null, " "));

        assertThat(dto.getBrandColor()).isNull();
        assertThat(dto.getSlogan()).isNull();
        assertThat(restaurant.getLayoutConfig().getPrimaryColor()).isEqualTo("#008CC2");
    }

    @Test
    void restaurantWithoutLayoutUsesDefaultTheme() {
        assertThat(storeService.getStore(1L).getThemePreset()).isEqualTo(RestaurantThemePreset.FRESH_GREEN);
    }

    private static Category category(long id, String name) {
        Category category = new Category();
        category.setId(id);
        category.setName(name);
        return category;
    }

    @Test
    void updateProfileKeepsSlugAndReplacesCategories() {
        restaurant.getCategories().add(category(9L, "Pizza"));
        List<Category> chosen = List.of(category(1L, "Hamburguer"), category(2L, "Lanches"));
        when(categoryRepository.findAllByIdOrThrow(List.of(1L, 2L))).thenReturn(chosen);

        StoreDTO dto = storeService.updateProfile(1L,
                new RestaurantProfileRequest("  Burger da Praça ", " ", "11999998888", List.of(1L, 2L), "$$"));

        assertThat(dto.getName()).isEqualTo("Burger da Praça");
        assertThat(dto.getSlug()).isEqualTo("burger-da-vila");
        assertThat(dto.getDescription()).isNull();
        assertThat(dto.getPhoneNumber()).isEqualTo("11999998888");
        assertThat(dto.getPriceRange()).isEqualTo("$$");
        assertThat(dto.getCategoryIds()).containsExactly(1L, 2L);
        assertThat(dto.getCategories()).containsExactly("Hamburguer", "Lanches");
    }

    @Test
    void updateProfileRejectsUnknownCategory() {
        when(categoryRepository.findAllByIdOrThrow(List.of(99L)))
                .thenThrow(new ResourceNotFoundException("Uma ou mais categorias não foram encontradas"));

        assertThatThrownBy(() -> storeService.updateProfile(1L,
                new RestaurantProfileRequest("Burger", null, "11999998888", List.of(99L), null)))
                .isInstanceOf(ResourceNotFoundException.class);
        assertThat(restaurant.getName()).isEqualTo("Burger da Vila");
    }

    @Test
    void updateAddressCreatesThenUpdatesTheSameAddress() {
        StoreDTO created = storeService.updateAddress(1L, new StoreAddressRequest("01001-000", "Praça da Sé", "100",
                " ", "Sé", "São Paulo", "sp", new BigDecimal("-23.5503"), new BigDecimal("-46.6339")));

        var address = restaurant.getAddress();
        assertThat(address).isNotNull();
        assertThat(created.getAddress().getState()).isEqualTo("SP");
        assertThat(created.getAddress().getComplement()).isNull();
        assertThat(restaurant.getLatitude()).isEqualByComparingTo("-23.5503");

        storeService.updateAddress(1L, new StoreAddressRequest("01310-100", "Av. Paulista", "1000",
                "Loja 2", "Bela Vista", "São Paulo", "SP", null, null));

        assertThat(restaurant.getAddress()).isSameAs(address);
        assertThat(address.getStreet()).isEqualTo("Av. Paulista");
        assertThat(address.getLatitude()).isNull();
        assertThat(restaurant.getLatitude()).isNull();
    }

    @Test
    void updateSettingsKeepsPriceRange() {
        restaurant.setPriceRange("$$$");

        StoreDTO dto = storeService.updateSettings(1L, new StoreSettingsRequest(AcceptanceMode.AUTO, 8, 20,
                new BigDecimal("5.00"), new BigDecimal("20.00"), 30, 45, false));

        assertThat(dto.getPriceRange()).isEqualTo("$$$");
        assertThat(dto.getAcceptanceMode()).isEqualTo(AcceptanceMode.AUTO);
    }
}
