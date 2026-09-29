package com.openbag.association.finance.service;

import com.openbag.association.finance.entity.MemberAddonStatus;
import com.openbag.association.core.entity.MembershipStatus;
import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.platform.web.exception.ResourceNotFoundException;
import com.openbag.association.finance.dto.AddonPlanDTO;
import com.openbag.association.finance.dto.AddonPlanRequest;
import com.openbag.association.finance.dto.MemberAddonDTO;
import com.openbag.association.finance.entity.AddonPlan;
import com.openbag.association.finance.entity.MemberAddon;
import com.openbag.association.finance.repository.AddonPlanRepository;
import com.openbag.association.finance.repository.MemberAddonRepository;
import com.openbag.association.core.entity.AssociationMembership;
import com.openbag.association.core.entity.Organization;
import com.openbag.association.core.repository.AssociationMembershipRepository;
import com.openbag.association.core.service.AssociationService;
import com.openbag.account.entity.User;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.EnumSet;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import com.openbag.association.member.service.MemberContext;

/**
 * Adicionais da mensalidade (ex: seguro de vida): a associação cadastra e propõe; o cooperado aceita ou recusa.
 * Só o adicional ativo entra na fatura. Tanto a associação quanto o cooperado podem cancelar um adicional.
 */
@Service
@Transactional
@Slf4j
public class AddonService {

    @Autowired
    private AddonPlanRepository planRepository;

    @Autowired
    private MemberAddonRepository memberAddonRepository;

    @Autowired
    private AssociationMembershipRepository membershipRepository;

    @Autowired
    private AssociationService associationService;

    @Autowired
    private MemberContext memberContext;

    @Autowired
    private Clock clock;

    // ============= Planos (gestor) =============

    @Transactional(readOnly = true)
    public List<AddonPlanDTO> listPlans(Long organizationId) {
        Map<Long, Map<MemberAddonStatus, Long>> counts = memberAddonRepository
                .findByOrganizationAndStatusIn(organizationId, EnumSet.of(MemberAddonStatus.ACTIVE, MemberAddonStatus.PROPOSED))
                .stream()
                .collect(Collectors.groupingBy(a -> a.getPlan().getId(),
                        Collectors.groupingBy(MemberAddon::getStatus, Collectors.counting())));
        return planRepository.findByOrganizationIdOrderByNameAsc(organizationId).stream()
                .map(plan -> {
                    Map<MemberAddonStatus, Long> c = counts.getOrDefault(plan.getId(), Map.of());
                    return AddonPlanDTO.from(plan, c.getOrDefault(MemberAddonStatus.ACTIVE, 0L),
                            c.getOrDefault(MemberAddonStatus.PROPOSED, 0L));
                })
                .toList();
    }

    public AddonPlanDTO createPlan(Long organizationId, AddonPlanRequest request) {
        Organization organization = associationService.findOperational(organizationId);
        AddonPlan plan = new AddonPlan();
        plan.setOrganization(organization);
        apply(plan, request);
        return AddonPlanDTO.from(planRepository.save(plan), 0, 0);
    }

    public AddonPlanDTO updatePlan(Long organizationId, Long planId, AddonPlanRequest request) {
        AddonPlan plan = findPlan(organizationId, planId);
        apply(plan, request);
        return AddonPlanDTO.from(planRepository.save(plan), 0, 0);
    }

    private static void apply(AddonPlan plan, AddonPlanRequest request) {
        plan.setName(request.name().trim());
        plan.setDescription(request.description() != null && !request.description().isBlank()
                ? request.description().trim() : null);
        plan.setPricing(request.pricing());
        plan.setValue(request.value());
        if (request.active() != null) {
            plan.setActive(request.active());
        }
    }

