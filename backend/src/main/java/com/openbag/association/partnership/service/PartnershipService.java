package com.openbag.association.partnership.service;

import com.openbag.restaurant.store.entity.CourierPolicy;
import com.openbag.association.partnership.entity.PartnershipSide;
import com.openbag.association.partnership.entity.PartnershipStatus;
import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.platform.web.exception.ConflictException;
import com.openbag.platform.web.exception.ResourceNotFoundException;
import com.openbag.association.partnership.dto.PartnerDTO;
import com.openbag.association.partnership.dto.RateProposalRequest;
import com.openbag.association.partnership.entity.RestaurantPartnership;
import com.openbag.association.partnership.repository.RestaurantPartnershipRepository;
import com.openbag.association.core.entity.DeliveryRate;
import com.openbag.association.core.entity.Organization;
import com.openbag.association.core.repository.OrganizationRepository;
import com.openbag.restaurant.store.entity.Restaurant;
import com.openbag.restaurant.store.repository.RestaurantRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.text.NumberFormat;
import java.time.Clock;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * Parcerias entre restaurantes e associações: pedido, aceite, recusa, encerramento e tabela especial (acordo).
 *
 * Um lado pede e só o outro decide. Qualquer lado encerra. A tabela especial só muda com o aceite dos dois:
 * um propõe e o outro aceita, recusa ou manda uma contraproposta (que troca a proposta e passa a vez).
 * O pedido de parceria pode já trazer a tabela proposta; aceitar o pedido aceita também a última proposta.
 * O entregador sempre recebe 100% da tabela que vale na loja.
 */
@Service
@Transactional
@Slf4j
public class PartnershipService {

    @Autowired
    private RestaurantPartnershipRepository partnershipRepository;

    @Autowired
    private RestaurantRepository restaurantRepository;

    @Autowired
    private OrganizationRepository organizationRepository;

    @Autowired
    private Clock clock;

    // ============= Pedido =============

    /** O restaurante pede parceria; se a associação já tinha convidado, a parceria começa na hora */
    public RestaurantPartnership requestByRestaurant(Long restaurantId, Long organizationId) {
        return request(findRestaurant(restaurantId), findOperationalAssociation(organizationId),
                PartnershipSide.RESTAURANT, null);
    }

    /** A associação convida a loja; se a loja já tinha pedido, a parceria começa na hora */
    public RestaurantPartnership requestByAssociation(Long organizationId, Long restaurantId) {
        return requestByAssociation(organizationId, restaurantId, null);
    }

    /**
     * A associação convida a loja já propondo uma tabela especial (null = a tabela padrão da associação).
     * A loja aceita, recusa ou manda uma contraproposta.
     */
    public RestaurantPartnership requestByAssociation(Long organizationId, Long restaurantId, DeliveryRate proposedRate) {
        Restaurant restaurant = restaurantRepository.findById(restaurantId)
                .filter(Restaurant::isActive)
                .orElseThrow(() -> new ResourceNotFoundException("Loja não encontrada"));
        return request(restaurant, findOperationalAssociation(organizationId), PartnershipSide.ASSOCIATION,
                proposedRate);
    }

    private RestaurantPartnership request(Restaurant restaurant, Organization organization, PartnershipSide side,
                                          DeliveryRate proposedRate) {
        if (!organization.isDeliveryRateConfigured()) {
            throw new BadRequestException(side == PartnershipSide.RESTAURANT
                    ? "Esta associação ainda não definiu a tabela de valores de entrega"
                    : "Defina a tabela de valores de entrega antes de convidar lojas");
        }

        var open = partnershipRepository.findOpen(restaurant.getId(), organization.getId());
        if (open.isPresent()) {
            RestaurantPartnership existing = open.get();
            if (existing.getStatus() == PartnershipStatus.PENDING && existing.getAwaitingSide() == side) {
                return accept(existing, side);
            }
            throw new BadRequestException(existing.isActive()
                    ? "A parceria já está ativa"
                    : "O pedido de parceria já foi enviado e aguarda resposta");
        }
        if (side == PartnershipSide.RESTAURANT) {
            assertFitsFee(restaurant, organization.getDeliveryRate(), organization.getTradingName(), side);
        }

        RestaurantPartnership partnership = new RestaurantPartnership();
        partnership.setRestaurant(restaurant);
        partnership.setOrganization(organization);
        partnership.setStatus(PartnershipStatus.PENDING);
        partnership.setRequestedBy(side);
        if (proposedRate != null && proposedRate.isConfigured()
                && !sameRate(proposedRate, organization.getDeliveryRate())) {
            partnership.setProposedRate(copy(proposedRate));
            partnership.setRateProposedBy(side);
            partnership.setRateProposedAt(now());
        }
        log.info("Pedido de parceria: loja {} e associação {} (pedido por {})", restaurant.getId(),
                organization.getId(), side);
        return partnershipRepository.save(partnership);
    }

