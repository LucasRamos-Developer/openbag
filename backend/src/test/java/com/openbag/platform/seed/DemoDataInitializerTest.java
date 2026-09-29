package com.openbag.platform.seed;

import com.openbag.modules.delivery.entity.DeliveryPerson;
import com.openbag.modules.delivery.repository.DeliveryPersonRepository;
import com.openbag.modules.delivery.service.CourierProfileService;
import com.openbag.restaurant.menu.service.MenuService;
import com.openbag.modules.organization.entity.Organization;
import com.openbag.modules.organization.repository.AssociationMembershipRepository;
import com.openbag.modules.organization.repository.OrganizationRepository;
import com.openbag.modules.organization.service.AssociationService;
import com.openbag.restaurant.catalog.repository.CategoryRepository;
import com.openbag.restaurant.store.repository.RestaurantRepository;
import com.openbag.restaurant.store.service.RestaurantOnboardingService;
import com.openbag.modules.user.entity.Role;
import com.openbag.modules.user.entity.User;
import com.openbag.modules.user.repository.RoleRepository;
import com.openbag.modules.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.transaction.TransactionStatus;
import org.springframework.transaction.support.TransactionTemplate;

import java.util.List;
import java.util.Optional;
import java.util.function.Consumer;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class DemoDataInitializerTest {

    @Mock private UserRepository userRepository;
    @Mock private RoleRepository roleRepository;
    @Mock private CategoryRepository categoryRepository;
    @Mock private RestaurantRepository restaurantRepository;
    @Mock private OrganizationRepository organizationRepository;
    @Mock private AssociationMembershipRepository membershipRepository;
    @Mock private DeliveryPersonRepository deliveryPersonRepository;
    @Mock private RestaurantOnboardingService onboardingService;
    @Mock private AssociationService associationService;
    @Mock private CourierProfileService courierProfileService;
    @Mock private MenuService menuService;
    @Mock private TransactionTemplate transactionTemplate;

    @InjectMocks
    private DemoDataInitializer initializer;

    private final User demo = new User();

    @BeforeEach
    @SuppressWarnings("unchecked")
    void setUp() {
        demo.setId(7L);
        demo.setEmail(DemoDataInitializer.DEMO_EMAIL);
        doAnswer(invocation -> {
            ((Consumer<TransactionStatus>) invocation.getArgument(0)).accept(null);
            return null;
        }).when(transactionTemplate).executeWithoutResult(any());
        for (Role.RoleName name : Role.RoleName.values()) {
            Role role = new Role();
            role.setName(name.name());
            when(roleRepository.findByName(name.name())).thenReturn(Optional.of(role));
        }
    }

    @Test
    void disabledByDefaultDoesNothing() {
        initializer.run(null);

        verifyNoInteractions(userRepository, onboardingService, organizationRepository, deliveryPersonRepository);
    }

    @Test
    void secondRunCreatesNothingAgain() {
        ReflectionTestUtils.setField(initializer, "enabled", true);
        when(userRepository.existsByEmail(DemoDataInitializer.DEMO_EMAIL)).thenReturn(true);
        when(userRepository.findByEmail(DemoDataInitializer.DEMO_EMAIL)).thenReturn(Optional.of(demo));
        when(organizationRepository.findByAdminUserId(7L)).thenReturn(List.of(new Organization()));
        when(deliveryPersonRepository.findByUserId(7L)).thenReturn(Optional.of(new DeliveryPerson()));

        initializer.run(null);

        verify(onboardingService, never()).completeOnboarding(any(), any(), any());
        verify(organizationRepository, never()).save(any());
        verify(deliveryPersonRepository, never()).save(any());
        verify(membershipRepository, never()).save(any());
        // Os papéis são conferidos a cada subida: a conta demo sempre tem todos
        assertThat(demo.getRoles()).extracting(Role::getName)
                .containsExactlyInAnyOrder(java.util.Arrays.stream(Role.RoleName.values()).map(Enum::name).toArray(String[]::new));
    }
}
