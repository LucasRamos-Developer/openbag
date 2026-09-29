package com.openbag.modules.organization.service;

import com.openbag.enums.MembershipStatus;
import com.openbag.enums.OrganizationStatus;
import com.openbag.enums.PartnershipSide;
import com.openbag.enums.UserType;
import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.platform.web.exception.ResourceNotFoundException;
import com.openbag.modules.delivery.entity.RestaurantPartnership;
import com.openbag.modules.delivery.repository.RestaurantPartnershipRepository;
import com.openbag.modules.delivery.service.PartnershipService;
import com.openbag.modules.organization.dto.AssociationDTO;
import com.openbag.modules.organization.dto.AssociationDataRequest;
import com.openbag.modules.organization.dto.AssociationOnboardingRequest;
import com.openbag.modules.organization.dto.AssociationStatsDTO;
import com.openbag.modules.organization.dto.AssociationSummaryDTO;
import com.openbag.modules.organization.dto.AssociationUpdateRequest;
import com.openbag.modules.organization.dto.DeliveryRateDTO;
import com.openbag.modules.organization.entity.Organization;
import com.openbag.modules.organization.repository.AssociationInviteRepository;
import com.openbag.modules.organization.repository.AssociationMembershipRepository;
import com.openbag.modules.organization.repository.OrganizationRepository;
import com.openbag.platform.files.FileStorageService;
import com.openbag.platform.util.BrazilianDocuments;
import com.openbag.modules.user.dto.AddressDTO;
import com.openbag.modules.user.entity.Address;
import com.openbag.modules.user.entity.Role;
import com.openbag.modules.user.entity.User;
import com.openbag.modules.user.service.AccountService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Ciclo de vida da associação/cooperativa: auto-cadastro, dados, estatísticas e moderação pelo ADMIN
 */
@Service
@Transactional
@Slf4j
public class AssociationService {

    private static final String LOGO_FOLDER = "associations";

    @Autowired
    private RestaurantPartnershipRepository partnershipRepository;

    @Autowired
    private OrganizationRepository organizationRepository;

    @Autowired
    private AssociationMembershipRepository membershipRepository;

    @Autowired
    private AssociationInviteRepository inviteRepository;

    @Autowired
    private AccountService accountService;

    @Autowired
    private FileStorageService fileStorageService;

    // ============= Cadastro =============

    /**
     * Cadastra a associação e seu gestor. A associação nasce PENDING_APPROVAL
     * e só passa a aceitar associados depois de aprovada por um ADMIN.
     */
    public AssociationDTO register(AssociationOnboardingRequest request, MultipartFile logo) {
        AssociationDataRequest data = request.getAssociation();
        String cnpj = normalizeCnpj(data.getCnpj());

        if (organizationRepository.existsByCnpj(cnpj)) {
            throw new BadRequestException("CNPJ já cadastrado");
        }
        accountService.validateAvailable(request.getManager());

        User manager = accountService.createAccount(request.getManager(), UserType.ORGANIZATION,
                Role.RoleName.CUSTOMER.name(), Role.RoleName.ASSOCIATION_MANAGER.name());

        Organization organization = new Organization();
        organization.setCnpj(cnpj);
        applyData(organization, data);
        organization.setStatus(OrganizationStatus.PENDING_APPROVAL);
        organization.setAdminUser(manager);
        organization.setAddress(toAddress(request.getAddress(), new Address()));

        if (logo != null && !logo.isEmpty()) {
            organization.setLogoUrl(fileStorageService.storeImage(logo, LOGO_FOLDER));
        }

        Organization saved = organizationRepository.save(organization);
        log.info("Associação {} cadastrada (gestor {}), aguardando aprovação", saved.getId(), manager.getId());
        return AssociationDTO.from(saved);
    }

    // ============= Gestor =============

    @Transactional(readOnly = true)
    public AssociationDTO getManagedAssociation(User manager) {
        return organizationRepository.findByAdminUserId(manager.getId()).stream()
                .findFirst()
                .map(AssociationDTO::from)
                .orElseThrow(() -> new ResourceNotFoundException("Nenhuma associação vinculada a este usuário"));
    }

