package com.openbag.restaurant.menu.service;

import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.platform.web.exception.ResourceNotFoundException;
import com.openbag.restaurant.combo.entity.Combo;
import com.openbag.restaurant.combo.entity.ComboItem;
import com.openbag.restaurant.combo.repository.ComboRepository;
import com.openbag.restaurant.menu.dto.ComboDTO;
import com.openbag.restaurant.menu.dto.ComboRequest;
import com.openbag.restaurant.menu.dto.CustomizationGroupDTO;
import com.openbag.restaurant.menu.dto.CustomizationGroupRequest;
import com.openbag.restaurant.menu.dto.MenuDTO;
import com.openbag.restaurant.menu.dto.MenuItemDTO;
import com.openbag.restaurant.menu.dto.MenuItemRequest;
import com.openbag.restaurant.menu.dto.MenuSectionDTO;
import com.openbag.restaurant.menu.dto.MenuSectionRequest;
import com.openbag.restaurant.menu.entity.MenuSection;
import com.openbag.restaurant.menu.repository.MenuSectionRepository;
import com.openbag.restaurant.catalog.entity.CustomizationGroup;
import com.openbag.restaurant.catalog.entity.CustomizationOption;
import com.openbag.restaurant.catalog.entity.Product;
import com.openbag.restaurant.catalog.entity.ProductType;
import com.openbag.restaurant.catalog.repository.CustomizationGroupRepository;
import com.openbag.modules.product.repository.OrderItemCustomizationRepository;
import com.openbag.restaurant.catalog.repository.ProductRepository;
import com.openbag.restaurant.store.entity.Restaurant;
import com.openbag.restaurant.store.repository.RestaurantRepository;
import com.openbag.platform.util.StringListConverter;
import com.openbag.platform.files.FileStorageService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDateTime;
import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Cardápio do restaurante: seções, itens, complementos e combos.
 * Toda operação recebe o restaurante do path e só enxerga registros dele.
 */
@Service
@Transactional
@Slf4j
public class MenuService {

    private static final String IMAGE_FOLDER = "products";
    static final int MAX_BADGES = 2;
    static final int MAX_BADGE_LENGTH = 20;

    @Autowired
    private MenuSectionRepository sectionRepository;

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private ComboRepository comboRepository;

    @Autowired
    private CustomizationGroupRepository groupRepository;

    @Autowired
    private OrderItemCustomizationRepository orderItemCustomizationRepository;

    @Autowired
    private RestaurantRepository restaurantRepository;

    @Autowired
    private FileStorageService fileStorageService;

    @Autowired
    private Clock clock;

    // ============= Leitura =============

    /**
     * Cardápio completo na visão do dono: inclui seções e itens inativos, esgotados e itens sem seção
     */
    @Transactional(readOnly = true)
    public MenuDTO getOwnerMenu(Long restaurantId) {
        findRestaurant(restaurantId);
        return buildMenu(restaurantId, true);
    }

    /**
     * Monta o cardápio. Na visão pública ficam só seções ativas, com itens ativos e disponíveis.
     */
    @Transactional(readOnly = true)
    public MenuDTO buildMenu(Long restaurantId, boolean ownerView) {
        List<MenuSection> sections = sectionRepository.findByRestaurantIdOrderByPositionAscIdAsc(restaurantId);
        List<Product> products = productRepository.findByRestaurantIdAndDeletedAtIsNullOrderByPositionAscIdAsc(restaurantId);
        List<Combo> combos = comboRepository.findByRestaurantIdAndDeletedAtIsNullOrderByPositionAscIdAsc(restaurantId);

        Map<Long, List<MenuItemDTO>> itemsBySection = products.stream()
                .filter(p -> p.getMenuSection() != null)
                .filter(p -> ownerView || (p.isActive() && p.isAvailable()))
                .map(MenuItemDTO::from)
                .collect(Collectors.groupingBy(MenuItemDTO::getSectionId, LinkedHashMap::new, Collectors.toList()));

        Map<Long, List<ComboDTO>> combosBySection = combos.stream()
                .filter(c -> c.getMenuSection() != null)
                .filter(c -> ownerView || (c.isActive() && c.isAvailable()))
                .map(ComboDTO::from)
                .collect(Collectors.groupingBy(ComboDTO::getSectionId, LinkedHashMap::new, Collectors.toList()));

        List<MenuSectionDTO> sectionDTOs = sections.stream()
                .filter(s -> ownerView || s.isActive())
                .map(s -> MenuSectionDTO.from(s,
                        itemsBySection.getOrDefault(s.getId(), List.of()),
                        combosBySection.getOrDefault(s.getId(), List.of())))
                .filter(s -> ownerView || !s.getItems().isEmpty() || !s.getCombos().isEmpty())
                .toList();

        List<MenuItemDTO> unsectioned = ownerView
                ? products.stream().filter(p -> p.getMenuSection() == null).map(MenuItemDTO::from).toList()
                : List.of();

        return new MenuDTO(restaurantId, sectionDTOs, unsectioned);
    }

