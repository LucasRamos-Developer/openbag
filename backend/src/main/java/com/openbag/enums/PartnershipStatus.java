package com.openbag.enums;

/**
 * Situação da parceria entre restaurante e associação. Só ACTIVE vale no despacho (PARTNERS_ONLY e tabela especial).
 */
public enum PartnershipStatus {
    PENDING,
    ACTIVE,
    DECLINED,
    ENDED
}
