package com.openbag.modules.delivery.service;

import com.openbag.enums.CourierLinkStatus;
import com.openbag.enums.CourierPolicy;
import com.openbag.enums.DeliveryFeeMode;
import com.openbag.enums.PartnershipSide;
import com.openbag.enums.PartnershipStatus;
import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.platform.web.exception.ConflictException;
import com.openbag.platform.web.exception.ResourceNotFoundException;
import com.openbag.modules.delivery.dto.PartnerDTO;
import com.openbag.modules.delivery.dto.RateProposalRequest;
import com.openbag.modules.delivery.dto.RestaurantDeliverySettingsDTO;
import com.openbag.modules.delivery.dto.RestaurantDeliverySettingsRequest;
import com.openbag.modules.delivery.entity.RestaurantPartnership;
import com.openbag.modules.delivery.repository.RestaurantCourierLinkRepository;
import com.openbag.modules.delivery.repository.RestaurantPartnershipRepository;
import com.openbag.restaurant.store.entity.Restaurant;
import com.openbag.restaurant.store.repository.RestaurantRepository;
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
 * Regra da taxa: o entregador recebe o valor da tabela que vale na loja (a especial combinada na parceria ou a da
 * associação); o cliente paga a taxa do restaurante. Um parceiro cujo valor base passa da taxa só é aceito se o
 * restaurante assumir a diferença. As parcerias em si ficam no {@link PartnershipService}.
 */
@Service
@Transactional
@Slf4j
public class RestaurantDeliveryService {

    @Autowired
    private RestaurantRepository restaurantRepository;

    @Autowired
    private RestaurantPartnershipRepository partnershipRepository;

    @Autowired
    private RestaurantCourierLinkRepository linkRepository;

    @Autowired
    private PartnershipService partnershipService;

    // Parcerias recusadas ou encerradas mostradas no painel da loja
    private static final int HISTORY_SIZE = 10;

    // Distâncias da simulação da taxa repassada ao cliente
    private static final List<Double> SIMULATED_KM = List.of(2.0, 5.0, 8.0, 12.0);

    @Autowired
    private DeliveryFeeQuoteService deliveryFeeQuoteService;

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
        DeliveryFeeMode feeMode = request.getDeliveryFeeMode() != null
                ? request.getDeliveryFeeMode()
                : restaurant.getDeliveryFeeMode();
        if (feeMode == DeliveryFeeMode.ASSUME && !request.isCoversDeliveryDifference()) {
            assertPartnersFitFee(partners, restaurant.getDeliveryFee());
        }

