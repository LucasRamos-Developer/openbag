package com.openbag.modules.organization.dto;

import com.openbag.enums.OrganizationStatus;
import com.openbag.enums.OrganizationType;
import com.openbag.modules.organization.entity.Organization;
import com.openbag.modules.user.dto.AddressDTO;
import com.openbag.modules.user.entity.Address;
import com.openbag.modules.user.entity.User;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AssociationDTO {

    private Long id;
    private OrganizationType type;
    private OrganizationStatus status;
    private String companyName;
    private String tradingName;
    private String cnpj;
    private String description;
    private String phoneNumber;
    private String contactEmail;
    private String logoUrl;
    private String rejectionReason;
    private LocalDateTime approvedAt;
    private LocalDateTime createdAt;
    private AddressDTO address;
    private ManagerSummary manager;
    private DeliveryRateDTO deliveryRate;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ManagerSummary {
        private Long id;
        private String fullName;
        private String email;
        private String phoneNumber;
    }

    public static AssociationDTO from(Organization organization) {
        User admin = organization.getAdminUser();
        return AssociationDTO.builder()
                .id(organization.getId())
                .type(organization.getType())
                .status(organization.getStatus())
                .companyName(organization.getCompanyName())
                .tradingName(organization.getTradingName())
                .cnpj(organization.getCnpj())
                .description(organization.getDescription())
                .phoneNumber(organization.getPhoneNumber())
                .contactEmail(organization.getContactEmail())
                .logoUrl(organization.getLogoUrl())
                .rejectionReason(organization.getRejectionReason())
                .approvedAt(organization.getApprovedAt())
                .createdAt(organization.getCreatedAt())
                .address(toAddressDTO(organization.getAddress()))
                .deliveryRate(DeliveryRateDTO.from(organization.getDeliveryRate()))
                .manager(admin == null ? null
                        : new ManagerSummary(admin.getId(), admin.getFullName(), admin.getEmail(), admin.getPhoneNumber()))
                .build();
    }

    static AddressDTO toAddressDTO(Address address) {
        if (address == null) {
            return null;
        }
        AddressDTO dto = new AddressDTO(address.getStreet(), address.getNumber(), address.getComplement(),
                address.getNeighborhood(), address.getCity(), address.getState(), address.getZipCode());
        dto.setId(address.getId());
        dto.setLatitude(address.getLatitude() != null ? BigDecimal.valueOf(address.getLatitude()) : null);
        dto.setLongitude(address.getLongitude() != null ? BigDecimal.valueOf(address.getLongitude()) : null);
        return dto;
    }
}