    // ============= Seções =============

    public MenuSectionDTO createSection(Long restaurantId, MenuSectionRequest request) {
        MenuSection section = new MenuSection();
        section.setRestaurant(findRestaurant(restaurantId));
        section.setName(request.getName().trim());
        section.setDescription(trimToNull(request.getDescription()));
        section.setIcon(trimToNull(request.getIcon()));
        section.setActive(request.getActive() == null || request.getActive());
        section.setPosition(sectionRepository.findMaxPosition(restaurantId) + 1);
        return MenuSectionDTO.from(sectionRepository.save(section), List.of(), List.of());
    }

    public MenuSectionDTO updateSection(Long restaurantId, Long sectionId, MenuSectionRequest request) {
        MenuSection section = findSection(restaurantId, sectionId);
        section.setName(request.getName().trim());
        section.setDescription(trimToNull(request.getDescription()));
        section.setIcon(trimToNull(request.getIcon()));
        if (request.getActive() != null) {
            section.setActive(request.getActive());
        }
        return MenuSectionDTO.from(sectionRepository.save(section), List.of(), List.of());
    }

    public void deleteSection(Long restaurantId, Long sectionId) {
        MenuSection section = findSection(restaurantId, sectionId);
        if (productRepository.countByMenuSectionIdAndDeletedAtIsNull(sectionId) > 0
                || comboRepository.countByMenuSectionIdAndDeletedAtIsNull(sectionId) > 0) {
            throw new BadRequestException("Mova ou exclua os itens desta seção antes de excluí-la");
        }
        productRepository.detachDeletedFromSection(sectionId);
        comboRepository.detachDeletedFromSection(sectionId);
        sectionRepository.delete(section);
    }

    public void reorderSections(Long restaurantId, List<Long> ids) {
        List<MenuSection> sections = sectionRepository.findByRestaurantIdOrderByPositionAscIdAsc(restaurantId);
        applyOrder(sections, ids, MenuSection::getId, MenuSection::setPosition);
        sectionRepository.saveAll(sections);
    }

    // ============= Itens =============

    public MenuItemDTO createItem(Long restaurantId, MenuItemRequest request) {
        validatePrices(request.getPrice(), request.getPromotionalPrice());
        MenuSection section = findSection(restaurantId, request.getSectionId());

        Product product = new Product();
        product.setRestaurant(section.getRestaurant());
        product.setMenuSection(section);
        product.setPosition(productRepository.findMaxPositionInSection(section.getId()) + 1);
        product.setProductType(ProductType.CUSTOM);
        applyItem(product, request);
        product.setAvailable(request.getAvailable() == null || request.getAvailable());
        product.setActive(request.getActive() == null || request.getActive());

        return MenuItemDTO.from(productRepository.save(product));
    }

    public MenuItemDTO updateItem(Long restaurantId, Long itemId, MenuItemRequest request) {
        validatePrices(request.getPrice(), request.getPromotionalPrice());
        Product product = findItem(restaurantId, itemId);

        MenuSection section = findSection(restaurantId, request.getSectionId());
        boolean sectionChanged = product.getMenuSection() == null
                || !product.getMenuSection().getId().equals(section.getId());
        if (sectionChanged) {
            product.setMenuSection(section);
            product.setPosition(productRepository.findMaxPositionInSection(section.getId()) + 1);
        }

        applyItem(product, request);
        if (request.getAvailable() != null) {
            product.setAvailable(request.getAvailable());
        }
        if (request.getActive() != null) {
            product.setActive(request.getActive());
        }
        return MenuItemDTO.from(productRepository.save(product));
    }