    // ============= Decisão e encerramento =============

    public RestaurantPartnership accept(Long partnershipId, PartnershipSide side, Long partyId) {
        RestaurantPartnership partnership = load(partnershipId, side, partyId);
        assertAwaiting(partnership, side);
        return accept(partnership, side);
    }

    /** Aceitar o pedido aceita também a última proposta de tabela (a do pedido ou a contraproposta) */
    private RestaurantPartnership accept(RestaurantPartnership partnership, PartnershipSide side) {
        Organization organization = partnership.getOrganization();
        if (!organization.isOperational() || !organization.isDeliveryRateConfigured()) {
            throw new BadRequestException("A associação não está ativa ou ainda não definiu a tabela de valores");
        }
        if (partnership.hasRateProposal()) {
            applyProposal(partnership);
        } else {
            assertFitsFee(partnership.getRestaurant(), partnership.getEffectiveRate(), organization.getTradingName(), side);
        }
        partnership.setStatus(PartnershipStatus.ACTIVE);
        partnership.setDecidedAt(now());
        log.info("Parceria {} aceita por {}", partnership.getId(), side);
        return partnershipRepository.save(partnership);
    }

    public RestaurantPartnership decline(Long partnershipId, PartnershipSide side, Long partyId) {
        RestaurantPartnership partnership = load(partnershipId, side, partyId);
        assertAwaiting(partnership, side);
        partnership.setStatus(PartnershipStatus.DECLINED);
        partnership.setDecidedAt(now());
        return partnershipRepository.save(partnership);
    }

    /**
     * Encerra a parceria ativa ou cancela o próprio pedido pendente.
     *
     * A loja não encerra a única parceira enquanto recebe pedidos só de parceiras. Já a associação sempre pode
     * sair: se era a última parceira de uma loja PARTNERS_ONLY, a loja passa a receber de qualquer entregador
     * (e vê um aviso), para não ficar sem ninguém.
     */
    public RestaurantPartnership end(Long partnershipId, PartnershipSide side, Long partyId) {
        RestaurantPartnership partnership = load(partnershipId, side, partyId);
        PartnershipStatus status = partnership.getStatus();
        if (status == PartnershipStatus.PENDING) {
            // Quem fez a última jogada pode desistir; quem precisa responder recusa
            if (partnership.getAwaitingSide() == side) {
                throw new BadRequestException("Recuse o pedido em vez de encerrar");
            }
        } else if (status != PartnershipStatus.ACTIVE) {
            throw new BadRequestException("A parceria já foi encerrada");
        }

        Restaurant restaurant = partnership.getRestaurant();
        if (status == PartnershipStatus.ACTIVE && restaurant.getCourierPolicy() == CourierPolicy.PARTNERS_ONLY
                && partnershipRepository.findActiveByRestaurant(restaurant.getId()).size() == 1) {
            if (side == PartnershipSide.RESTAURANT) {
                throw new BadRequestException(
                        "Esta é a única parceira. Mude quem recebe os pedidos antes de encerrar a parceria.");
            }
            restaurant.setCourierPolicy(CourierPolicy.OPEN);
            restaurant.setPartnersEndedNoticeAt(now());
            restaurantRepository.save(restaurant);
            log.info("Loja {} ficou sem parceiras e passou a receber de qualquer entregador", restaurant.getId());
        }

        partnership.setStatus(PartnershipStatus.ENDED);
        partnership.setEndedAt(now());
        partnership.setEndedBy(side);
        partnership.clearRateProposal();
        log.info("Parceria {} encerrada por {}", partnership.getId(), side);
        return partnershipRepository.save(partnership);
    }

    /** O restaurante encerra pela associação (rota antiga, por organizationId) */
    public void endByRestaurant(Long restaurantId, Long organizationId) {
        RestaurantPartnership partnership = partnershipRepository.findOpen(restaurantId, organizationId)
                .orElseThrow(() -> new ResourceNotFoundException("Parceria não encontrada"));
        end(partnership.getId(), PartnershipSide.RESTAURANT, restaurantId);
    }

    // ============= Acordo: tabela especial =============

