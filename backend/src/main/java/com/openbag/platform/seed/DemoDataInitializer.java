package com.openbag.platform.seed;

import com.openbag.enums.MembershipOrigin;
import com.openbag.enums.MembershipStatus;
import com.openbag.enums.OrganizationStatus;
import com.openbag.enums.OrganizationType;
import com.openbag.enums.PartnershipSide;
import com.openbag.enums.PartnershipStatus;
import com.openbag.enums.RestaurantThemePreset;
import com.openbag.enums.UserType;
import com.openbag.enums.VehicleType;
import com.openbag.delivery.courier.entity.DeliveryPerson;
import com.openbag.association.partnership.entity.RestaurantPartnership;
import com.openbag.delivery.courier.repository.DeliveryPersonRepository;
import com.openbag.association.partnership.repository.RestaurantPartnershipRepository;
import com.openbag.delivery.courier.service.CourierProfileService;
import com.openbag.restaurant.menu.dto.MenuItemRequest;
import com.openbag.restaurant.menu.dto.MenuSectionRequest;
import com.openbag.restaurant.menu.service.MenuService;
import com.openbag.association.core.dto.DeliveryRateDTO;
import com.openbag.association.core.entity.AssociationMembership;
import com.openbag.association.core.entity.DeliveryRate;
import com.openbag.association.core.entity.Organization;
import com.openbag.association.core.repository.AssociationMembershipRepository;
import com.openbag.association.core.repository.OrganizationRepository;
import com.openbag.association.core.service.AssociationService;
import com.openbag.restaurant.catalog.entity.Category;
import com.openbag.restaurant.catalog.repository.CategoryRepository;
import com.openbag.restaurant.store.dto.LayoutConfigDTO;
import com.openbag.restaurant.store.dto.OpeningHourDTO;
import com.openbag.restaurant.store.dto.RestaurantOnboardingRequest;
import com.openbag.restaurant.store.entity.Restaurant;
import com.openbag.restaurant.store.repository.RestaurantRepository;
import com.openbag.restaurant.store.service.RestaurantOnboardingService;
import com.openbag.modules.user.dto.AddressDTO;
import com.openbag.modules.user.entity.Address;
import com.openbag.modules.user.entity.Role;
import com.openbag.modules.user.entity.User;
import com.openbag.modules.user.repository.RoleRepository;
import com.openbag.modules.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionTemplate;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Conta de demonstração com TODOS os perfis (super admin, cliente, restaurante, entregador e gestor
 * de associação), para testar e tirar as capturas de tela: uma loja aberta com cardápio, uma
 * associação aprovada com tabela de entrega e o perfil de entregador vinculado a ela.
 *
 * Só roda com app.demo.enabled=true (OPENBAG_DEMO_ENABLED): a senha é pública, então NUNCA
 * ligue em produção. É idempotente: cada parte só é criada se ainda não existir.
 */
@Component
@Order(2)
@Slf4j
@RequiredArgsConstructor
public class DemoDataInitializer implements ApplicationRunner {

    public static final String DEMO_EMAIL = "demo@openbag.local";
    public static final String DEMO_PASSWORD = "demo1234";
    // Fictício, no mesmo formato do ADMIN inicial (00000000000), para não colidir com telefones reais
    static final String DEMO_PHONE = "00000000001";
    static final String DEMO_SLUG = "cantina-demo";

    // Documentos fictícios com dígitos verificadores válidos (usados só na conta demo)
    private static final String RESTAURANT_CNPJ = "11.222.333/0001-81";
    private static final String ASSOCIATION_CNPJ = "11444777000161";
    private static final String COURIER_CPF = "52998224725";
    private static final String COURIER_CNH = "98765432100";

    // Centro de Blumenau (SC)
    private static final BigDecimal LATITUDE = new BigDecimal("-26.919400");
    private static final BigDecimal LONGITUDE = new BigDecimal("-49.066100");

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final CategoryRepository categoryRepository;
    private final RestaurantRepository restaurantRepository;
    private final OrganizationRepository organizationRepository;
    private final AssociationMembershipRepository membershipRepository;
    private final DeliveryPersonRepository deliveryPersonRepository;
    private final RestaurantPartnershipRepository partnershipRepository;
    private final RestaurantOnboardingService onboardingService;
    private final AssociationService associationService;
    private final CourierProfileService courierProfileService;
    private final MenuService menuService;
    private final TransactionTemplate transactionTemplate;