    /**
     * Exclusão lógica: o item some do cardápio, mas o histórico de pedidos continua íntegro
     */
    public void deleteItem(Long restaurantId, Long itemId) {
        Product product = findItem(restaurantId, itemId);

        List<String> combosWithItem = comboRepository.findByRestaurantIdAndDeletedAtIsNullOrderByPositionAscIdAsc(restaurantId)
                .stream()
                .filter(c -> c.getComboItems().stream().anyMatch(i -> i.getProduct().getId().equals(itemId)))
                .map(Combo::getName)
                .toList();
        if (!combosWithItem.isEmpty()) {
            throw new BadRequestException("Este item faz parte do combo " + String.join(", ", combosWithItem)
                    + ". Remova-o do combo antes de excluir.");
        }

        product.setDeletedAt(LocalDateTime.now(clock));
        product.setActive(false);
        product.setAvailable(false);
        productRepository.save(product);
    }

    public MenuItemDTO setItemAvailability(Long restaurantId, Long itemId, boolean available) {
        Product product = findItem(restaurantId, itemId);
        product.setAvailable(available);
        return MenuItemDTO.from(productRepository.save(product));
    }

    public void reorderItems(Long restaurantId, Long sectionId, List<Long> ids) {
        findSection(restaurantId, sectionId);
        List<Product> items = productRepository.findByRestaurantIdAndDeletedAtIsNullOrderByPositionAscIdAsc(restaurantId)
                .stream()
                .filter(p -> p.getMenuSection() != null && p.getMenuSection().getId().equals(sectionId))
                .toList();
        applyOrder(items, ids, Product::getId, Product::setPosition);
        productRepository.saveAll(items);
    }

    public MenuItemDTO updateItemImage(Long restaurantId, Long itemId, MultipartFile image) {
        Product product = findItem(restaurantId, itemId);
        String previous = product.getImageUrl();
        product.setImageUrl(fileStorageService.storeImage(image, IMAGE_FOLDER));
        productRepository.save(product);
        deleteFileQuietly(previous);
        return MenuItemDTO.from(product);
    }

    public MenuItemDTO removeItemImage(Long restaurantId, Long itemId) {
        Product product = findItem(restaurantId, itemId);
        String previous = product.getImageUrl();
        product.setImageUrl(null);
        productRepository.save(product);
        deleteFileQuietly(previous);
        return MenuItemDTO.from(product);
    }

    // ============= Complementos =============

    public CustomizationGroupDTO createGroup(Long restaurantId, Long itemId, CustomizationGroupRequest request) {
        validateGroup(request);
        Product product = findItem(restaurantId, itemId);

        CustomizationGroup group = new CustomizationGroup();
        group.setProduct(product);
        group.setPosition(product.getCustomizationGroups().size());
        applyGroup(group, request);
        product.getCustomizationGroups().add(group);

        return CustomizationGroupDTO.from(groupRepository.save(group));
    }

    public CustomizationGroupDTO updateGroup(Long restaurantId, Long groupId, CustomizationGroupRequest request) {
        validateGroup(request);
        CustomizationGroup group = findGroup(restaurantId, groupId);

        Set<Long> keptIds = request.getOptions().stream()
                .map(CustomizationGroupRequest.OptionRequest::getId)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());
        List<Long> removedIds = group.getOptions().stream()
                .map(CustomizationOption::getId)
                .filter(id -> !keptIds.contains(id))
                .toList();
        if (!removedIds.isEmpty() && orderItemCustomizationRepository.existsByCustomizationOptionIdIn(removedIds)) {
            throw new BadRequestException("Uma das opções removidas já foi usada em pedidos. Marque-a como indisponível em vez de removê-la.");
        }

