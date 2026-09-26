package com.openbag.modules.order.service;

import com.openbag.exception.BadRequestException;
import com.openbag.modules.combo.entity.Combo;
import com.openbag.modules.order.dto.CreateOrderRequest;
import com.openbag.modules.product.entity.CustomizationGroup;
import com.openbag.modules.product.entity.CustomizationOption;
import com.openbag.modules.product.entity.Product;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.*;

/**
 * Calcula o preço de cada linha do pedido a partir do cardápio e valida disponibilidade e complementos.
 * Não acessa o banco: recebe os itens e combos já carregados do restaurante.
 */
@Component
public class OrderCalculator {

    public record PricedOption(CustomizationOption option, String groupName, String optionName, BigDecimal price) {
    }

    public record PricedLine(Product product, Combo combo, String name, int quantity, BigDecimal unitPrice,
                             BigDecimal totalPrice, String notes, List<PricedOption> options) {
    }

    /**
     * @param products itens do restaurante disponíveis para venda, por id
     * @param combos   combos do restaurante disponíveis para venda, por id
     */
    public List<PricedLine> price(List<CreateOrderRequest.ItemRequest> items,
                                  Map<Long, Product> products,
                                  Map<Long, Combo> combos) {
        List<PricedLine> lines = new ArrayList<>();
        for (CreateOrderRequest.ItemRequest item : items) {
            boolean isProduct = item.getProductId() != null;
            if (isProduct == (item.getComboId() != null)) {
                throw new BadRequestException("Cada item do pedido deve ser um produto ou um combo");
            }
            lines.add(isProduct ? priceProduct(item, products) : priceCombo(item, combos));
        }
        return lines;
    }

    public BigDecimal subtotal(List<PricedLine> lines) {
        return lines.stream().map(PricedLine::totalPrice).reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private PricedLine priceProduct(CreateOrderRequest.ItemRequest item, Map<Long, Product> products) {
        Product product = products.get(item.getProductId());
        if (product == null) {
            throw new BadRequestException("Um dos itens do carrinho não está mais disponível. Atualize o carrinho.");
        }

        List<Long> optionIds = item.getOptionIds() != null ? item.getOptionIds() : List.of();
        if (new HashSet<>(optionIds).size() != optionIds.size()) {
            throw new BadRequestException("Complemento repetido em \"" + product.getName() + "\"");
        }

        Map<Long, CustomizationOption> optionsById = new HashMap<>();
        Map<Long, CustomizationGroup> groupOfOption = new HashMap<>();
        for (CustomizationGroup group : product.getCustomizationGroups()) {
            for (CustomizationOption option : group.getOptions()) {
                optionsById.put(option.getId(), option);
                groupOfOption.put(option.getId(), group);
            }
        }

        List<PricedOption> chosen = new ArrayList<>();
        Map<Long, Integer> countByGroup = new HashMap<>();
        for (Long optionId : optionIds) {
            CustomizationOption option = optionsById.get(optionId);
            if (option == null) {
                throw new BadRequestException("Complemento inválido em \"" + product.getName() + "\". Atualize o carrinho.");
            }
            if (!option.isAvailable()) {
                throw new BadRequestException("\"" + option.getName() + "\" não está disponível no momento");
            }
            CustomizationGroup group = groupOfOption.get(optionId);
            countByGroup.merge(group.getId(), 1, Integer::sum);
            chosen.add(new PricedOption(option, group.getName(), option.getName(), option.getPriceModifier()));
        }

        for (CustomizationGroup group : product.getCustomizationGroups()) {
            int count = countByGroup.getOrDefault(group.getId(), 0);
            int min = group.getMinSelections() != null ? group.getMinSelections() : 0;
            int max = group.getMaxSelections() != null ? group.getMaxSelections() : 1;
            if (count < min) {
                throw new BadRequestException("Escolha " + (min == 1 ? "uma opção" : "pelo menos " + min + " opções")
                        + " em \"" + group.getName() + "\" (" + product.getName() + ")");
            }
            if (count > max) {
                throw new BadRequestException("Escolha no máximo " + max + " em \"" + group.getName() + "\" (" + product.getName() + ")");
            }
        }

        BigDecimal unitPrice = chosen.stream()
                .map(PricedOption::price)
                .reduce(product.getCurrentPrice(), BigDecimal::add);
        return new PricedLine(product, null, product.getName(), item.getQuantity(), unitPrice,
                unitPrice.multiply(BigDecimal.valueOf(item.getQuantity())), trimToNull(item.getNotes()), chosen);
    }

    private PricedLine priceCombo(CreateOrderRequest.ItemRequest item, Map<Long, Combo> combos) {
        Combo combo = combos.get(item.getComboId());
        if (combo == null) {
            throw new BadRequestException("Um dos combos do carrinho não está mais disponível. Atualize o carrinho.");
        }
        if (item.getOptionIds() != null && !item.getOptionIds().isEmpty()) {
            throw new BadRequestException("Combos não aceitam complementos");
        }
        return new PricedLine(null, combo, combo.getName(), item.getQuantity(), combo.getPrice(),
                combo.getPrice().multiply(BigDecimal.valueOf(item.getQuantity())), trimToNull(item.getNotes()), List.of());
    }

    private String trimToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
