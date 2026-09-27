package com.openbag.modules.delivery.service;

import com.openbag.enums.CourierLinkStatus;
import com.openbag.enums.CourierPolicy;
import com.openbag.exception.BadRequestException;
import com.openbag.exception.ConflictException;
import com.openbag.exception.ResourceNotFoundException;
import com.openbag.modules.delivery.dto.PartnerDTO;
import com.openbag.modules.delivery.dto.RestaurantDeliverySettingsDTO;
import com.openbag.modules.delivery.dto.RestaurantDeliverySettingsRequest;
import com.openbag.modules.delivery.entity.RestaurantPartnership;
import com.openbag.modules.delivery.repository.RestaurantCourierLinkRepository;
import com.openbag.modules.delivery.repository.RestaurantPartnershipRepository;
import com.openbag.modules.organization.entity.Organization;
import com.openbag.modules.organization.repository.OrganizationRepository;
import com.openbag.modules.restaurant.entity.Restaurant;
import com.openbag.modules.restaurant.repository.RestaurantRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.EnumSet;
import java.util.List;

/**
 * Regras de entrega do restaurante: política de entregadores, associações parceiras e cobertura da diferença.
 *
 * Regra da taxa: o entregador recebe o valor da tabela da associação dele; o cliente paga a taxa do restaurante.
 * Um parceiro cujo valor base passa da taxa só é aceito se o restaurante assumir a diferença.
 */
@Service
@Transactional
@Slf4j
public class RestaurantDeliveryService {

    @Autowired
    private RestaurantRepository restaurantRepository;

    @Autowired
    private OrganizationRepository organizationRepository;

    @Autowired
    private RestaurantPartnershipRepository partnershipRepository;

    @Autowired
    private RestaurantCourierLinkRepository linkRepository;

    @Transactional(readOnly = true)
    public RestaurantDeliverySettingsDTO getSettings(Long restaurantId) {
        return toDTO(findRestaurant(restaurantId));
    }

    public RestaurantDeliverySettingsDTO updateSettings(Long restaurantId, RestaurantDeliverySettingsRequest request) {
        Restaurant restaurant = findRestaurant(restaurantId);
        List<RestaurantPartnership> partners = partnershipRepository.findActiveByRestaurant(restaurantId);

        if (request.getCourierPolicy() == CourierPolicy.PARTNERS_ONLY && partners.isEmpty()) {
            throw new BadRequestException("Adicione ao menos uma associação parceira antes de restringir a elas");
        }
        if (!request.isCoversDeliveryDifference()) {
            assertPartnersFitFee(partners, restaurant.getDeliveryFee());
        }

        restaurant.setCourierPolicy(request.getCourierPolicy());
        restaurant.setFallbackToOpen(request.isFallbackToOpen());
        if (request.isCoversDeliveryDifference() && !restaurant.isCoversDeliveryDifference()) {
            restaurant.setCoversDeliveryDifferenceAcceptedAt(LocalDateTime.now());
        }
        if (!request.isCoversDeliveryDifference()) {
            restaurant.setCoversDeliveryDifferenceAcceptedAt(null);
        }
        restaurant.setCoversDeliveryDifference(request.isCoversDeliveryDifference());
        if (request.getCourierNoShowMinutes() != null) {
            restaurant.setCourierNoShowMinutes(request.getCourierNoShowMinutes());
        }
        log.info("Restaurante {} atualizou as regras de entrega: {} (fallback={}, cobre diferença={})", restaurantId,
                request.getCourierPolicy(), request.isFallbackToOpen(), request.isCoversDeliveryDifference());
        return toDTO(restaurantRepository.save(restaurant));
    }

    public RestaurantDeliverySettingsDTO addPartner(Long restaurantId, Long organizationId) {
        Restaurant restaurant = findRestaurant(restaurantId);
        Organization organization = organizationRepository.findById(organizationId)
                .filter(Organization::isOperational)
                .orElseThrow(() -> new ResourceNotFoundException("Associação não encontrada"));

        if (partnershipRepository.findActive(restaurantId, organizationId).isPresent()) {
            throw new BadRequestException("Esta associação já é parceira do restaurante");
        }
        if (!organization.isDeliveryRateConfigured()) {
            throw new BadRequestException("Esta associação ainda não definiu a tabela de valores de entrega");
        }
        if (!restaurant.isCoversDeliveryDifference()) {
            assertPartnersFitFee(List.of(organization), restaurant.getDeliveryFee(), true);
        }

        RestaurantPartnership partnership = new RestaurantPartnership();
        partnership.setRestaurant(restaurant);
        partnership.setOrganization(organization);
        partnershipRepository.save(partnership);
        log.info("Restaurante {} adicionou a associação {} como parceira", restaurantId, organizationId);
        return toDTO(restaurant);
    }