        restaurant.setDeliveryFeeMode(feeMode);
        restaurant.setCourierPolicy(request.getCourierPolicy());
        restaurant.setPartnersEndedNoticeAt(null);
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
        log.info("Restaurante {} atualizou as regras de entrega: {} (fallback={}, cobre diferença={}, taxa={})",
                restaurantId, request.getCourierPolicy(), request.isFallbackToOpen(),
                request.isCoversDeliveryDifference(), feeMode);
        return toDTO(restaurantRepository.save(restaurant));
    }

    public RestaurantDeliverySettingsDTO addPartner(Long restaurantId, Long organizationId) {
        partnershipService.requestByRestaurant(restaurantId, organizationId);
        return toDTO(findRestaurant(restaurantId));
    }

    public RestaurantDeliverySettingsDTO removePartner(Long restaurantId, Long organizationId) {
        partnershipService.endByRestaurant(restaurantId, organizationId);
        return toDTO(findRestaurant(restaurantId));
    }

    /** Aceitar, recusar ou encerrar uma parceria, ou responder a uma proposta de tabela (lado da loja) */
    public RestaurantDeliverySettingsDTO partnershipAction(Long restaurantId, Long partnershipId, String action) {
        PartnershipSide side = PartnershipSide.RESTAURANT;
        switch (action) {
            case "accept" -> partnershipService.accept(partnershipId, side, restaurantId);
            case "decline" -> partnershipService.decline(partnershipId, side, restaurantId);
            case "end" -> partnershipService.end(partnershipId, side, restaurantId);
            case "rate-accept" -> partnershipService.acceptRate(partnershipId, side, restaurantId);
            case "rate-decline" -> partnershipService.declineRate(partnershipId, side, restaurantId);
            case "rate-cancel" -> partnershipService.cancelRate(partnershipId, side, restaurantId);
            default -> throw new BadRequestException("Ação inválida");
        }
        return toDTO(findRestaurant(restaurantId));
    }

    public RestaurantDeliverySettingsDTO proposeRate(Long restaurantId, Long partnershipId,
                                                     RateProposalRequest request) {
        partnershipService.proposeRate(partnershipId, PartnershipSide.RESTAURANT, restaurantId, request);
        return toDTO(findRestaurant(restaurantId));
    }

    /**
     * Chamado quando o restaurante muda a taxa de entrega: a nova taxa não pode ficar abaixo do valor base
     * de um parceiro sem que o restaurante assuma a diferença.
     */
    @Transactional(readOnly = true)
    public void assertDeliveryFeeCovered(Restaurant restaurant, BigDecimal newDeliveryFee) {
        if (restaurant.isCoversDeliveryDifference() || restaurant.passesDeliveryFee()) {
            return;
        }
        assertPartnersFitFee(partnershipRepository.findActiveByRestaurant(restaurant.getId()), newDeliveryFee);
    }

    // ============= Auxiliares =============

    /** Vale a tabela de cada parceria na loja: a especial, se houver, ou a da associação */
    private void assertPartnersFitFee(List<RestaurantPartnership> partners, BigDecimal deliveryFee) {
        List<String> exceeding = partners.stream()
                .filter(p -> PartnerDTO.exceedsFee(p.getEffectiveRate(), deliveryFee))
                .map(p -> p.getOrganization().getTradingName())
                .toList();
        if (exceeding.isEmpty()) {
            return;
        }
        throw new ConflictException(String.format("O valor base de %s (parceira) é maior que a sua taxa de entrega. "
                + "Mantenha a opção de assumir a diferença ou encerre a parceria.", String.join(", ", exceeding)));
    }

    private RestaurantDeliverySettingsDTO toDTO(Restaurant restaurant) {
        BigDecimal fee = restaurant.getDeliveryFee();
        List<RestaurantPartnership> partnerships = partnershipRepository.findByRestaurant(restaurant.getId());
        return RestaurantDeliverySettingsDTO.builder()
                .courierPolicy(restaurant.getCourierPolicy())
                .fallbackToOpen(restaurant.isFallbackToOpen())
                .coversDeliveryDifference(restaurant.isCoversDeliveryDifference())
                .coversDeliveryDifferenceAcceptedAt(restaurant.getCoversDeliveryDifferenceAcceptedAt())
                .deliveryFee(fee)
                .deliveryFeeMode(restaurant.getDeliveryFeeMode())
                .deliveryFeeFrom(deliveryFeeQuoteService.passThroughFee(restaurant, null))
                .deliveryFeeSimulation(SIMULATED_KM.stream()
                        .map(km -> new RestaurantDeliverySettingsDTO.FeeSample(km,
                                deliveryFeeQuoteService.passThroughFee(restaurant, km)))
                        .toList())
                .partners(partnerships.stream()
                        .filter(p -> p.getStatus() == PartnershipStatus.ACTIVE)
                        .map(p -> PartnerDTO.from(p, fee))
                        .toList())
                .partnershipRequests(partnerships.stream()
                        .filter(p -> p.getStatus() == PartnershipStatus.PENDING)
                        .map(p -> PartnerDTO.from(p, fee))
                        .toList())
                .partnershipHistory(partnerships.stream()
                        .filter(p -> p.getStatus() == PartnershipStatus.DECLINED
                                || p.getStatus() == PartnershipStatus.ENDED)
                        .limit(HISTORY_SIZE)
                        .map(p -> PartnerDTO.from(p, fee))
                        .toList())
                .pendingPartnershipActions(PartnershipService.pendingFor(partnerships, PartnershipSide.RESTAURANT))
                .partnersEndedNoticeAt(restaurant.getPartnersEndedNoticeAt())
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
