package com.openbag.modules.restaurant.service;

import com.openbag.modules.restaurant.dto.RestaurantOnboardingRequest;
import com.openbag.modules.user.dto.AddressDTO;
import com.openbag.modules.restaurant.dto.LayoutConfigDTO;
import com.openbag.modules.restaurant.dto.OpeningHourDTO;
import com.openbag.modules.user.entity.User;
import com.openbag.modules.user.entity.Address;
import com.openbag.modules.restaurant.entity.Restaurant;
import com.openbag.modules.restaurant.entity.LayoutConfig;
import com.openbag.modules.restaurant.entity.OpeningHour;
import com.openbag.modules.product.entity.Category;
import com.openbag.modules.shared.exception.BadRequestException;
import com.openbag.modules.shared.exception.ResourceNotFoundException;
import com.openbag.modules.restaurant.repository.RestaurantRepository;
import com.openbag.modules.user.repository.UserRepository;
import com.openbag.modules.product.repository.CategoryRepository;
import com.openbag.modules.user.service.RoleService;
import com.openbag.modules.shared.service.FileStorageService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.List;

/**
 * Serviço para gerenciamento do onboarding completo de restaurantes
 */
@Service
@Transactional
@Slf4j
public class RestaurantOnboardingService {

    @Autowired
    private RestaurantRepository restaurantRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private CategoryRepository categoryRepository;

    @Autowired
    private RoleService roleService;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private FileStorageService fileStorageService;

    /**
     * Completa o onboarding de um restaurante com upload de logo e banner
     * 
     * @param request Dados completos do onboarding
     * @param logo Arquivo de logo (opcional)
     * @param banner Arquivo de banner (opcional)
     * @return Restaurante criado
     * @throws BadRequestException se houver duplicidade de email, telefone, CNPJ ou slug
     * @throws ResourceNotFoundException se categorias não existirem
     */
    public Restaurant completeOnboarding(RestaurantOnboardingRequest request, MultipartFile logo, MultipartFile banner) {
        log.info("Iniciando onboarding de restaurante: {}", request.getRestaurant().getName());

        // 1. Validar unicidade de email, telefone, CNPJ e slug
        validateUniqueness(request);

        // 2. Fazer upload das imagens se fornecidas
        String logoUrl = null;
        String bannerUrl = null;
        
        if (logo != null && !logo.isEmpty()) {
            logoUrl = fileStorageService.storeImage(logo, "restaurants/logos");
            log.info("Logo salva: {}", logoUrl);
        }
        
        if (banner != null && !banner.isEmpty()) {
            bannerUrl = fileStorageService.storeImage(banner, "restaurants/banners");
            log.info("Banner salvo: {}", bannerUrl);
        }

        // 3. Validar que todas as categorias existem
        List<Category> categories = validateAndGetCategories(request.getCategoryIds());

        // 4. Criar o usuário owner
        User owner = createOwner(request.getOwner());

        // 5. Criar o restaurante
        Restaurant restaurant = createRestaurant(request.getRestaurant(), owner, logoUrl, bannerUrl);

        // 6. Criar e vincular o endereço
        Address address = createAddress(request.getAddress(), restaurant);
        restaurant.setAddress(address);

        // 7. Criar e vincular a configuração de layout
        LayoutConfig layoutConfig = createLayoutConfig(request.getLayoutConfig(), restaurant);
        restaurant.setLayoutConfig(layoutConfig);

        // 8. Criar e vincular horários de funcionamento
        List<OpeningHour> openingHours = createOpeningHours(request.getOpeningHours(), restaurant);
        restaurant.setOpeningHours(openingHours);

        // 9. Vincular categorias
        restaurant.setCategories(categories);

        // 10. Salvar restaurante (cascade salvará address, layoutConfig e openingHours)
        Restaurant savedRestaurant = restaurantRepository.save(restaurant);

        // 11. Adicionar roles ao owner
        addRolesToOwner(owner);

        log.info("Onboarding concluído com sucesso. Restaurante ID: {}, Owner ID: {}, Slug: {}", 
                savedRestaurant.getId(), owner.getId(), savedRestaurant.getSlug());

        return savedRestaurant;
    }

    /**
     * Completa o onboarding de um restaurante (versão legada sem upload)
     * 
     * @deprecated Use {@link #completeOnboarding(RestaurantOnboardingRequest, MultipartFile, MultipartFile)}
     */
    @Deprecated
    public Restaurant completeOnboarding(RestaurantOnboardingRequest request) {
        return completeOnboarding(request, null, null);
    }

    private void validateUniqueness(RestaurantOnboardingRequest request) {
        // Validar email
        if (userRepository.existsByEmail(request.getOwner().getEmail())) {
            throw new BadRequestException("Email já está em uso");
        }

        // Validar telefone do owner
        if (userRepository.existsByPhoneNumber(request.getOwner().getPhoneNumber())) {
            throw new BadRequestException("Telefone já está em uso");
        }

        // Validar CNPJ
        if (restaurantRepository.existsByCnpj(request.getRestaurant().getCnpj())) {
            throw new BadRequestException("CNPJ já cadastrado");
        }

        // Validar slug
        if (restaurantRepository.existsBySlug(request.getRestaurant().getSlug())) {
            throw new BadRequestException("Slug já está em uso. Escolha outro.");
        }
    }

