package com.openbag.modules.cooperative.service;

import com.openbag.enums.MembershipStatus;
import com.openbag.exception.ResourceNotFoundException;
import com.openbag.modules.delivery.entity.DeliveryPerson;
import com.openbag.modules.delivery.repository.DeliveryPersonRepository;
import com.openbag.modules.organization.entity.AssociationMembership;
import com.openbag.modules.organization.repository.AssociationMembershipRepository;
import com.openbag.modules.user.entity.User;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.EnumSet;

/**
 * O vínculo do entregador logado com a associação (ativo ou suspenso): é por ele que o cooperado vê as faturas,
 * os adicionais, a caixinha, os convênios, as enquetes e os documentos
 */
@Component
public class MemberContext {

    @Autowired
    private DeliveryPersonRepository deliveryPersonRepository;

    @Autowired
    private AssociationMembershipRepository membershipRepository;

    public AssociationMembership current(User user) {
        DeliveryPerson courier = deliveryPersonRepository.findByUserId(user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Perfil de entregador não encontrado"));
        return membershipRepository.findByDeliveryPersonIdAndStatusIn(courier.getId(),
                        EnumSet.of(MembershipStatus.ACTIVE, MembershipStatus.SUSPENDED)).stream()
                .findFirst()
                .orElseThrow(() -> new ResourceNotFoundException("Você não faz parte de uma associação"));
    }
}
