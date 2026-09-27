package com.openbag.modules.menu.service;

import com.openbag.exception.BadRequestException;
import com.openbag.exception.ResourceNotFoundException;
import com.openbag.modules.combo.entity.Combo;
import com.openbag.modules.combo.entity.ComboItem;
import com.openbag.modules.combo.repository.ComboRepository;
import com.openbag.modules.menu.dto.*;
import com.openbag.modules.menu.entity.MenuSection;
import com.openbag.modules.menu.repository.MenuSectionRepository;
import com.openbag.modules.product.entity.CustomizationGroup;
import com.openbag.modules.product.entity.CustomizationOption;
import com.openbag.modules.product.entity.Product;
import com.openbag.modules.product.repository.CustomizationGroupRepository;
import com.openbag.modules.product.repository.OrderItemCustomizationRepository;
import com.openbag.modules.product.repository.ProductRepository;
import com.openbag.modules.restaurant.entity.Restaurant;
import com.openbag.modules.restaurant.repository.RestaurantRepository;
import com.openbag.modules.shared.service.FileStorageService;
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
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class MenuServiceTest {

    private static final long RID = 1L;

    @Mock private MenuSectionRepository sectionRepository;
    @Mock private ProductRepository productRepository;
    @Mock private ComboRepository comboRepository;
    @Mock private CustomizationGroupRepository groupRepository;
    @Mock private OrderItemCustomizationRepository orderItemCustomizationRepository;
    @Mock private RestaurantRepository restaurantRepository;
    @Mock private FileStorageService fileStorageService;
    @Spy private Clock clock = Clock.fixed(Instant.parse("2026-09-21T15:00:00Z"), ZoneId.of("America/Sao_Paulo"));

    @InjectMocks
    private MenuService menuService;

    private Restaurant restaurant;
    private MenuSection section;

    @BeforeEach
    void setUp() {
        restaurant = new Restaurant();
        restaurant.setId(RID);
        section = new MenuSection();
        section.setId(10L);
        section.setRestaurant(restaurant);
        section.setName("Lanches");
        lenient().when(sectionRepository.findByIdAndRestaurantId(10L, RID)).thenReturn(Optional.of(section));
        lenient().when(productRepository.save(any(Product.class))).thenAnswer(inv -> inv.getArgument(0));
        lenient().when(groupRepository.save(any(CustomizationGroup.class))).thenAnswer(inv -> inv.getArgument(0));
    }

    private Product product(long id, String name) {
        Product product = new Product();
        product.setId(id);
        product.setName(name);
        product.setPrice(new BigDecimal("30.00"));
        product.setRestaurant(restaurant);
        product.setMenuSection(section);
        lenient().when(productRepository.findByIdAndRestaurantIdAndDeletedAtIsNull(id, RID)).thenReturn(Optional.of(product));
        return product;
    }

    @Test
    void newItemGoesToEndOfSectionAndStartsAvailable() {
        when(productRepository.findMaxPositionInSection(10L)).thenReturn(4);

        MenuItemDTO item = menuService.createItem(RID, new MenuItemRequest(10L, " X-Burger ", null,
                new BigDecimal("30.00"), new BigDecimal("25.00"), 15, null, null, null));

        assertThat(item.getName()).isEqualTo("X-Burger");
        assertThat(item.getPosition()).isEqualTo(5);
        assertThat(item.getCurrentPrice()).isEqualByComparingTo("25.00");
        assertThat(item.isAvailable()).isTrue();
        assertThat(item.isActive()).isTrue();
    }

    @Test
    void badgesAreTrimmedAndDeduplicated() {
        when(productRepository.findMaxPositionInSection(10L)).thenReturn(0);

        MenuItemDTO item = menuService.createItem(RID, new MenuItemRequest(10L, "X-Bacon", null,
                BigDecimal.TEN, null, null, List.of(" Especial ", "especial", "", "Picante"), null, null));

        assertThat(item.getBadges()).containsExactly("Especial", "Picante");
    }

    @Test
    void atMostTwoBadgesUpToTwentyCharacters() {
        assertThat(menuService.normalizeBadges(null)).isEmpty();
        assertThatThrownBy(() -> menuService.normalizeBadges(List.of("Novo", "Vegano", "Picante")))
                .isInstanceOf(BadRequestException.class);
        assertThatThrownBy(() -> menuService.normalizeBadges(List.of("Um selo comprido demais")))
                .isInstanceOf(BadRequestException.class);
        assertThatThrownBy(() -> menuService.normalizeBadges(List.of("A|B")))
                .isInstanceOf(BadRequestException.class);
    }

    @Test
    void sectionKeepsIcon() {
        when(sectionRepository.save(any(MenuSection.class))).thenAnswer(inv -> inv.getArgument(0));

        MenuSectionDTO dto = menuService.updateSection(RID, 10L, new MenuSectionRequest("Bebidas", null, "local_drink", null));

        assertThat(dto.getIcon()).isEqualTo("local_drink");
    }

    @Test
    void promotionalPriceMustBeLowerThanPrice() {
        assertThatThrownBy(() -> menuService.createItem(RID, new MenuItemRequest(10L, "X", null,
                new BigDecimal("30.00"), new BigDecimal("30.00"), null, null, null, null)))
                .isInstanceOf(BadRequestException.class);
    }

    @Test
    void sectionFromAnotherRestaurantIsNotFound() {
        when(sectionRepository.findByIdAndRestaurantId(99L, RID)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> menuService.createItem(RID, new MenuItemRequest(99L, "X", null,
                BigDecimal.TEN, null, null, null, null, null)))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void deletingItemIsLogicalAndHidesIt() {
        Product product = product(5L, "X-Burger");
        when(comboRepository.findByRestaurantIdAndDeletedAtIsNullOrderByPositionAscIdAsc(RID)).thenReturn(List.of());

        menuService.deleteItem(RID, 5L);

        assertThat(product.getDeletedAt()).isNotNull();
        assertThat(product.isActive()).isFalse();
        assertThat(product.isAvailable()).isFalse();
    }

    @Test
    void itemInsideComboCannotBeDeleted() {
        Product product = product(5L, "X-Burger");
        Combo combo = new Combo();
        combo.setName("Combo Família");
        ComboItem comboItem = new ComboItem();
        comboItem.setProduct(product);
        combo.getComboItems().add(comboItem);
        when(comboRepository.findByRestaurantIdAndDeletedAtIsNullOrderByPositionAscIdAsc(RID)).thenReturn(List.of(combo));

        assertThatThrownBy(() -> menuService.deleteItem(RID, 5L))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("Combo Família");
        assertThat(product.getDeletedAt()).isNull();
    }

    @Test
    void sectionWithItemsCannotBeDeleted() {
        when(productRepository.countByMenuSectionIdAndDeletedAtIsNull(10L)).thenReturn(2L);
        assertThatThrownBy(() -> menuService.deleteSection(RID, 10L)).isInstanceOf(BadRequestException.class);
        verify(sectionRepository, never()).delete(any());
    }

    @Test
    void reorderMustContainExactlyTheCurrentSections() {
        MenuSection other = new MenuSection();
        other.setId(11L);
        when(sectionRepository.findByRestaurantIdOrderByPositionAscIdAsc(RID)).thenReturn(List.of(section, other));

        assertThatThrownBy(() -> menuService.reorderSections(RID, List.of(11L)))
                .isInstanceOf(BadRequestException.class);

        menuService.reorderSections(RID, List.of(11L, 10L));
        assertThat(other.getPosition()).isZero();
        assertThat(section.getPosition()).isEqualTo(1);
    }

    @Test
    void customizationGroupIsRequiredWhenMinimumIsPositive() {
        product(5L, "X-Burger");
        CustomizationGroupRequest request = new CustomizationGroupRequest("Ponto da carne", 1, 1, List.of(
                new CustomizationGroupRequest.OptionRequest(null, "Mal passada", BigDecimal.ZERO, null),
                new CustomizationGroupRequest.OptionRequest(null, "Ao ponto", BigDecimal.ZERO, null)));

        CustomizationGroupDTO group = menuService.createGroup(RID, 5L, request);

        assertThat(group.isRequired()).isTrue();
        assertThat(group.getOptions()).extracting(CustomizationGroupDTO.Option::getName)
                .containsExactly("Mal passada", "Ao ponto");
    }

    @Test
    void customizationGroupLimitsAreValidated() {
        List<CustomizationGroupRequest.OptionRequest> oneOption = List.of(
                new CustomizationGroupRequest.OptionRequest(null, "Bacon", new BigDecimal("4.00"), null));

        assertThatThrownBy(() -> menuService.createGroup(RID, 5L, new CustomizationGroupRequest("Adicionais", 0, 2, oneOption)))
                .isInstanceOf(BadRequestException.class);
        assertThatThrownBy(() -> menuService.createGroup(RID, 5L, new CustomizationGroupRequest("Adicionais", 2, 1, oneOption)))
                .isInstanceOf(BadRequestException.class);
    }

    @Test
    void optionAlreadyUsedInOrdersCannotBeRemoved() {
        Product product = product(5L, "X-Burger");
        CustomizationGroup group = new CustomizationGroup();
        group.setId(7L);
        group.setProduct(product);
        CustomizationOption bacon = new CustomizationOption();
        bacon.setId(70L);
        bacon.setName("Bacon");
        group.setOptions(new ArrayList<>(List.of(bacon)));
        when(groupRepository.findById(7L)).thenReturn(Optional.of(group));
        when(orderItemCustomizationRepository.existsByCustomizationOptionIdIn(List.of(70L))).thenReturn(true);

        CustomizationGroupRequest request = new CustomizationGroupRequest("Adicionais", 0, 1, List.of(
                new CustomizationGroupRequest.OptionRequest(null, "Cheddar", new BigDecimal("3.00"), null)));

        assertThatThrownBy(() -> menuService.updateGroup(RID, 7L, request)).isInstanceOf(BadRequestException.class);
    }
}
