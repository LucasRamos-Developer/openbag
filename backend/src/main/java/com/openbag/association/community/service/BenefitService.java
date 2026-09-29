package com.openbag.association.community.service;

import com.openbag.platform.web.exception.ResourceNotFoundException;
import com.openbag.association.community.dto.BenefitDTO;
import com.openbag.association.community.dto.BenefitRequest;
import com.openbag.association.community.entity.Benefit;
import com.openbag.association.community.repository.BenefitRepository;
import com.openbag.association.core.service.AssociationService;
import com.openbag.platform.files.FileStorageService;
import com.openbag.account.entity.User;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.Clock;
import java.time.LocalDate;
import java.util.List;
import com.openbag.association.member.service.MemberContext;

/**
 * Convênios da associação (oficinas, idiomas, descontos): o gestor cadastra e os cooperados veem os disponíveis
 */
@Service
@Transactional
public class BenefitService {

    @Autowired
    private BenefitRepository benefitRepository;

    @Autowired
    private AssociationService associationService;

    @Autowired
    private FileStorageService fileStorageService;

    @Autowired
    private MemberContext memberContext;

    @Autowired
    private Clock clock;

    @Transactional(readOnly = true)
    public List<BenefitDTO> list(Long organizationId) {
        LocalDate today = LocalDate.now(clock);
        return benefitRepository.findByOrganizationIdOrderByPartnerNameAsc(organizationId).stream()
                .map(b -> BenefitDTO.from(b, today))
                .toList();
    }

    public BenefitDTO create(Long organizationId, BenefitRequest request) {
        Benefit benefit = new Benefit();
        benefit.setOrganization(associationService.findOperational(organizationId));
        apply(benefit, request);
        return BenefitDTO.from(benefitRepository.save(benefit), LocalDate.now(clock));
    }

    public BenefitDTO update(Long organizationId, Long benefitId, BenefitRequest request) {
        Benefit benefit = find(organizationId, benefitId);
        apply(benefit, request);
        return BenefitDTO.from(benefitRepository.save(benefit), LocalDate.now(clock));
    }

    public BenefitDTO updateLogo(Long organizationId, Long benefitId, MultipartFile file) {
        Benefit benefit = find(organizationId, benefitId);
        String previous = benefit.getLogoUrl();
        benefit.setLogoUrl(fileStorageService.storeImage(file, "benefits"));
        fileStorageService.deleteFile(previous);
        return BenefitDTO.from(benefitRepository.save(benefit), LocalDate.now(clock));
    }

    public void delete(Long organizationId, Long benefitId) {
        Benefit benefit = find(organizationId, benefitId);
        fileStorageService.deleteFile(benefit.getLogoUrl());
        benefitRepository.delete(benefit);
    }

    /** Os convênios disponíveis hoje para o cooperado logado */
    @Transactional(readOnly = true)
    public List<BenefitDTO> forMember(User user) {
        LocalDate today = LocalDate.now(clock);
        return benefitRepository.findByOrganizationIdOrderByPartnerNameAsc(
                        memberContext.current(user).getOrganization().getId()).stream()
                .filter(b -> b.isAvailable(today))
                .map(b -> BenefitDTO.from(b, today))
                .toList();
    }

    private static void apply(Benefit benefit, BenefitRequest request) {
        benefit.setPartnerName(request.partnerName().trim());
        benefit.setCategory(request.category());
        benefit.setHeadline(request.headline().trim());
        benefit.setDescription(blankToNull(request.description()));
        benefit.setAddress(blankToNull(request.address()));
        benefit.setPhone(blankToNull(request.phone()));
        benefit.setLink(blankToNull(request.link()));
        benefit.setValidUntil(request.validUntil());
        if (request.active() != null) {
            benefit.setActive(request.active());
        }
    }

    private Benefit find(Long organizationId, Long benefitId) {
        return benefitRepository.findByIdAndOrganizationId(benefitId, organizationId)
                .orElseThrow(() -> new ResourceNotFoundException("Convênio não encontrado"));
    }

    private static String blankToNull(String text) {
        return text != null && !text.isBlank() ? text.trim() : null;
    }
}