    @Value("${app.demo.enabled:false}")
    private boolean enabled;

    @Override
    public void run(ApplicationArguments args) {
        if (!enabled) {
            return;
        }
        try {
            // Cada parte na sua transação: uma falha não desfaz as anteriores nem derruba a aplicação
            transactionTemplate.executeWithoutResult(status -> ensureRestaurant());
            // Cardápio em outra transação: com a loja recém-criada ainda na memória, o hashCode do Lombok
            // entre Restaurant e LayoutConfig entra em recursão
            transactionTemplate.executeWithoutResult(status -> ensureMenu());
            transactionTemplate.executeWithoutResult(status -> ensureRoles());
            transactionTemplate.executeWithoutResult(status -> ensureAssociation());
            transactionTemplate.executeWithoutResult(status -> ensureCourier());
            transactionTemplate.executeWithoutResult(status -> ensurePartnership());
            log.warn("Conta de demonstração ativa: {} / {} (todos os perfis, inclusive ADMIN). "
                    + "Não use app.demo.enabled em produção.", DEMO_EMAIL, DEMO_PASSWORD);
        } catch (RuntimeException e) {
            log.error("Não foi possível criar a conta de demonstração: {}", e.getMessage(), e);
        }
    }

    private User demoUser() {
        return userRepository.findByEmail(DEMO_EMAIL)
                .orElseThrow(() -> new IllegalStateException("Usuário demo não encontrado"));
    }

    /** Loja + usuário (o cadastro do restaurante cria o dono) */
    private void ensureRestaurant() {
        if (userRepository.existsByEmail(DEMO_EMAIL)) {
            return;
        }
        RestaurantOnboardingRequest request = new RestaurantOnboardingRequest();
        request.setOwner(new RestaurantOnboardingRequest.OwnerData("Conta Demo", DEMO_EMAIL, DEMO_PHONE, DEMO_PASSWORD));

        RestaurantOnboardingRequest.RestaurantData data = new RestaurantOnboardingRequest.RestaurantData();
        data.setName("Cantina Demo");
        data.setSlug(DEMO_SLUG);
        data.setDescription("Comida caseira feita na hora: pratos do dia, massas e sobremesas.");
        data.setPhoneNumber("4733330000");
        data.setCnpj(RESTAURANT_CNPJ);
        data.setDeliveryFee(new BigDecimal("6.00"));
        data.setMinimumOrder(new BigDecimal("25.00"));
        data.setDeliveryTimeMin(30);
        data.setDeliveryTimeMax(45);
        data.setLatitude(LATITUDE);
        data.setLongitude(LONGITUDE);
        request.setRestaurant(data);

        request.setAddress(address("Rua XV de Novembro", "1200", "Centro", "89010-001", LATITUDE, LONGITUDE));
        request.setLayoutConfig(new LayoutConfigDTO(RestaurantThemePreset.SUNSET_ORANGE, null,
                "Comida de casa, sem pressa", null, null));

        List<OpeningHourDTO> hours = new ArrayList<>();
        for (int weekday = 1; weekday <= 7; weekday++) {
            hours.add(new OpeningHourDTO(null, weekday, LocalTime.of(10, 0), LocalTime.of(23, 30), null));
        }
        request.setOpeningHours(hours);
        request.setCategoryIds(List.of(category("Comida caseira").getId()));

        onboardingService.completeOnboarding(request, null, null);
        log.info("Demo: loja {} criada", DEMO_SLUG);
    }