        applyGroup(group, request);
        return CustomizationGroupDTO.from(groupRepository.save(group));
    }

    public void deleteGroup(Long restaurantId, Long groupId) {
        CustomizationGroup group = findGroup(restaurantId, groupId);
        if (orderItemCustomizationRepository.existsByGroupId(groupId)) {
            throw new BadRequestException("Este grupo já foi usado em pedidos. Marque as opções como indisponíveis em vez de excluí-lo.");
        }
        group.getProduct().getCustomizationGroups().remove(group);
        groupRepository.delete(group);
    }

    public void reorderGroups(Long restaurantId, Long itemId, List<Long> ids) {
        Product product = findItem(restaurantId, itemId);
        applyOrder(product.getCustomizationGroups(), ids, CustomizationGroup::getId, CustomizationGroup::setPosition);
        groupRepository.saveAll(product.getCustomizationGroups());
    }

    // ============= Combos =============

    public ComboDTO createCombo(Long restaurantId, ComboRequest request) {
        MenuSection section = findSection(restaurantId, request.getSectionId());

        Combo combo = new Combo();
        combo.setRestaurant(section.getRestaurant());
        combo.setMenuSection(section);
        combo.setPosition((int) comboRepository.countByMenuSectionIdAndDeletedAtIsNull(section.getId()));
        applyCombo(restaurantId, combo, request);
        combo.setAvailable(request.getAvailable() == null || request.getAvailable());
        combo.setActive(request.getActive() == null || request.getActive());

        return ComboDTO.from(comboRepository.save(combo));
    }

    public ComboDTO updateCombo(Long restaurantId, Long comboId, ComboRequest request) {
        Combo combo = findCombo(restaurantId, comboId);
        MenuSection section = findSection(restaurantId, request.getSectionId());
        combo.setMenuSection(section);
        applyCombo(restaurantId, combo, request);
        if (request.getAvailable() != null) {
            combo.setAvailable(request.getAvailable());
        }
        if (request.getActive() != null) {
            combo.setActive(request.getActive());
        }
        return ComboDTO.from(comboRepository.save(combo));
    }

    public void deleteCombo(Long restaurantId, Long comboId) {
        Combo combo = findCombo(restaurantId, comboId);
        combo.setDeletedAt(LocalDateTime.now(clock));
        combo.setActive(false);
        combo.setAvailable(false);
        comboRepository.save(combo);
    }

    public ComboDTO setComboAvailability(Long restaurantId, Long comboId, boolean available) {
        Combo combo = findCombo(restaurantId, comboId);
        combo.setAvailable(available);
        return ComboDTO.from(comboRepository.save(combo));
    }

    public ComboDTO updateComboImage(Long restaurantId, Long comboId, MultipartFile image) {
        Combo combo = findCombo(restaurantId, comboId);
        String previous = combo.getImageUrl();
        combo.setImageUrl(fileStorageService.storeImage(image, IMAGE_FOLDER));
        comboRepository.save(combo);
        deleteFileQuietly(previous);
        return ComboDTO.from(combo);
    }

    // ============= Helpers =============

    private Restaurant findRestaurant(Long restaurantId) {
        return restaurantRepository.findById(restaurantId)
                .orElseThrow(() -> new ResourceNotFoundException("Restaurante não encontrado"));
    }

    private MenuSection findSection(Long restaurantId, Long sectionId) {
        return sectionRepository.findByIdAndRestaurantId(sectionId, restaurantId)
                .orElseThrow(() -> new ResourceNotFoundException("Seção não encontrada"));
    }

    private Product findItem(Long restaurantId, Long itemId) {
        return productRepository.findByIdAndRestaurantIdAndDeletedAtIsNull(itemId, restaurantId)
                .orElseThrow(() -> new ResourceNotFoundException("Item não encontrado"));
    }

    private Combo findCombo(Long restaurantId, Long comboId) {
        return comboRepository.findByIdAndRestaurantIdAndDeletedAtIsNull(comboId, restaurantId)
                .orElseThrow(() -> new ResourceNotFoundException("Combo não encontrado"));
    }

    private CustomizationGroup findGroup(Long restaurantId, Long groupId) {
        CustomizationGroup group = groupRepository.findById(groupId)
                .orElseThrow(() -> new ResourceNotFoundException("Grupo de complementos não encontrado"));
        Product product = group.getProduct();
        if (product.getDeletedAt() != null || !product.getRestaurant().getId().equals(restaurantId)) {
            throw new ResourceNotFoundException("Grupo de complementos não encontrado");
        }
        return group;
    }

    private void applyItem(Product product, MenuItemRequest request) {
        product.setName(request.getName().trim());
        product.setDescription(trimToNull(request.getDescription()));
        product.setPrice(request.getPrice());
        product.setPromotionalPrice(request.getPromotionalPrice());
        product.setPreparationTime(request.getPreparationTime());
        product.setBadges(normalizeBadges(request.getBadges()));
    }

    private void applyGroup(CustomizationGroup group, CustomizationGroupRequest request) {
        group.setName(request.getName().trim());
        group.setMinSelections(request.getMinSelections());
        group.setMaxSelections(request.getMaxSelections());
        group.setRequired(request.getMinSelections() > 0);

        Map<Long, CustomizationOption> existing = group.getOptions().stream()
                .collect(Collectors.toMap(CustomizationOption::getId, Function.identity()));

        List<CustomizationOption> ordered = new ArrayList<>();
        for (int i = 0; i < request.getOptions().size(); i++) {
            CustomizationGroupRequest.OptionRequest optionRequest = request.getOptions().get(i);
            CustomizationOption option;
            if (optionRequest.getId() != null) {
                option = existing.get(optionRequest.getId());
                if (option == null) {
                    throw new BadRequestException("Opção " + optionRequest.getId() + " não pertence a este grupo");
                }
            } else {
                option = new CustomizationOption();
                option.setCustomizationGroup(group);
            }
            option.setName(optionRequest.getName().trim());
            option.setPriceModifier(optionRequest.getPriceModifier());
            option.setAvailable(optionRequest.getAvailable() == null || optionRequest.getAvailable());
            option.setDisplayOrder(i);
            ordered.add(option);
        }

        // Mantém a mesma lista (orphanRemoval apaga as opções que saíram)
        group.getOptions().clear();
        group.getOptions().addAll(ordered);
    }

    private void applyCombo(Long restaurantId, Combo combo, ComboRequest request) {
        combo.setName(request.getName().trim());
        combo.setDescription(trimToNull(request.getDescription()));
        combo.setPrice(request.getPrice());

        combo.getComboItems().clear();
        for (ComboRequest.ItemRequest itemRequest : request.getItems()) {
            Product product = findItem(restaurantId, itemRequest.getProductId());
            ComboItem item = new ComboItem();
            item.setCombo(combo);
            item.setProduct(product);
            item.setQuantity(itemRequest.getQuantity());
            item.setUnitPriceSnapshot(product.getCurrentPrice());
            combo.getComboItems().add(item);
        }
    }

    private void validatePrices(BigDecimal price, BigDecimal promotionalPrice) {
        if (promotionalPrice != null && promotionalPrice.compareTo(price) >= 0) {
            throw new BadRequestException("O preço promocional deve ser menor que o preço normal");
        }
    }

    private void validateGroup(CustomizationGroupRequest request) {
        int options = request.getOptions().size();
        if (request.getMinSelections() > request.getMaxSelections()) {
            throw new BadRequestException("O mínimo de escolhas não pode ser maior que o máximo");
        }
        if (request.getMaxSelections() > options) {
            throw new BadRequestException("O máximo de escolhas não pode ser maior que o número de opções");
        }
    }

    /**
     * Aplica a nova ordem: os ids enviados precisam ser exatamente os registros existentes
     */
    private <T> void applyOrder(List<T> items, List<Long> ids, Function<T, Long> idOf, PositionSetter<T> setter) {
        Set<Long> current = items.stream().map(idOf).collect(Collectors.toSet());
        if (ids.size() != current.size() || !current.equals(new HashSet<>(ids))) {
            throw new BadRequestException("A nova ordem deve conter exatamente os registros atuais");
        }
        Map<Long, T> byId = items.stream().collect(Collectors.toMap(idOf, Function.identity()));
        for (int i = 0; i < ids.size(); i++) {
            setter.set(byId.get(ids.get(i)), i);
        }
    }

    @FunctionalInterface
    private interface PositionSetter<T> {
        void set(T item, int position);
    }

    private void deleteFileQuietly(String path) {
        if (path != null) {
            fileStorageService.deleteFile(path);
        }
    }

    /** Remove vazios e repetidos (sem diferenciar maiúsculas) e valida limite e tamanho */
    List<String> normalizeBadges(List<String> badges) {
        if (badges == null) {
            return new ArrayList<>();
        }
        Map<String, String> unique = new LinkedHashMap<>();
        for (String badge : badges) {
            String value = trimToNull(badge);
            if (value != null) {
                unique.putIfAbsent(value.toLowerCase(), value);
            }
        }
        List<String> result = new ArrayList<>(unique.values());
        if (result.size() > MAX_BADGES) {
            throw new BadRequestException("Cada item pode ter no máximo " + MAX_BADGES + " selos");
        }
        for (String badge : result) {
            if (badge.length() > MAX_BADGE_LENGTH) {
                throw new BadRequestException("O selo \"" + badge + "\" passa de " + MAX_BADGE_LENGTH + " caracteres");
            }
            if (badge.contains(StringListConverter.SEPARATOR)) {
                throw new BadRequestException("Selos não podem conter o caractere " + StringListConverter.SEPARATOR);
            }
        }
        return result;
    }

    private String trimToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
