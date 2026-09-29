package com.openbag.delivery.courier.service;

import com.openbag.delivery.courier.entity.SocialPlatform;
import com.openbag.delivery.courier.entity.VehicleType;
import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.delivery.courier.dto.VehicleDTO;
import com.openbag.delivery.courier.dto.VehicleRequest;
import com.openbag.delivery.courier.entity.DeliveryPerson;
import com.openbag.delivery.courier.entity.Vehicle;
import com.openbag.delivery.courier.repository.DeliveryPersonRepository;
import com.openbag.delivery.courier.repository.VehicleRepository;
import com.openbag.association.core.repository.AssociationMembershipRepository;
import com.openbag.account.entity.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CourierProfileServiceTest {

    @Mock
    private DeliveryPersonRepository deliveryPersonRepository;

    @Mock
    private VehicleRepository vehicleRepository;

    @Mock
    private AssociationMembershipRepository membershipRepository;

    @Mock
    private CourierEarningsService earningsService;

    @InjectMocks
    private CourierProfileService service;

    private User user;
    private DeliveryPerson deliveryPerson;

    @BeforeEach
    void setUp() {
        user = new User();
        user.setId(1L);
        user.setFullName("João da Silva Araújo");
        deliveryPerson = new DeliveryPerson();
        deliveryPerson.setId(2L);
        deliveryPerson.setUser(user);
        deliveryPerson.setSlug("joao-araujo-abcd");

        lenient().when(deliveryPersonRepository.findByUserId(1L)).thenReturn(Optional.of(deliveryPerson));
        lenient().when(deliveryPersonRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        lenient().when(vehicleRepository.save(any())).thenAnswer(inv -> {
            Vehicle v = inv.getArgument(0);
            if (v.getId() == null) {
                v.setId(100L);
            }
            return v;
        });
    }

    @Test
    void slugUsesFirstAndLastNameWithoutAccents() {
        assertThat(CourierProfileService.slugify("João da Silva Araújo")).isEqualTo("joao-araujo");
        assertThat(CourierProfileService.slugify("  ")).isEqualTo("entregador");
        assertThat(CourierProfileService.slugify("Zé")).isEqualTo("ze");
    }

    @Test
    void initializeGeneratesUniqueSlugAndMigratesLegacyVehicle() {
        deliveryPerson.setSlug(null);
        deliveryPerson.setVehicleType(VehicleType.MOTORCYCLE);
        deliveryPerson.setVehiclePlate("ABC1D23");
        when(deliveryPersonRepository.existsBySlug(anyString())).thenReturn(true, false);

        service.initializeProfile(deliveryPerson);

        assertThat(deliveryPerson.getSlug()).matches("joao-araujo-[a-z0-9]{4}");
        assertThat(deliveryPerson.getActiveVehicle()).isNotNull();
        assertThat(deliveryPerson.getActiveVehicle().getPlate()).isEqualTo("ABC1D23");
        assertThat(deliveryPerson.getActiveVehicle().getType()).isEqualTo(VehicleType.MOTORCYCLE);
    }

    @Test
    void masksPlateKeepingStartAndEnd() {
        assertThat(CourierProfileService.maskPlate("ABC-1D23")).isEqualTo("ABC**23");
        assertThat(CourierProfileService.maskPlate(null)).isNull();
    }

    @Test
    void normalizesSocialLinks() {
        assertThat(CourierProfileService.normalizeSocialUrl(SocialPlatform.WHATSAPP, "(11) 98765-4321"))
                .isEqualTo("https://wa.me/5511987654321");
        assertThat(CourierProfileService.normalizeSocialUrl(SocialPlatform.INSTAGRAM, "instagram.com/joao"))
                .isEqualTo("https://instagram.com/joao");
        assertThatThrownBy(() -> CourierProfileService.normalizeSocialUrl(SocialPlatform.WEBSITE, "joao"))
                .isInstanceOf(BadRequestException.class);
    }

    @Test
    void firstVehicleBecomesActiveAndMotorizedRequiresPlate() {
        VehicleRequest bike = new VehicleRequest();
        bike.setType(VehicleType.BICYCLE);
        VehicleDTO created = service.createVehicle(user, bike);
        assertThat(created.isActive()).isTrue();

        VehicleRequest moto = new VehicleRequest();
        moto.setType(VehicleType.MOTORCYCLE);
        assertThatThrownBy(() -> service.createVehicle(user, moto))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("Placa");
    }

    @Test
    void cannotArchiveTheOnlyVehicle() {
        Vehicle only = new Vehicle();
        only.setId(5L);
        only.setType(VehicleType.BICYCLE);
        deliveryPerson.useVehicle(only);
        when(vehicleRepository.findByIdAndDeliveryPersonIdAndArchivedFalse(5L, 2L)).thenReturn(Optional.of(only));
        when(vehicleRepository.findByDeliveryPersonIdAndArchivedFalseOrderByCreatedAtAsc(2L)).thenReturn(List.of(only));

        assertThatThrownBy(() -> service.archiveVehicle(user, 5L)).isInstanceOf(BadRequestException.class);
        assertThat(only.isArchived()).isFalse();
    }

    @Test
    void archivingActiveVehicleSwitchesToNext() {
        Vehicle first = new Vehicle();
        first.setId(5L);
        first.setType(VehicleType.BICYCLE);
        Vehicle second = new Vehicle();
        second.setId(6L);
        second.setType(VehicleType.CAR);
        second.setPlate("XYZ9A99");
        deliveryPerson.useVehicle(first);
        when(vehicleRepository.findByIdAndDeliveryPersonIdAndArchivedFalse(5L, 2L)).thenReturn(Optional.of(first));
        when(vehicleRepository.findByDeliveryPersonIdAndArchivedFalseOrderByCreatedAtAsc(2L))
                .thenReturn(List.of(first, second));

        service.archiveVehicle(user, 5L);

        assertThat(first.isArchived()).isTrue();
        assertThat(deliveryPerson.getActiveVehicle()).isSameAs(second);
        assertThat(deliveryPerson.getVehicleType()).isEqualTo(VehicleType.CAR);
    }
}