    /**
     * Propõe uma tabela especial ou a volta à tabela padrão da associação.
     *
     * Numa parceria ativa qualquer lado propõe; se já havia proposta do outro lado, esta é a contraproposta
     * e troca a anterior. Num pedido pendente só quem precisa responder manda contraproposta.
     */
    public RestaurantPartnership proposeRate(Long partnershipId, PartnershipSide side, Long partyId,
                                             RateProposalRequest request) {
        RestaurantPartnership partnership = load(partnershipId, side, partyId);
        PartnershipStatus status = partnership.getStatus();
        if (status == PartnershipStatus.PENDING) {
            if (partnership.getAwaitingSide() != side) {
                throw new BadRequestException("Aguarde a resposta à sua proposta");
            }
        } else if (status != PartnershipStatus.ACTIVE) {
            throw new BadRequestException("A tabela especial só pode ser combinada numa parceria ativa ou num pedido");
        }

        // O que vale se ninguém mudar nada: a proposta do outro lado (no pedido) ou a tabela combinada
        DeliveryRate current = status == PartnershipStatus.PENDING
                ? (partnership.hasRateProposal() && !partnership.isRateProposalToDefault() ? partnership.getProposedRate() : null)
                : (partnership.hasAgreedRate() ? partnership.getAgreedRate() : null);

        boolean toDefault = request.toDefault() || request.rate() == null;
        if (toDefault) {
            if (current == null) {
                throw new BadRequestException(status == PartnershipStatus.PENDING
                        ? "O pedido já usa a tabela padrão da associação"
                        : "Esta parceria já usa a tabela padrão da associação");
            }
            partnership.setProposedRate(null);
        } else {
            DeliveryRate rate = request.rate().toEntity();
            if (sameRate(rate, current != null ? current : partnership.getOrganization().getDeliveryRate())) {
                throw new BadRequestException(current != null
                        ? "Esta já é a tabela proposta"
                        : "Esta já é a tabela padrão da associação");
            }
            partnership.setProposedRate(rate);
        }
        partnership.setRateProposalToDefault(toDefault ? Boolean.TRUE : null);
        partnership.setRateProposedBy(side);
        partnership.setRateProposedAt(now());
        return partnershipRepository.save(partnership);
    }

    public RestaurantPartnership acceptRate(Long partnershipId, PartnershipSide side, Long partyId) {
        RestaurantPartnership partnership = loadActive(partnershipId, side, partyId);
        assertProposalFrom(partnership, side.other());
        applyProposal(partnership);
        log.info("Parceria {}: tabela combinada {}", partnership.getId(), partnership.getAgreedRate());
        return partnershipRepository.save(partnership);
    }

    /** A proposta aberta vira a tabela combinada (ou a parceria volta à tabela padrão) */
    private void applyProposal(RestaurantPartnership partnership) {
        DeliveryRate next = partnership.isRateProposalToDefault()
                ? partnership.getOrganization().getDeliveryRate()
                : partnership.getProposedRate();
        assertFitsFee(partnership.getRestaurant(), next, partnership.getOrganization().getTradingName(),
                partnership.getRateProposedBy().other());

        partnership.setAgreedRate(partnership.isRateProposalToDefault() ? null : copy(partnership.getProposedRate()));
        partnership.setAgreedAt(now());
        partnership.clearRateProposal();
    }

    /** O outro lado recusa a proposta */
    public RestaurantPartnership declineRate(Long partnershipId, PartnershipSide side, Long partyId) {
        RestaurantPartnership partnership = loadActive(partnershipId, side, partyId);
        assertProposalFrom(partnership, side.other());
        partnership.clearRateProposal();
        return partnershipRepository.save(partnership);
    }

    /** Quem propôs desiste da proposta */
    public RestaurantPartnership cancelRate(Long partnershipId, PartnershipSide side, Long partyId) {
        RestaurantPartnership partnership = loadActive(partnershipId, side, partyId);
        assertProposalFrom(partnership, side);
        partnership.clearRateProposal();
        return partnershipRepository.save(partnership);
    }

    // ============= Consultas =============

    @Transactional(readOnly = true)
    public List<RestaurantPartnership> listForAssociation(Long organizationId) {
        return partnershipRepository.findByOrganization(organizationId);
    }

    /** Tabelas especiais que valem na loja, por associação (para o despacho calcular o valor do entregador) */
    @Transactional(readOnly = true)
    public Map<Long, DeliveryRate> agreedRates(Long restaurantId) {
        Map<Long, DeliveryRate> rates = new HashMap<>();
        for (RestaurantPartnership partnership : partnershipRepository.findActiveByRestaurant(restaurantId)) {
            if (partnership.hasAgreedRate()) {
                rates.put(partnership.getOrganization().getId(), partnership.getAgreedRate());
            }
        }
        return rates;
    }

