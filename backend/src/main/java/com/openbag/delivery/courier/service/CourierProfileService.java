package com.openbag.delivery.courier.service;

import com.openbag.enums.MembershipStatus;
import com.openbag.enums.SocialPlatform;
import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.platform.web.exception.ResourceNotFoundException;
import com.openbag.delivery.courier.dto.CourierAssociationDTO;
import com.openbag.delivery.courier.dto.CourierProfileDTO;
import com.openbag.delivery.courier.dto.CourierProfileUpdateRequest;
import com.openbag.delivery.courier.dto.CourierPublicDTO;
import com.openbag.delivery.courier.dto.SocialLinkDTO;
import com.openbag.delivery.courier.dto.VehicleDTO;
import com.openbag.delivery.courier.dto.VehicleRequest;
import com.openbag.delivery.courier.entity.CourierSocialLink;
import com.openbag.delivery.courier.entity.DeliveryPerson;
import com.openbag.delivery.courier.entity.Vehicle;
import com.openbag.delivery.courier.repository.DeliveryPersonRepository;
import com.openbag.delivery.courier.repository.VehicleRepository;
import com.openbag.association.core.entity.AssociationMembership;
import com.openbag.association.core.repository.AssociationMembershipRepository;
import com.openbag.platform.files.FileStorageService;
import com.openbag.platform.util.BrazilianDocuments;
import com.openbag.modules.user.entity.User;
import com.openbag.modules.user.repository.UserRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.security.SecureRandom;
import java.text.Normalizer;
import java.util.List;
import java.util.Locale;
import java.util.Optional;

/**
 * Perfil do entregador: dados pessoais, foto, redes sociais, veículos e o perfil público (/e/{slug}).
 */
@Service
@Transactional
@Slf4j
public class CourierProfileService {

    static final String PHOTO_FOLDER = "couriers";
    static final String VEHICLE_PHOTO_FOLDER = "couriers/vehicles";

    private static final String SLUG_ALPHABET = "abcdefghjkmnpqrstuvwxyz23456789";
    private static final SecureRandom RANDOM = new SecureRandom();

    @Autowired
    private DeliveryPersonRepository deliveryPersonRepository;

    @Autowired
    private VehicleRepository vehicleRepository;

    @Autowired
    private AssociationMembershipRepository membershipRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private FileStorageService fileStorageService;

    @Autowired
    private CourierEarningsService earningsService;

    // ============= Perfil =============

    @Transactional(readOnly = true)
    public CourierProfileDTO getMyProfile(User user) {
        return toProfileDTO(findByUser(user));
    }

    public CourierProfileDTO updateProfile(User user, CourierProfileUpdateRequest request) {
        DeliveryPerson deliveryPerson = findByUser(user);
        User account = deliveryPerson.getUser();

        String phone = request.getPhoneNumber().trim();
        if (!phone.equals(account.getPhoneNumber()) && userRepository.existsByPhoneNumber(phone)) {
            throw new BadRequestException("Telefone já está em uso");
        }
        account.setFullName(request.getFullName().trim());
        account.setPhoneNumber(phone);
        userRepository.save(account);

        deliveryPerson.setBio(blankToNull(request.getBio()));
        if (request.getShowWorkHistory() != null) {
            deliveryPerson.setShowWorkHistory(request.getShowWorkHistory());
        }
        deliveryPerson.getSocialLinks().clear();
        if (request.getSocialLinks() != null) {
            for (SocialLinkDTO link : request.getSocialLinks()) {
                deliveryPerson.getSocialLinks().add(
                        new CourierSocialLink(link.getPlatform(), normalizeSocialUrl(link.getPlatform(), link.getUrl())));
            }
        }
        return toProfileDTO(deliveryPersonRepository.save(deliveryPerson));
    }

    public CourierProfileDTO updatePhoto(User user, MultipartFile photo) {
        if (photo == null || photo.isEmpty()) {
            throw new BadRequestException("Arquivo da foto é obrigatório");
        }
        DeliveryPerson deliveryPerson = findByUser(user);
        String previous = deliveryPerson.getPhotoUrl();

        String path = fileStorageService.storeImage(photo, PHOTO_FOLDER);
        deliveryPerson.setPhotoUrl(path);
        // A foto do perfil também é a da conta (usada no painel da associação)
        deliveryPerson.getUser().setProfileImageUrl(path);
        userRepository.save(deliveryPerson.getUser());
        deliveryPersonRepository.save(deliveryPerson);

        if (previous != null) {
            fileStorageService.deleteFile(previous);
        }
        return toProfileDTO(deliveryPerson);
    }