    /** Cardápio da loja demo, se ela ainda não tiver nenhuma seção */
    private void ensureMenu() {
        Restaurant restaurant = restaurantRepository.findByOwnerIdOrderByNameAsc(demoUser().getId()).stream()
                .filter(r -> DEMO_SLUG.equals(r.getSlug()))
                .findFirst()
                .orElse(null);
        if (restaurant == null || !menuService.getOwnerMenu(restaurant.getId()).getSections().isEmpty()) {
            return;
        }
        Long restaurantId = restaurant.getId();
        Long dishes = menuService.createSection(restaurantId,
                new MenuSectionRequest("Pratos do dia", "Servidos com arroz, feijão e salada", "rice_bowl", true)).getId();
        item(restaurantId, dishes, "Frango grelhado", "Peito de frango grelhado com legumes", "32.00", null);
        item(restaurantId, dishes, "Bife acebolado", "Contrafilé com cebola dourada", "38.00", "34.00");
        item(restaurantId, dishes, "Omelete da casa", "Três ovos, queijo, tomate e ervas", "26.00", null);

        Long pasta = menuService.createSection(restaurantId,
                new MenuSectionRequest("Massas", "Massa fresca feita aqui", "dinner_dining", true)).getId();
        item(restaurantId, pasta, "Talharim ao sugo", "Molho de tomate caseiro e manjericão", "34.00", null);
        item(restaurantId, pasta, "Nhoque à bolonhesa", "Nhoque de batata com ragu de carne", "39.00", null);

        Long drinks = menuService.createSection(restaurantId,
                new MenuSectionRequest("Bebidas", null, "local_drink", true)).getId();
        item(restaurantId, drinks, "Suco natural 500ml", "Laranja, limão ou maracujá", "12.00", null);
        item(restaurantId, drinks, "Refrigerante lata", "Coca-Cola, Guaraná ou Sprite", "7.00", null);
    }

    private void item(Long restaurantId, Long sectionId, String name, String description, String price, String promo) {
        MenuItemRequest request = new MenuItemRequest();
        request.setSectionId(sectionId);
        request.setName(name);
        request.setDescription(description);
        request.setPrice(new BigDecimal(price));
        request.setPromotionalPrice(promo != null ? new BigDecimal(promo) : null);
        request.setPreparationTime(20);
        request.setAvailable(true);
        request.setActive(true);
        menuService.createItem(restaurantId, request);
    }

    /** Todos os papéis na mesma conta */
    private void ensureRoles() {
        User user = demoUser();
        for (Role.RoleName name : Role.RoleName.values()) {
            roleRepository.findByName(name.name())
                    .filter(role -> !user.getRoles().contains(role))
                    .ifPresent(role -> user.getRoles().add(role));
        }
        user.setUserType(UserType.ADMIN);
        userRepository.save(user);
    }

    /** Associação já aprovada, com a conta demo como gestora e tabela de entrega */
    private void ensureAssociation() {
        User user = demoUser();
        if (!organizationRepository.findByAdminUserId(user.getId()).isEmpty()) {
            return;
        }
        Organization organization = new Organization();
        organization.setType(OrganizationType.COOPERATIVE);
        organization.setCompanyName("Cooperativa Demo de Entregadores");
        organization.setTradingName("Cooperativa Demo");
        organization.setCnpj(ASSOCIATION_CNPJ);
        organization.setDescription("Cooperativa de demonstração do OpenBag");
        organization.setPhoneNumber("4733331111");
        organization.setContactEmail(DEMO_EMAIL);
        organization.setStatus(OrganizationStatus.ACTIVE);
        organization.setApprovedAt(LocalDateTime.now());
        organization.setApprovedBy(user);
        organization.setAdminUser(user);
        organization.setAddress(toAddress(address("Rua Sete de Setembro", "500", "Centro", "89010-200",
                new BigDecimal("-26.916600"), new BigDecimal("-49.071700"))));
        organization = organizationRepository.save(organization);

        associationService.updateDeliveryRate(organization.getId(),
                new DeliveryRateDTO(new BigDecimal("7.00"), new BigDecimal("3.0"), new BigDecimal("1.50"), true));
        log.info("Demo: associação {} criada", organization.getId());
    }