    @Transactional(readOnly = true)
    public AssociationDTO getAssociation(Long organizationId) {
        return AssociationDTO.from(findById(organizationId));
    }

    /**
     * Atualiza os dados da associação. Uma associação recusada que é editada volta para análise.
     */
    public AssociationDTO update(Long organizationId, AssociationUpdateRequest request) {
        Organization organization = findById(organizationId);
        applyData(organization, request.getAssociation());

        if (request.getAddress() != null) {
            Address address = organization.getAddress() != null ? organization.getAddress() : new Address();
            organization.setAddress(toAddress(request.getAddress(), address));
        }

        if (organization.getStatus() == OrganizationStatus.REJECTED) {
            organization.setStatus(OrganizationStatus.PENDING_APPROVAL);
            organization.setRejectionReason(null);
            log.info("Associação {} reenviada para análise após edição", organizationId);
        }

        return AssociationDTO.from(organizationRepository.save(organization));
    }

    public AssociationDTO updateLogo(Long organizationId, MultipartFile logo) {
        if (logo == null || logo.isEmpty()) {
            throw new BadRequestException("Arquivo de logo é obrigatório");
        }
        Organization organization = findById(organizationId);
        String previousLogo = organization.getLogoUrl();

        organization.setLogoUrl(fileStorageService.storeImage(logo, LOGO_FOLDER));
        organizationRepository.save(organization);

        if (previousLogo != null) {
            fileStorageService.deleteFile(previousLogo);
        }
        return AssociationDTO.from(organization);
    }

    /**
     * Define a tabela de valores de entrega (base até X km + adicional por km)
     */
    public AssociationDTO updateDeliveryRate(Long organizationId, DeliveryRateDTO request) {
        Organization organization = findOperational(organizationId);
        organization.setDeliveryRate(request.toEntity());
        log.info("Associação {} atualizou a tabela de entrega: {}", organizationId, organization.getDeliveryRate());
        return AssociationDTO.from(organizationRepository.save(organization));
    }

    @Transactional(readOnly = true)
    public AssociationStatsDTO getStats(Long organizationId) {
        findById(organizationId);

        Map<String, Long> byStatus = new LinkedHashMap<>();
        for (MembershipStatus status : MembershipStatus.values()) {
            byStatus.put(status.name(), 0L);
        }
        for (Object[] row : membershipRepository.countByStatus(organizationId)) {
            byStatus.put(((MembershipStatus) row[0]).name(), (Long) row[1]);
        }

        Map<String, Long> byVehicle = new LinkedHashMap<>();
        for (Object[] row : membershipRepository.countActiveByVehicleType(organizationId)) {
            byVehicle.put(row[0] != null ? row[0].toString() : "UNKNOWN", (Long) row[1]);
        }

        List<RestaurantPartnership> partnerships = partnershipRepository.findByOrganization(organizationId);

        long activeInvites = inviteRepository.findByOrganizationIdOrderByCreatedAtDesc(organizationId).stream()
                .filter(invite -> invite.isUsable())
                .count();

        return AssociationStatsDTO.builder()
                .activeMembers(byStatus.get(MembershipStatus.ACTIVE.name()))
                .pendingRequests(byStatus.get(MembershipStatus.PENDING.name()))
                .suspendedMembers(byStatus.get(MembershipStatus.SUSPENDED.name()))
                .availableNow(membershipRepository.countAvailableNow(organizationId))
                .totalDeliveries(membershipRepository.sumActiveDeliveries(organizationId))
                .activeInvites(activeInvites)
                .activePartners(partnerships.stream().filter(RestaurantPartnership::isActive).count())
                .pendingPartnerships(PartnershipService.pendingFor(partnerships, PartnershipSide.ASSOCIATION))
                .membersByStatus(byStatus)
                .activeMembersByVehicleType(byVehicle)
                .build();
    }

    // ============= Público =============

    @Transactional(readOnly = true)
    public List<AssociationSummaryDTO> listActiveAssociations() {
        return organizationRepository.findByStatusOrderByTradingNameAsc(OrganizationStatus.ACTIVE).stream()
                .map(AssociationSummaryDTO::from)
                .toList();
    }