    /** Quantas decisões esperam por este lado: pedidos de parceria e propostas de tabela do outro lado */
    public static long pendingFor(List<RestaurantPartnership> partnerships, PartnershipSide side) {
        return partnerships.stream()
                .filter(p -> p.getAwaitingSide() == side)
                .count();
    }

    // ============= Auxiliares =============

    /**
     * O valor base da tabela que vai valer não pode passar da taxa de entrega da loja, a menos que ela assuma a
     * diferença (a mesma regra de antes do aceite, agora com a tabela efetiva)
     */
    private void assertFitsFee(Restaurant restaurant, DeliveryRate rate, String associationName, PartnershipSide side) {
        // Quem repassa a taxa ao cliente cobra pela tabela: não há diferença a cobrir
        if (restaurant.passesDeliveryFee() || restaurant.isCoversDeliveryDifference()
                || !PartnerDTO.exceedsFee(rate, restaurant.getDeliveryFee())) {
            return;
        }
        throw new ConflictException(side == PartnershipSide.RESTAURANT
                ? String.format("O valor base da tabela de %s (%s) é maior que a sua taxa de entrega. Para seguir, "
                + "marque que o restaurante assume a diferença.", associationName, money(rate.getBaseFee()))
                : String.format("A taxa de entrega da loja (%s) é menor que o valor base da tabela (%s) e a loja não "
                + "assume a diferença. Ela precisa ajustar a taxa ou assumir a diferença.",
                money(restaurant.getDeliveryFee()), money(rate.getBaseFee())));
    }

    private static void assertAwaiting(RestaurantPartnership partnership, PartnershipSide side) {
        if (partnership.getStatus() != PartnershipStatus.PENDING || partnership.getAwaitingSide() != side) {
            throw new BadRequestException("Não há pedido de parceria para responder");
        }
    }

    private static DeliveryRate copy(DeliveryRate rate) {
        return new DeliveryRate(rate.getBaseFee(), rate.getBaseDistanceKm(), rate.getExtraPerKm());
    }

    private static void assertProposalFrom(RestaurantPartnership partnership, PartnershipSide side) {
        if (!partnership.hasRateProposal() || partnership.getRateProposedBy() != side) {
            throw new BadRequestException("Não há proposta de tabela para responder");
        }
    }

    private static boolean sameRate(DeliveryRate a, DeliveryRate b) {
        return a.getBaseFee().compareTo(b.getBaseFee()) == 0
                && a.getBaseDistanceKm().compareTo(b.getBaseDistanceKm()) == 0
                && extra(a).compareTo(extra(b)) == 0;
    }

    private static BigDecimal extra(DeliveryRate rate) {
        return rate.getExtraPerKm() != null ? rate.getExtraPerKm() : BigDecimal.ZERO;
    }

    private RestaurantPartnership loadActive(Long partnershipId, PartnershipSide side, Long partyId) {
        RestaurantPartnership partnership = load(partnershipId, side, partyId);
        if (!partnership.isActive()) {
            throw new BadRequestException("A tabela especial só pode ser combinada numa parceria ativa");
        }
        return partnership;
    }

    /** A parceria, se pertencer a quem está pedindo (a loja ou a associação) */
    private RestaurantPartnership load(Long partnershipId, PartnershipSide side, Long partyId) {
        return partnershipRepository.findWithParties(partnershipId)
                .filter(p -> side == PartnershipSide.RESTAURANT
                        ? p.getRestaurant().getId().equals(partyId)
                        : p.getOrganization().getId().equals(partyId))
                .orElseThrow(() -> new ResourceNotFoundException("Parceria não encontrada"));
    }

    private Restaurant findRestaurant(Long restaurantId) {
        return restaurantRepository.findById(restaurantId)
                .orElseThrow(() -> new ResourceNotFoundException("Restaurante não encontrado"));
    }

    private Organization findOperationalAssociation(Long organizationId) {
        return organizationRepository.findById(organizationId)
                .filter(Organization::isOperational)
                .orElseThrow(() -> new ResourceNotFoundException("Associação não encontrada"));
    }

    private LocalDateTime now() {
        return LocalDateTime.now(clock);
    }

    private static String money(BigDecimal value) {
        return NumberFormat.getCurrencyInstance(Locale.forLanguageTag("pt-BR"))
                .format(value != null ? value : BigDecimal.ZERO);
    }
}
