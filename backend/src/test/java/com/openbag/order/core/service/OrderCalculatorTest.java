package com.openbag.order.core.service;

import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.restaurant.combo.entity.Combo;
import com.openbag.order.core.dto.CreateOrderRequest.ItemRequest;
import com.openbag.restaurant.catalog.entity.CustomizationGroup;
import com.openbag.restaurant.catalog.entity.CustomizationOption;
import com.openbag.restaurant.catalog.entity.Product;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class OrderCalculatorTest {

    private final OrderCalculator calculator = new OrderCalculator();
    private Product burger;
    private Combo combo;

    private static CustomizationGroup group(long id, String name, int min, int max, CustomizationOption... options) {
        CustomizationGroup group = new CustomizationGroup();
        group.setId(id);
        group.setName(name);
        group.setMinSelections(min);
        group.setMaxSelections(max);
        for (CustomizationOption option : options) {
            option.setCustomizationGroup(group);
            group.getOptions().add(option);
        }
        return group;
    }

    private static CustomizationOption option(long id, String name, String price) {
        CustomizationOption option = new CustomizationOption();
        option.setId(id);
        option.setName(name);
        option.setPriceModifier(new BigDecimal(price));
        return option;
    }

    @BeforeEach
    void setUp() {
        burger = new Product();
        burger.setId(1L);
        burger.setName("X-Burger");
        burger.setPrice(new BigDecimal("32.90"));
        burger.setPromotionalPrice(new BigDecimal("27.90"));
        burger.getCustomizationGroups().add(group(10, "Ponto da carne", 1, 1,
                option(100, "Mal passada", "0"), option(101, "Ao ponto", "0")));
        burger.getCustomizationGroups().add(group(11, "Adicionais", 0, 2,
                option(110, "Bacon", "6.00"), option(111, "Ovo", "3.00"), option(112, "Cheddar", "4.00")));

        combo = new Combo();
        combo.setId(5L);
        combo.setName("Combo Burger + Refri");
        combo.setPrice(new BigDecimal("32.00"));
    }

    private List<OrderCalculator.PricedLine> price(ItemRequest... items) {
        return calculator.price(List.of(items), Map.of(1L, burger), Map.of(5L, combo));
    }

    @Test
    void usesPromotionalPricePlusOptionsTimesQuantity() {
        var lines = price(new ItemRequest(1L, null, 2, " sem cebola ", List.of(101L, 110L, 111L)));

        var line = lines.get(0);
        assertThat(line.unitPrice()).isEqualByComparingTo("36.90"); // 27,90 + 6 + 3
        assertThat(line.totalPrice()).isEqualByComparingTo("73.80");
        assertThat(line.notes()).isEqualTo("sem cebola");
        assertThat(line.options()).extracting(OrderCalculator.PricedOption::optionName).containsExactly("Ao ponto", "Bacon", "Ovo");
        assertThat(line.options()).extracting(OrderCalculator.PricedOption::groupName).contains("Ponto da carne", "Adicionais");
    }

    @Test
    void comboUsesComboPriceAndSubtotalSumsLines() {
        var lines = price(new ItemRequest(1L, null, 1, null, List.of(100L)), new ItemRequest(null, 5L, 3, null, null));
        assertThat(lines.get(1).totalPrice()).isEqualByComparingTo("96.00");
        assertThat(calculator.subtotal(lines)).isEqualByComparingTo("123.90");
    }

    @Test
    void requiredGroupMustBeAnswered() {
        assertThatThrownBy(() -> price(new ItemRequest(1L, null, 1, null, List.of(110L))))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("Ponto da carne");
    }

    @Test
    void groupMaximumIsEnforced() {
        assertThatThrownBy(() -> price(new ItemRequest(1L, null, 1, null, List.of(100L, 110L, 111L, 112L))))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("no máximo 2");
    }

    @Test
    void optionFromAnotherItemOrUnavailableIsRejected() {
        assertThatThrownBy(() -> price(new ItemRequest(1L, null, 1, null, List.of(100L, 999L))))
                .isInstanceOf(BadRequestException.class);

        burger.getCustomizationGroups().get(1).getOptions().get(0).setAvailable(false);
        assertThatThrownBy(() -> price(new ItemRequest(1L, null, 1, null, List.of(100L, 110L))))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("Bacon");
    }

    @Test
    void duplicatedOptionIsRejected() {
        assertThatThrownBy(() -> price(new ItemRequest(1L, null, 1, null, List.of(100L, 110L, 110L))))
                .isInstanceOf(BadRequestException.class);
    }

    @Test
    void unavailableItemOrComboIsRejected() {
        assertThatThrownBy(() -> price(new ItemRequest(2L, null, 1, null, null))).isInstanceOf(BadRequestException.class);
        assertThatThrownBy(() -> price(new ItemRequest(null, 6L, 1, null, null))).isInstanceOf(BadRequestException.class);
    }

    @Test
    void itemMustBeProductOrComboButNotBoth() {
        assertThatThrownBy(() -> price(new ItemRequest(1L, 5L, 1, null, null))).isInstanceOf(BadRequestException.class);
        assertThatThrownBy(() -> price(new ItemRequest(null, null, 1, null, null))).isInstanceOf(BadRequestException.class);
    }

    @Test
    void comboDoesNotAcceptOptions() {
        assertThatThrownBy(() -> price(new ItemRequest(null, 5L, 1, null, List.of(110L)))).isInstanceOf(BadRequestException.class);
    }
}