    // ============= ADMIN =============

    @Transactional(readOnly = true)
    public Page<AssociationDTO> listForAdmin(OrganizationStatus status, Pageable pageable) {
        Page<Organization> page = status != null
                ? organizationRepository.findByStatus(status, pageable)
                : organizationRepository.findAll(pageable);
        return page.map(AssociationDTO::from);
    }

    /**
     * Aprova (ou reativa) uma associação
     */
    public AssociationDTO approve(Long organizationId, User admin) {
        Organization organization = findById(organizationId);
        if (organization.getStatus() == OrganizationStatus.ACTIVE) {
            throw new BadRequestException("Associação já está ativa");
        }
        organization.setStatus(OrganizationStatus.ACTIVE);
        organization.setRejectionReason(null);
        organization.setApprovedAt(LocalDateTime.now());
        organization.setApprovedBy(admin);
        log.info("Associação {} aprovada pelo ADMIN {}", organizationId, admin.getId());
        return AssociationDTO.from(organizationRepository.save(organization));
    }

    public AssociationDTO reject(Long organizationId, String reason, User admin) {
        Organization organization = findById(organizationId);
        if (organization.getStatus() != OrganizationStatus.PENDING_APPROVAL) {
            throw new BadRequestException("Somente associações aguardando aprovação podem ser recusadas");
        }
        if (reason == null || reason.isBlank()) {
            throw new BadRequestException("Informe o motivo da recusa");
        }
        organization.setStatus(OrganizationStatus.REJECTED);
        organization.setRejectionReason(reason.trim());
        log.info("Associação {} recusada pelo ADMIN {}", organizationId, admin.getId());
        return AssociationDTO.from(organizationRepository.save(organization));
    }

    public AssociationDTO suspend(Long organizationId, String reason, User admin) {
        Organization organization = findById(organizationId);
        if (organization.getStatus() != OrganizationStatus.ACTIVE) {
            throw new BadRequestException("Somente associações ativas podem ser suspensas");
        }
        organization.setStatus(OrganizationStatus.SUSPENDED);
        organization.setRejectionReason(reason != null && !reason.isBlank() ? reason.trim() : null);
        log.info("Associação {} suspensa pelo ADMIN {}", organizationId, admin.getId());
        return AssociationDTO.from(organizationRepository.save(organization));
    }

    // ============= Helpers =============

    public Organization findById(Long organizationId) {
        return organizationRepository.findById(organizationId)
                .orElseThrow(() -> new ResourceNotFoundException("Associação não encontrada"));
    }

    /**
     * Garante que a associação foi aprovada e está ativa (pode aceitar associados)
     */
    public Organization findOperational(Long organizationId) {
        Organization organization = findById(organizationId);
        if (!organization.isOperational()) {
            throw new BadRequestException("A associação ainda não está ativa na plataforma");
        }
        return organization;
    }

    private String normalizeCnpj(String cnpj) {
        if (!BrazilianDocuments.isValidCnpj(cnpj)) {
            throw new BadRequestException("CNPJ inválido");
        }
        return BrazilianDocuments.normalizeCnpj(cnpj);
    }

    private void applyData(Organization organization, AssociationDataRequest data) {
        organization.setType(data.getType());
        organization.setCompanyName(data.getCompanyName().trim());
        organization.setTradingName(data.getTradingName().trim());
        organization.setDescription(data.getDescription());
        organization.setPhoneNumber(data.getPhoneNumber());
        organization.setContactEmail(data.getContactEmail());
    }

    private Address toAddress(AddressDTO dto, Address address) {
        address.setStreet(dto.getStreet());
        address.setNumber(dto.getNumber());
        address.setComplement(dto.getComplement());
        address.setNeighborhood(dto.getNeighborhood());
        address.setCity(dto.getCity());
        address.setState(dto.getState());
        address.setZipCode(dto.getZipCode());
        address.setLatitude(dto.getLatitude() != null ? dto.getLatitude().doubleValue() : null);
        address.setLongitude(dto.getLongitude() != null ? dto.getLongitude().doubleValue() : null);
        return address;
    }
}