    /** Perfil de entregador com moto ativa e vínculo ACTIVE com a associação demo */
    private void ensureCourier() {
        User user = demoUser();
        if (deliveryPersonRepository.findByUserId(user.getId()).isPresent()) {
            return;
        }
        Organization organization = organizationRepository.findByAdminUserId(user.getId()).get(0);

        DeliveryPerson courier = new DeliveryPerson();
        courier.setUser(user);
        courier.setDocumentNumber(COURIER_CPF);
        courier.setDriverLicense(COURIER_CNH);
        courier.setVehicleType(VehicleType.MOTORCYCLE);
        courier.setVehiclePlate("DMO1A23");
        courier.setVehicleModel("Honda CG 160");
        courier.setVehicleColor("Vermelha");
        courier.setBio("Conta de demonstração do OpenBag.");
        courier.setOrganization(organization);
        courier.setActive(true);
        courier.setAvailable(false);
        courier = deliveryPersonRepository.save(courier);
        courierProfileService.initializeProfile(courier);

        AssociationMembership membership = new AssociationMembership();
        membership.setOrganization(organization);
        membership.setDeliveryPerson(courier);
        membership.setOrigin(MembershipOrigin.MANAGER_CREATED);
        membership.setStatus(MembershipStatus.ACTIVE);
        membership.setMemberNumber(membershipRepository.findMaxMemberNumber(organization.getId()) + 1);
        membership.setRequestedAt(LocalDateTime.now());
        membership.setDecidedAt(LocalDateTime.now());
        membership.setDecidedBy(user);
        membershipRepository.save(membership);
        log.info("Demo: entregador {} criado", courier.getId());
    }

    /**
     * Parceria ativa entre a Cantina Demo e a Cooperativa Demo, com tabela especial: a taxa da loja (R$ 6,00) fica
     * abaixo do valor base padrão da cooperativa (R$ 7,00), e o acordo cobre mais km no valor base
     */
    private void ensurePartnership() {
        User user = demoUser();
        Restaurant restaurant = restaurantRepository.findByOwnerIdOrderByNameAsc(user.getId()).stream()
                .filter(r -> DEMO_SLUG.equals(r.getSlug()))
                .findFirst()
                .orElse(null);
        List<Organization> organizations = organizationRepository.findByAdminUserId(user.getId());
        if (restaurant == null || organizations.isEmpty()) {
            return;
        }
        Organization organization = organizations.get(0);
        boolean exists = partnershipRepository.findByRestaurant(restaurant.getId()).stream()
                .anyMatch(p -> p.getOrganization().getId().equals(organization.getId()));
        if (exists) {
            return;
        }
        RestaurantPartnership partnership = new RestaurantPartnership();
        partnership.setRestaurant(restaurant);
        partnership.setOrganization(organization);
        partnership.setStatus(PartnershipStatus.ACTIVE);
        partnership.setRequestedBy(PartnershipSide.RESTAURANT);
        partnership.setDecidedAt(LocalDateTime.now());
        partnership.setAgreedRate(new DeliveryRate(new BigDecimal("6.00"), new BigDecimal("4.0"),
                new BigDecimal("1.50")));
        partnership.setAgreedAt(LocalDateTime.now());
        partnershipRepository.save(partnership);
        log.info("Demo: parceria {} criada", partnership.getId());
    }

    private Category category(String name) {
        return categoryRepository.findAll().stream()
                .filter(category -> category.getName().equalsIgnoreCase(name))
                .findFirst()
                .orElseGet(() -> {
                    Category category = new Category();
                    category.setName(name);
                    category.setActive(true);
                    return categoryRepository.save(category);
                });
    }

    private static AddressDTO address(String street, String number, String neighborhood, String zipCode,
                                      BigDecimal latitude, BigDecimal longitude) {
        AddressDTO address = new AddressDTO();
        address.setStreet(street);
        address.setNumber(number);
        address.setNeighborhood(neighborhood);
        address.setCity("Blumenau");
        address.setState("SC");
        address.setZipCode(zipCode);
        address.setLatitude(latitude);
        address.setLongitude(longitude);
        return address;
    }

    private static Address toAddress(AddressDTO dto) {
        Address address = new Address();
        address.setStreet(dto.getStreet());
        address.setNumber(dto.getNumber());
        address.setNeighborhood(dto.getNeighborhood());
        address.setCity(dto.getCity());
        address.setState(dto.getState());
        address.setZipCode(dto.getZipCode());
        address.setLatitude(dto.getLatitude().doubleValue());
        address.setLongitude(dto.getLongitude().doubleValue());
        return address;
    }
}