    // ============= Veículos =============

    @Transactional(readOnly = true)
    public List<VehicleDTO> listVehicles(User user) {
        DeliveryPerson deliveryPerson = findByUser(user);
        return vehicleRepository.findByDeliveryPersonIdAndArchivedFalseOrderByCreatedAtAsc(deliveryPerson.getId())
                .stream()
                .map(vehicle -> VehicleDTO.from(vehicle, isActive(deliveryPerson, vehicle)))
                .toList();
    }

    public VehicleDTO createVehicle(User user, VehicleRequest request) {
        DeliveryPerson deliveryPerson = findByUser(user);
        Vehicle vehicle = new Vehicle();
        vehicle.setDeliveryPerson(deliveryPerson);
        applyVehicle(vehicle, request);
        vehicle = vehicleRepository.save(vehicle);

        // O primeiro veículo já entra em uso
        if (deliveryPerson.getActiveVehicle() == null) {
            deliveryPerson.useVehicle(vehicle);
            deliveryPersonRepository.save(deliveryPerson);
        }
        return VehicleDTO.from(vehicle, isActive(deliveryPerson, vehicle));
    }

    public VehicleDTO updateVehicle(User user, Long vehicleId, VehicleRequest request) {
        DeliveryPerson deliveryPerson = findByUser(user);
        Vehicle vehicle = findVehicle(deliveryPerson, vehicleId);
        applyVehicle(vehicle, request);
        vehicleRepository.save(vehicle);

        if (isActive(deliveryPerson, vehicle)) {
            deliveryPerson.useVehicle(vehicle);
            deliveryPersonRepository.save(deliveryPerson);
        }
        return VehicleDTO.from(vehicle, isActive(deliveryPerson, vehicle));
    }

    public VehicleDTO updateVehiclePhoto(User user, Long vehicleId, MultipartFile photo) {
        if (photo == null || photo.isEmpty()) {
            throw new BadRequestException("Arquivo da foto é obrigatório");
        }
        DeliveryPerson deliveryPerson = findByUser(user);
        Vehicle vehicle = findVehicle(deliveryPerson, vehicleId);
        String previous = vehicle.getPhotoUrl();

        vehicle.setPhotoUrl(fileStorageService.storeImage(photo, VEHICLE_PHOTO_FOLDER));
        vehicleRepository.save(vehicle);

        if (previous != null) {
            fileStorageService.deleteFile(previous);
        }
        return VehicleDTO.from(vehicle, isActive(deliveryPerson, vehicle));
    }

    public List<VehicleDTO> activateVehicle(User user, Long vehicleId) {
        DeliveryPerson deliveryPerson = findByUser(user);
        deliveryPerson.useVehicle(findVehicle(deliveryPerson, vehicleId));
        deliveryPersonRepository.save(deliveryPerson);
        return listVehicles(user);
    }

    /**
     * Arquiva o veículo. Se for o que está em uso, passa a usar o próximo; o último veículo não pode ser removido.
     */
    public List<VehicleDTO> archiveVehicle(User user, Long vehicleId) {
        DeliveryPerson deliveryPerson = findByUser(user);
        Vehicle vehicle = findVehicle(deliveryPerson, vehicleId);

        if (isActive(deliveryPerson, vehicle)) {
            Vehicle next = vehicleRepository
                    .findByDeliveryPersonIdAndArchivedFalseOrderByCreatedAtAsc(deliveryPerson.getId())
                    .stream()
                    .filter(other -> !other.getId().equals(vehicle.getId()))
                    .findFirst()
                    .orElseThrow(() -> new BadRequestException(
                            "Cadastre outro veículo antes de remover o único que você tem"));
            deliveryPerson.useVehicle(next);
            deliveryPersonRepository.save(deliveryPerson);
        }
        vehicle.setArchived(true);
        vehicleRepository.save(vehicle);
        return listVehicles(user);
    }