    /**
     * Propõe o adicional aos cooperados escolhidos (vazio = todos os ativos). Quem já tem o adicional proposto ou
     * ativo fica de fora. Devolve quantos receberam a proposta.
     */
    public int propose(Long organizationId, Long planId, List<Long> membershipIds) {
        AddonPlan plan = findPlan(organizationId, planId);
        if (!plan.isActive()) {
            throw new BadRequestException("Reative o adicional antes de propor");
        }
        List<AssociationMembership> targets = membershipIds == null || membershipIds.isEmpty()
                ? membershipRepository.findByOrganizationId(organizationId).stream()
                    .filter(m -> m.getStatus() == MembershipStatus.ACTIVE)
                    .toList()
                : membershipIds.stream()
                    .map(id -> membershipRepository.findByIdAndOrganizationId(id, organizationId)
                            .orElseThrow(() -> new ResourceNotFoundException("Associado não encontrado")))
                    .toList();

        int proposed = 0;
        for (AssociationMembership membership : targets) {
            if (memberAddonRepository.existsOpen(membership.getId(), plan.getId())) {
                continue;
            }
            MemberAddon addon = new MemberAddon();
            addon.setMembership(membership);
            addon.setPlan(plan);
            addon.setStatus(MemberAddonStatus.PROPOSED);
            memberAddonRepository.save(addon);
            proposed++;
        }
        log.info("Associação {}: adicional {} proposto a {} cooperado(s)", organizationId, planId, proposed);
        return proposed;
    }

    @Transactional(readOnly = true)
    public List<MemberAddonDTO> listForMember(Long organizationId, Long membershipId) {
        membershipRepository.findByIdAndOrganizationId(membershipId, organizationId)
                .orElseThrow(() -> new ResourceNotFoundException("Associado não encontrado"));
        return memberAddonRepository.findByMembership(membershipId).stream().map(MemberAddonDTO::from).toList();
    }

    public MemberAddonDTO cancelByAssociation(Long organizationId, Long memberAddonId) {
        MemberAddon addon = memberAddonRepository.findByIdAndOrganization(memberAddonId, organizationId)
                .orElseThrow(() -> new ResourceNotFoundException("Adicional não encontrado"));
        return MemberAddonDTO.from(cancel(addon));
    }

    // ============= Cooperado =============

    @Transactional(readOnly = true)
    public List<MemberAddonDTO> mine(User user) {
        return memberAddonRepository.findByMembership(memberContext.current(user).getId()).stream()
                .map(MemberAddonDTO::from)
                .toList();
    }

    /** accept, decline ou cancel */
    public MemberAddonDTO answer(User user, Long memberAddonId, String action) {
        AssociationMembership membership = memberContext.current(user);
        MemberAddon addon = memberAddonRepository.findById(memberAddonId)
                .filter(a -> a.getMembership().getId().equals(membership.getId()))
                .orElseThrow(() -> new ResourceNotFoundException("Adicional não encontrado"));
        return MemberAddonDTO.from(switch (action) {
            case "accept", "decline" -> {
                if (addon.getStatus() != MemberAddonStatus.PROPOSED) {
                    throw new BadRequestException("Este adicional não está aguardando sua resposta");
                }
                addon.setStatus(action.equals("accept") ? MemberAddonStatus.ACTIVE : MemberAddonStatus.DECLINED);
                addon.setDecidedAt(LocalDateTime.now(clock));
                yield memberAddonRepository.save(addon);
            }
            case "cancel" -> cancel(addon);
            default -> throw new BadRequestException("Ação inválida");
        });
    }

    // ============= Auxiliares =============

    /** Adicionais ativos de cada cooperado da associação (para a fatura) */
    @Transactional(readOnly = true)
    public Map<Long, List<AddonPlan>> activeByMembership(Long organizationId) {
        return memberAddonRepository.findByOrganizationAndStatusIn(organizationId, EnumSet.of(MemberAddonStatus.ACTIVE))
                .stream()
                .collect(Collectors.groupingBy(a -> a.getMembership().getId(),
                        Collectors.mapping(MemberAddon::getPlan, Collectors.toList())));
    }

    private MemberAddon cancel(MemberAddon addon) {
        if (!addon.isOpen()) {
            throw new BadRequestException("Este adicional já foi encerrado");
        }
        addon.setStatus(MemberAddonStatus.CANCELLED);
        addon.setCancelledAt(LocalDateTime.now(clock));
        return memberAddonRepository.save(addon);
    }

    private AddonPlan findPlan(Long organizationId, Long planId) {
        return planRepository.findByIdAndOrganizationId(planId, organizationId)
                .orElseThrow(() -> new ResourceNotFoundException("Adicional não encontrado"));
    }
}
