package com.openbag.enums;

/**
 * Filtro da lista de associados pela mensalidade
 */
public enum MemberBillingFilter {
    ALL,
    /** Com fatura em aberto */
    OPEN,
    /** Sem fatura em aberto */
    UP_TO_DATE
}