    // ============= Perfil público =============

    @Transactional(readOnly = true)
    public CourierPublicDTO getPublicProfile(String slug) {
        DeliveryPerson deliveryPerson = deliveryPersonRepository.findBySlug(slug)
                .filter(dp -> dp.getUser().isActive())
                .orElseThrow(() -> new ResourceNotFoundException("Entregador não encontrado"));
        User user = deliveryPerson.getUser();
        Vehicle vehicle = deliveryPerson.getActiveVehicle();

        return CourierPublicDTO.builder()
                .slug(deliveryPerson.getSlug())
                .fullName(user.getFullName())
                .photoUrl(deliveryPerson.getPhotoUrl())
                .bio(deliveryPerson.getBio())
                .socialLinks(deliveryPerson.getSocialLinks().stream().map(SocialLinkDTO::from).toList())
                .memberSince(deliveryPerson.getCreatedAt())
                .rating(deliveryPerson.getRating())
                .totalReviews(deliveryPerson.getTotalReviews())
                .totalDeliveries(deliveryPerson.getTotalDeliveries())
                .association(findApprovedMembership(deliveryPerson).map(CourierAssociationDTO::from).orElse(null))
                .vehicle(vehicle == null ? null : CourierPublicDTO.PublicVehicle.builder()
                        .type(vehicle.getType())
                        .model(vehicle.getModel())
                        .color(vehicle.getColor())
                        .maskedPlate(maskPlate(vehicle.getPlate()))
                        .build())
                .workHistory(deliveryPerson.isShowWorkHistory() ? earningsService.restaurantsWorked(deliveryPerson) : List.of())
                .build();
    }

    // ============= Inicialização =============

    /**
     * Garante slug e veículo em uso. Chamado no cadastro e, para perfis antigos, na subida da aplicação.
     */
    public void initializeProfile(DeliveryPerson deliveryPerson) {
        if (deliveryPerson.getSlug() == null) {
            deliveryPerson.setSlug(generateSlug(deliveryPerson.getUser().getFullName()));
        }
        if (deliveryPerson.getActiveVehicle() == null && deliveryPerson.getVehicleType() != null) {
            Vehicle vehicle = new Vehicle();
            vehicle.setDeliveryPerson(deliveryPerson);
            vehicle.setType(deliveryPerson.getVehicleType());
            vehicle.setPlate(deliveryPerson.getVehiclePlate());
            vehicle.setModel(deliveryPerson.getVehicleModel());
            vehicle.setColor(deliveryPerson.getVehicleColor());
            deliveryPerson.useVehicle(vehicleRepository.save(vehicle));
        }
        deliveryPersonRepository.save(deliveryPerson);
    }

    // ============= Auxiliares =============

    private CourierProfileDTO toProfileDTO(DeliveryPerson deliveryPerson) {
        User user = deliveryPerson.getUser();
        Vehicle vehicle = deliveryPerson.getActiveVehicle();
        return CourierProfileDTO.builder()
                .id(deliveryPerson.getId())
                .slug(deliveryPerson.getSlug())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .phoneNumber(user.getPhoneNumber())
                .photoUrl(deliveryPerson.getPhotoUrl())
                .bio(deliveryPerson.getBio())
                .showWorkHistory(deliveryPerson.isShowWorkHistory())
                .socialLinks(deliveryPerson.getSocialLinks().stream().map(SocialLinkDTO::from).toList())
                .activeVehicle(vehicle != null ? VehicleDTO.from(vehicle, true) : null)
                .rating(deliveryPerson.getRating())
                .totalReviews(deliveryPerson.getTotalReviews())
                .totalDeliveries(deliveryPerson.getTotalDeliveries())
                .memberSince(deliveryPerson.getCreatedAt())
                .association(findOpenMembership(deliveryPerson).map(CourierAssociationDTO::from).orElse(null))
                .build();
    }

