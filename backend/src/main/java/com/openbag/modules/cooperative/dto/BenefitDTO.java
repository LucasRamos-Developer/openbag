package com.openbag.modules.cooperative.dto;

import com.openbag.enums.BenefitCategory;
import com.openbag.modules.cooperative.entity.Benefit;

import java.time.LocalDate;

public record BenefitDTO(Long id, String partnerName, BenefitCategory category, String headline, String description,
                         String address, String phone, String link, String logoUrl, LocalDate validUntil,
                         boolean active, boolean available) {

    public static BenefitDTO from(Benefit benefit, LocalDate today) {
        return new BenefitDTO(benefit.getId(), benefit.getPartnerName(), benefit.getCategory(), benefit.getHeadline(),
                benefit.getDescription(), benefit.getAddress(), benefit.getPhone(), benefit.getLink(),
                benefit.getLogoUrl(), benefit.getValidUntil(), benefit.isActive(), benefit.isAvailable(today));
    }
}