    private List<Category> validateAndGetCategories(List<Long> categoryIds) {
        List<Category> categories = categoryRepository.findAllById(categoryIds);
        
        if (categories.size() != categoryIds.size()) {
            throw new ResourceNotFoundException("Uma ou mais categorias não foram encontradas");
        }

        return categories;
    }

    private User createOwner(RestaurantOnboardingRequest.OwnerData ownerData) {
        User owner = new User();
        owner.setFullName(ownerData.getFullName());
        owner.setEmail(ownerData.getEmail());
        owner.setPhoneNumber(ownerData.getPhoneNumber());
        owner.setPassword(passwordEncoder.encode(ownerData.getPassword()));
        owner.setActive(true);

        // Salvar o usuário para obter o ID
        return userRepository.save(owner);
    }

    private Restaurant createRestaurant(
            RestaurantOnboardingRequest.RestaurantData restaurantData, 
            User owner, 
            String logoUrl, 
            String bannerUrl) {
        Restaurant restaurant = new Restaurant();
        restaurant.setName(restaurantData.getName());
        restaurant.setSlug(restaurantData.getSlug());
        restaurant.setDescription(restaurantData.getDescription());
        restaurant.setPhoneNumber(restaurantData.getPhoneNumber());
        restaurant.setCnpj(restaurantData.getCnpj());
        restaurant.setLogoUrl(logoUrl != null ? logoUrl : restaurantData.getLogoUrl());
        restaurant.setBannerUrl(bannerUrl != null ? bannerUrl : restaurantData.getBannerUrl());
        restaurant.setDeliveryFee(restaurantData.getDeliveryFee());
        restaurant.setMinimumOrder(restaurantData.getMinimumOrder());
        restaurant.setDeliveryTimeMin(restaurantData.getDeliveryTimeMin());
        restaurant.setDeliveryTimeMax(restaurantData.getDeliveryTimeMax());
        restaurant.setLatitude(restaurantData.getLatitude());
        restaurant.setLongitude(restaurantData.getLongitude());
        restaurant.setOwner(owner);
        restaurant.setActive(true);
        restaurant.setOpen(true);

        return restaurant;
    }

    private Address createAddress(AddressDTO addressDTO, Restaurant restaurant) {
        Address address = new Address();
        address.setStreet(addressDTO.getStreet());
        address.setNumber(addressDTO.getNumber());
        address.setComplement(addressDTO.getComplement());
        address.setNeighborhood(addressDTO.getNeighborhood());
        address.setCity(addressDTO.getCity());
        address.setState(addressDTO.getState());
        address.setZipCode(addressDTO.getZipCode());
        address.setLatitude(addressDTO.getLatitude() != null ? addressDTO.getLatitude().doubleValue() : null);
        address.setLongitude(addressDTO.getLongitude() != null ? addressDTO.getLongitude().doubleValue() : null);

        return address;
    }

    private LayoutConfig createLayoutConfig(LayoutConfigDTO layoutConfigDTO, Restaurant restaurant) {
        LayoutConfig layoutConfig = new LayoutConfig();
        layoutConfig.setPrimaryColor(layoutConfigDTO.getPrimaryColor());
        layoutConfig.setSecondaryColor(layoutConfigDTO.getSecondaryColor());
        layoutConfig.setRestaurant(restaurant);

        return layoutConfig;
    }

    private List<OpeningHour> createOpeningHours(List<OpeningHourDTO> openingHourDTOs, Restaurant restaurant) {
        List<OpeningHour> openingHours = new ArrayList<>();

        for (OpeningHourDTO dto : openingHourDTOs) {
            // Validar que closeTime é depois de openTime
            if (dto.getCloseTime().isBefore(dto.getOpenTime()) || dto.getCloseTime().equals(dto.getOpenTime())) {
                throw new BadRequestException(
                    String.format("Horário de fechamento deve ser posterior ao horário de abertura (Dia %d)", dto.getWeekday())
                );
            }

            OpeningHour openingHour = new OpeningHour();
            openingHour.setLabel(dto.getLabel());
            openingHour.setWeekday(dto.getWeekday());
            openingHour.setOpenTime(dto.getOpenTime());
            openingHour.setCloseTime(dto.getCloseTime());
            openingHour.setObservation(dto.getObservation());
            openingHour.setRestaurant(restaurant);

            openingHours.add(openingHour);
        }

        return openingHours;
    }

    private void addRolesToOwner(User owner) {
        try {
            // Adicionar role CUSTOMER (padrão para todos os usuários)
            roleService.addRoleToUser(owner.getId(), "CUSTOMER");
            
            // Adicionar role RESTAURANT_OWNER
            roleService.addRoleToUser(owner.getId(), "RESTAURANT_OWNER");
            
            log.info("Roles CUSTOMER e RESTAURANT_OWNER adicionadas ao usuário {}", owner.getId());
        } catch (Exception e) {
            log.warn("Erro ao adicionar roles ao usuário {}: {}", owner.getId(), e.getMessage());
            // Não falhar a transação por causa das roles
        }
    }
}
