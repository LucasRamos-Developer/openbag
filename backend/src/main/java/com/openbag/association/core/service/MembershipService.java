package com.openbag.association.core.service;

import com.openbag.association.core.dto.MemberBillingFilter;
import com.openbag.association.core.entity.MembershipOrigin;
import com.openbag.association.core.entity.MembershipStatus;
import com.openbag.account.entity.UserType;
import com.openbag.delivery.courier.entity.VehicleType;
import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.platform.web.exception.ConflictException;
import com.openbag.platform.web.exception.ResourceNotFoundException;
import com.openbag.delivery.courier.entity.DeliveryPerson;
import com.openbag.delivery.courier.repository.DeliveryPersonRepository;
import com.openbag.delivery.courier.repository.VehicleRepository;
import com.openbag.delivery.courier.service.CourierProfileService;
import com.openbag.association.core.dto.AccountRequest;
import com.openbag.association.core.dto.CreateMemberRequest;
import com.openbag.association.core.dto.DeliveryPersonDataRequest;
import com.openbag.association.core.dto.DeliveryPersonRegisterRequest;
import com.openbag.association.core.dto.JoinAssociationRequest;
import com.openbag.association.core.dto.MemberDTO;
import com.openbag.association.core.entity.AssociationInvite;
import com.openbag.association.core.entity.AssociationMembership;
import com.openbag.association.core.entity.Organization;
import com.openbag.association.core.repository.AssociationMembershipRepository;
import com.openbag.platform.util.BrazilianDocuments;
import com.openbag.account.entity.Role;
import com.openbag.account.entity.User;
import com.openbag.account.repository.UserRepository;
import com.openbag.account.service.AccountService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.EnumSet;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Vínculos entre entregadores e associações.
 *
 * Regras:
 * - o entregador tem no máximo um vínculo em {@link MembershipStatus#OPEN} por vez;
 * - {@code DeliveryPerson.organization} aponta para a associação do vínculo aberto que já foi aprovado
 *   (ACTIVE ou SUSPENDED), e {@code DeliveryPerson.isActive} só é true com vínculo ACTIVE;
 * - associações só aceitam/gerenciam associados depois de aprovadas (status ACTIVE).
 */
@Service
@Transactional
@Slf4j
public class MembershipService {

    @Autowired
    private AssociationMembershipRepository membershipRepository;

    @Autowired
    private DeliveryPersonRepository deliveryPersonRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private VehicleRepository vehicleRepository;

    @Autowired
    private AccountService accountService;

    @Autowired
    private AssociationService associationService;

    @Autowired
    private InviteService inviteService;

    @Autowired
    private CourierProfileService courierProfileService;

    // ============= Gestor: consulta =============

    @Transactional(readOnly = true)
    public Page<MemberDTO> listMembers(Long organizationId, MembershipStatus status, VehicleType vehicleType,
                                       MemberBillingFilter billing, String query, Pageable pageable) {
        associationService.findById(organizationId);
        Set<MembershipStatus> statuses = status != null ? EnumSet.of(status) : EnumSet.allOf(MembershipStatus.class);
        String q = query != null ? query.trim() : "";
        Map<Long, Object[]> open = openInvoices(organizationId);
        return membershipRepository.search(organizationId, statuses, vehicleType == null,
                        vehicleType != null ? vehicleType : VehicleType.MOTORCYCLE,
                        (billing != null ? billing : MemberBillingFilter.ALL).name(), q, pageable)
                .map(membership -> withOpenInvoices(MemberDTO.from(membership), open.get(membership.getId())));
    }

    /** Faturas em aberto por associado: [membershipId, quantidade, total] */
    Map<Long, Object[]> openInvoices(Long organizationId) {
        return membershipRepository.openInvoicesByMembership(organizationId).stream()
                .collect(Collectors.toMap(row -> (Long) row[0], row -> row));
    }

    private static MemberDTO withOpenInvoices(MemberDTO dto, Object[] open) {
        if (open != null) {
            dto.setOpenInvoices(((Number) open[1]).intValue());
            dto.setOpenAmount((BigDecimal) open[2]);
        }
        return dto;
    }

    @Transactional(readOnly = true)
    public MemberDTO getMember(Long organizationId, Long membershipId) {
        AssociationMembership membership = findMembership(organizationId, membershipId);
        return withOpenInvoices(MemberDTO.from(membership,
                        vehicleRepository.findByDeliveryPersonIdAndArchivedFalseOrderByCreatedAtAsc(
                                membership.getDeliveryPerson().getId())),
                openInvoices(organizationId).get(membershipId));
    }

    // ============= Gestor: cadastro direto =============

    /**
     * O gestor cadastra o entregador (conta + perfil) e ele já entra como associado ativo
     */
    public MemberDTO createMember(Long organizationId, CreateMemberRequest request, User manager) {
        Organization organization = associationService.findOperational(organizationId);

        if (userRepository.existsByEmail(request.getAccount().getEmail().trim())) {
            throw new ConflictException(
                    "Já existe uma conta com este email. Gere um código de convite para o entregador entrar na associação.");
        }

        DeliveryPerson deliveryPerson = createDeliveryPerson(request.getAccount(), request.getDeliveryPerson());
        AssociationMembership membership = newMembership(organization, deliveryPerson, MembershipOrigin.MANAGER_CREATED);
        applyStatus(membership, MembershipStatus.ACTIVE, null, manager);

        log.info("Gestor {} cadastrou o entregador {} na associação {}", manager.getId(), deliveryPerson.getId(), organizationId);
        return MemberDTO.from(membershipRepository.save(membership));
    }

    // ============= Gestor: transições =============

    public MemberDTO approve(Long organizationId, Long membershipId, User manager) {
        return transition(organizationId, membershipId, EnumSet.of(MembershipStatus.PENDING),
                MembershipStatus.ACTIVE, null, manager);
    }

    public MemberDTO reject(Long organizationId, Long membershipId, String reason, User manager) {
        return transition(organizationId, membershipId, EnumSet.of(MembershipStatus.PENDING),
                MembershipStatus.REJECTED, reason, manager);
    }

    public MemberDTO suspend(Long organizationId, Long membershipId, String reason, User manager) {
        return transition(organizationId, membershipId, EnumSet.of(MembershipStatus.ACTIVE),
                MembershipStatus.SUSPENDED, reason, manager);
    }

    public MemberDTO reactivate(Long organizationId, Long membershipId, User manager) {
        return transition(organizationId, membershipId, EnumSet.of(MembershipStatus.SUSPENDED),
                MembershipStatus.ACTIVE, null, manager);
    }

    public MemberDTO remove(Long organizationId, Long membershipId, String reason, User manager) {
        return transition(organizationId, membershipId, EnumSet.of(MembershipStatus.ACTIVE, MembershipStatus.SUSPENDED),
                MembershipStatus.REMOVED, reason, manager);
    }

    // ============= Entregador =============

    /**
     * Auto-cadastro do entregador (endpoint público).
     * Com código de convite entra ACTIVE; com organizationId fica PENDING até o gestor decidir.
     */
    public MemberDTO registerDeliveryPerson(DeliveryPersonRegisterRequest request) {
        JoinTarget target = resolveTarget(request.getOrganizationId(), request.getInviteCode());
        accountService.validateAvailable(request.getAccount());

        DeliveryPerson deliveryPerson = createDeliveryPerson(request.getAccount(), request.getDeliveryPerson());
        return MemberDTO.from(join(deliveryPerson, target));
    }

    /**
     * Entregador já cadastrado pede entrada em uma associação (ou entra por convite)
     */
    public MemberDTO requestToJoin(User user, JoinAssociationRequest request) {
        DeliveryPerson deliveryPerson = deliveryPersonRepository.findByUserIdForUpdate(user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Perfil de entregador não encontrado"));

        if (findOpenMembership(deliveryPerson).isPresent()) {
            throw new BadRequestException(
                    "Você já possui um vínculo ativo ou pendente. Desligue-se antes de entrar em outra associação.");
        }

        JoinTarget target = resolveTarget(request.getOrganizationId(), request.getInviteCode());
        return MemberDTO.from(join(deliveryPerson, target));
    }

    @Transactional(readOnly = true)
    public Optional<MemberDTO> getMyMembership(User user) {
        DeliveryPerson deliveryPerson = deliveryPersonRepository.findByUserId(user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Perfil de entregador não encontrado"));
        return findOpenMembership(deliveryPerson).map(MemberDTO::from);
    }

    /**
     * O entregador se desliga da associação (ou cancela uma solicitação pendente)
     */
    public MemberDTO leave(User user, String reason) {
        DeliveryPerson deliveryPerson = deliveryPersonRepository.findByUserIdForUpdate(user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Perfil de entregador não encontrado"));
        AssociationMembership membership = findOpenMembership(deliveryPerson)
                .orElseThrow(() -> new BadRequestException("Você não está vinculado a nenhuma associação"));

        applyStatus(membership, MembershipStatus.LEFT, reason, user);
        log.info("Entregador {} saiu da associação {}", deliveryPerson.getId(), membership.getOrganization().getId());
        return MemberDTO.from(membershipRepository.save(membership));
    }

    // ============= Núcleo =============

    private MemberDTO transition(Long organizationId, Long membershipId, Set<MembershipStatus> allowedFrom,
                                 MembershipStatus target, String reason, User actor) {
        associationService.findOperational(organizationId);
        AssociationMembership membership = findMembership(organizationId, membershipId);

        if (!allowedFrom.contains(membership.getStatus())) {
            throw new BadRequestException(String.format("Não é possível mudar de %s para %s",
                    membership.getStatus().getDisplayName(), target.getDisplayName()));
        }

        applyStatus(membership, target, reason, actor);
        log.info("Vínculo {} da associação {} mudou para {} por {}", membershipId, organizationId, target, actor.getId());
        return MemberDTO.from(membershipRepository.save(membership));
    }

    /**
     * Aplica o novo status ao vínculo e mantém o cache do entregador (organization/isActive) consistente
     */
    private void applyStatus(AssociationMembership membership, MembershipStatus status, String reason, User actor) {
        LocalDateTime now = LocalDateTime.now();
        DeliveryPerson deliveryPerson = membership.getDeliveryPerson();

        membership.setStatus(status);
        membership.setDecidedAt(now);
        membership.setDecidedBy(actor);
        membership.setReason(reason != null && !reason.isBlank() ? reason.trim() : null);

        switch (status) {
            case ACTIVE -> {
                if (membership.getMemberNumber() == null) {
                    membership.setMemberNumber(
                            membershipRepository.findMaxMemberNumber(membership.getOrganization().getId()) + 1);
                }
                deliveryPerson.setOrganization(membership.getOrganization());
                deliveryPerson.setActive(true);
            }
            case SUSPENDED -> {
                deliveryPerson.setActive(false);
                deliveryPerson.setAvailable(false);
            }
            case REJECTED, REMOVED, LEFT -> {
                membership.setEndedAt(now);
                deliveryPerson.setOrganization(null);
                deliveryPerson.setActive(false);
                deliveryPerson.setAvailable(false);
            }
            case PENDING -> {
                deliveryPerson.setActive(false);
                deliveryPerson.setAvailable(false);
            }
        }
        deliveryPersonRepository.save(deliveryPerson);
    }

    private AssociationMembership join(DeliveryPerson deliveryPerson, JoinTarget target) {
        AssociationMembership membership;
        if (target.invite() != null) {
            membership = newMembership(target.organization(), deliveryPerson, MembershipOrigin.INVITE);
            membership.setInvite(target.invite());
            applyStatus(membership, MembershipStatus.ACTIVE, null, null);
        } else {
            membership = newMembership(target.organization(), deliveryPerson, MembershipOrigin.SELF_REQUEST);
            applyStatus(membership, MembershipStatus.PENDING, null, null);
            membership.setDecidedAt(null);
        }
        log.info("Entregador {} entrou na associação {} via {} ({})", deliveryPerson.getId(),
                target.organization().getId(), membership.getOrigin(), membership.getStatus());
        return membershipRepository.save(membership);
    }

    private JoinTarget resolveTarget(Long organizationId, String inviteCode) {
        if (inviteCode != null && !inviteCode.isBlank()) {
            AssociationInvite invite = inviteService.consume(inviteCode);
            return new JoinTarget(invite.getOrganization(), invite);
        }
        if (organizationId != null) {
            return new JoinTarget(associationService.findOperational(organizationId), null);
        }
        throw new BadRequestException("Informe a associação ou um código de convite");
    }

    private DeliveryPerson createDeliveryPerson(AccountRequest account, DeliveryPersonDataRequest data) {
        String cpf = BrazilianDocuments.digitsOnly(data.getDocumentNumber());
        if (!BrazilianDocuments.isValidCpf(cpf)) {
            throw new BadRequestException("CPF inválido");
        }
        if (deliveryPersonRepository.existsByDocumentNumber(cpf)) {
            throw new BadRequestException("CPF já cadastrado como entregador");
        }
        String driverLicense = BrazilianDocuments.digitsOnly(data.getDriverLicense());
        if (driverLicense.isBlank()) {
            throw new BadRequestException("CNH inválida");
        }
        if (deliveryPersonRepository.existsByDriverLicense(driverLicense)) {
            throw new BadRequestException("CNH já cadastrada");
        }
        boolean motorized = data.getVehicleType() == VehicleType.MOTORCYCLE || data.getVehicleType() == VehicleType.CAR;
        if (motorized && (data.getVehiclePlate() == null || data.getVehiclePlate().isBlank())) {
            throw new BadRequestException("Placa do veículo é obrigatória para moto e carro");
        }

        User user = accountService.createAccount(account, UserType.DELIVERY_PERSON,
                Role.RoleName.CUSTOMER.name(), Role.RoleName.DELIVERY_PERSON.name());

        DeliveryPerson deliveryPerson = new DeliveryPerson();
        deliveryPerson.setUser(user);
        deliveryPerson.setDocumentNumber(cpf);
        deliveryPerson.setDriverLicense(driverLicense);
        deliveryPerson.setVehicleType(data.getVehicleType());
        deliveryPerson.setVehiclePlate(data.getVehiclePlate() != null ? data.getVehiclePlate().trim().toUpperCase() : null);
        deliveryPerson.setVehicleModel(data.getVehicleModel());
        deliveryPerson.setVehicleColor(data.getVehicleColor());
        // Só fica ativo/disponível quando o vínculo com a associação estiver ACTIVE
        deliveryPerson.setActive(false);
        deliveryPerson.setAvailable(false);
        deliveryPerson = deliveryPersonRepository.save(deliveryPerson);
        courierProfileService.initializeProfile(deliveryPerson);
        return deliveryPerson;
    }

    private AssociationMembership newMembership(Organization organization, DeliveryPerson deliveryPerson,
                                                MembershipOrigin origin) {
        AssociationMembership membership = new AssociationMembership();
        membership.setOrganization(organization);
        membership.setDeliveryPerson(deliveryPerson);
        membership.setOrigin(origin);
        membership.setRequestedAt(LocalDateTime.now());
        return membership;
    }

    private Optional<AssociationMembership> findOpenMembership(DeliveryPerson deliveryPerson) {
        return membershipRepository.findByDeliveryPersonIdAndStatusIn(deliveryPerson.getId(), MembershipStatus.OPEN)
                .stream()
                .findFirst();
    }

    private AssociationMembership findMembership(Long organizationId, Long membershipId) {
        // Filtra pela organização do path: um gestor nunca acessa vínculos de outra associação
        return membershipRepository.findByIdAndOrganizationId(membershipId, organizationId)
                .orElseThrow(() -> new ResourceNotFoundException("Associado não encontrado"));
    }

    private record JoinTarget(Organization organization, AssociationInvite invite) {
    }
}
