package com.openbag.association.partnership.entity;

/**
 * Lado da parceria que fez um pedido ou uma proposta; a outra parte é quem aceita
 */
public enum PartnershipSide {
    RESTAURANT,
    ASSOCIATION;

    public PartnershipSide other() {
        return this == RESTAURANT ? ASSOCIATION : RESTAURANT;
    }
}