    public RestaurantDeliverySettingsDTO removePartner(Long restaurantId, Long organizationId) {
        Restaurant restaurant = findRestaurant(restaurantId);
        RestaurantPartnership partnership = partnershipRepository.findActive(restaurantId, organizationId)
                .orElseThrow(() -> new ResourceNotFoundException("Parceria não encontrada"));

        if (restaurant.getCourierPolicy() == CourierPolicy.PARTNERS_ONLY
                && partnershipRepository.findActiveByRestaurant(restaurantId).size() == 1) {
            throw new BadRequestException(
                    "Esta é a única parceira. Mude quem recebe os pedidos antes de encerrar a parceria.");
        }
        partnership.setEndedAt(LocalDateTime.now());
        partnershipRepository.save(partnership);
        return toDTO(restaurant);
    }

    /**
     * Chamado quando o restaurante muda a taxa de entrega: a nova taxa não pode ficar abaixo do valor base
     * de um parceiro sem que o restaurante assuma a diferença.
     */
    @Transactional(readOnly = true)
    public void assertDeliveryFeeCovered(Restaurant restaurant, BigDecimal newDeliveryFee) {
        if (restaurant.isCoversDeliveryDifference()) {
            return;
        }
        assertPartnersFitFee(partnershipRepository.findActiveByRestaurant(restaurant.getId()), newDeliveryFee);
    }

    // ============= Auxiliares =============

    private void assertPartnersFitFee(List<RestaurantPartnership> partners, BigDecimal deliveryFee) {
        assertPartnersFitFee(partners.stream().map(RestaurantPartnership::getOrganization).toList(), deliveryFee, false);
    }

    private void assertPartnersFitFee(List<Organization> organizations, BigDecimal deliveryFee, boolean adding) {
        List<String> exceeding = organizations.stream()
                .filter(org -> PartnerDTO.exceedsFee(org, deliveryFee))
                .map(Organization::getTradingName)
                .toList();
        if (exceeding.isEmpty()) {
            return;
        }
        String names = String.join(", ", exceeding);
        throw new ConflictException(adding
                ? String.format("O valor base de %s é maior que a sua taxa de entrega. Para ter esta parceria, "
                + "marque que o restaurante assume a diferença.", names)
                : String.format("O valor base de %s (parceira) é maior que a sua taxa de entrega. "
                + "Mantenha a opção de assumir a diferença ou encerre a parceria.", names));
    }

    private RestaurantDeliverySettingsDTO toDTO(Restaurant restaurant) {
        BigDecimal fee = restaurant.getDeliveryFee();
        return RestaurantDeliverySettingsDTO.builder()
                .courierPolicy(restaurant.getCourierPolicy())
                .fallbackToOpen(restaurant.isFallbackToOpen())
                .coversDeliveryDifference(restaurant.isCoversDeliveryDifference())
                .coversDeliveryDifferenceAcceptedAt(restaurant.getCoversDeliveryDifferenceAcceptedAt())
                .deliveryFee(fee)
                .partners(partnershipRepository.findActiveByRestaurant(restaurant.getId()).stream()
                        .map(p -> PartnerDTO.from(p, fee))
                        .toList())
                .activeFixedCouriers(linkRepository.findByRestaurant(restaurant.getId(),
                        EnumSet.of(CourierLinkStatus.ACTIVE)).size())
                .pendingFixedCouriers(linkRepository.findByRestaurant(restaurant.getId(),
                        EnumSet.of(CourierLinkStatus.PENDING)).size())
                .courierNoShowMinutes(restaurant.getCourierNoShowMinutes())
                .build();
    }

    private Restaurant findRestaurant(Long restaurantId) {
        return restaurantRepository.findById(restaurantId)
                .orElseThrow(() -> new ResourceNotFoundException("Restaurante não encontrado"));
    }
}