    private DeliveryPerson findByUser(User user) {
        DeliveryPerson deliveryPerson = deliveryPersonRepository.findByUserId(user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Perfil de entregador não encontrado"));
        if (deliveryPerson.getSlug() == null || deliveryPerson.getActiveVehicle() == null) {
            initializeProfile(deliveryPerson);
        }
        return deliveryPerson;
    }

    private Vehicle findVehicle(DeliveryPerson deliveryPerson, Long vehicleId) {
        return vehicleRepository.findByIdAndDeliveryPersonIdAndArchivedFalse(vehicleId, deliveryPerson.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Veículo não encontrado"));
    }

    private Optional<AssociationMembership> findOpenMembership(DeliveryPerson deliveryPerson) {
        return membershipRepository.findByDeliveryPersonIdAndStatusIn(deliveryPerson.getId(), MembershipStatus.OPEN)
                .stream()
                .findFirst();
    }

    // O perfil público só mostra associação que já aceitou o entregador (ACTIVE/SUSPENDED)
    private Optional<AssociationMembership> findApprovedMembership(DeliveryPerson deliveryPerson) {
        return findOpenMembership(deliveryPerson).filter(m -> m.getStatus() != MembershipStatus.PENDING);
    }

    private static boolean isActive(DeliveryPerson deliveryPerson, Vehicle vehicle) {
        return deliveryPerson.getActiveVehicle() != null
                && deliveryPerson.getActiveVehicle().getId().equals(vehicle.getId());
    }

    private static void applyVehicle(Vehicle vehicle, VehicleRequest request) {
        String plate = blankToNull(request.getPlate());
        vehicle.setType(request.getType());
        vehicle.setPlate(plate != null ? plate.toUpperCase(Locale.ROOT) : null);
        vehicle.setModel(blankToNull(request.getModel()));
        vehicle.setColor(blankToNull(request.getColor()));
        if (vehicle.isMotorized() && vehicle.getPlate() == null) {
            throw new BadRequestException("Placa do veículo é obrigatória para moto e carro");
        }
    }

    /**
     * Aceita link completo (http/https). Para WhatsApp aceita também só o número, convertido em wa.me.
     */
    static String normalizeSocialUrl(SocialPlatform platform, String value) {
        String url = value.trim();
        if (platform == SocialPlatform.WHATSAPP && !url.startsWith("http")) {
            String digits = BrazilianDocuments.digitsOnly(url);
            if (digits.length() < 10) {
                throw new BadRequestException("Número de WhatsApp inválido");
            }
            return "https://wa.me/" + (digits.length() <= 11 ? "55" + digits : digits);
        }
        if (!url.startsWith("http://") && !url.startsWith("https://")) {
            url = "https://" + url;
        }
        if (url.contains(" ") || !url.substring(url.indexOf("//") + 2).contains(".")) {
            throw new BadRequestException("Link inválido para " + platform.getDisplayName());
        }
        return url;
    }

    static String maskPlate(String plate) {
        if (plate == null || plate.isBlank()) {
            return null;
        }
        String clean = plate.replaceAll("[^A-Za-z0-9]", "");
        if (clean.length() <= 4) {
            return clean;
        }
        return clean.substring(0, 3) + "*".repeat(clean.length() - 5) + clean.substring(clean.length() - 2);
    }

    private String generateSlug(String fullName) {
        String base = slugify(fullName);
        for (int attempt = 0; attempt < 20; attempt++) {
            String candidate = base + "-" + randomSuffix(attempt < 10 ? 4 : 6);
            if (!deliveryPersonRepository.existsBySlug(candidate)) {
                return candidate;
            }
        }
        throw new IllegalStateException("Não foi possível gerar um identificador público único");
    }

    /**
     * Primeiro e último nome, sem acento, em minúsculas e separados por hífen
     */
    static String slugify(String fullName) {
        String normalized = Normalizer.normalize(fullName == null ? "" : fullName, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "")
                .toLowerCase(Locale.ROOT)
                .replaceAll("[^a-z0-9 ]", " ")
                .trim();
        if (normalized.isEmpty()) {
            return "entregador";
        }
        String[] parts = normalized.split("\\s+");
        String slug = parts.length == 1 ? parts[0] : parts[0] + "-" + parts[parts.length - 1];
        return slug.length() > 40 ? slug.substring(0, 40) : slug;
    }

    private static String randomSuffix(int length) {
        StringBuilder sb = new StringBuilder(length);
        for (int i = 0; i < length; i++) {
            sb.append(SLUG_ALPHABET.charAt(RANDOM.nextInt(SLUG_ALPHABET.length())));
        }
        return sb.toString();
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
