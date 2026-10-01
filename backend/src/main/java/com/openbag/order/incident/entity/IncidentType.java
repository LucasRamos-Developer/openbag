package com.openbag.order.incident.entity;

/**
 * O que atrapalhou a entrega, relatado pelo entregador. Serve para a loja agir e para a cooperativa negociar;
 * nunca vira nota nem penalidade do entregador.
 */
public enum IncidentType {
    ORDER_NOT_READY,
    WRONG_ADDRESS,
    CUSTOMER_NOT_FOUND,
    ORDER_MISMATCH,
    RESTAURANT_CLOSED,
    VEHICLE_PROBLEM,
    ACCESS_PROBLEM,
    /** Precisa de observação */
    OTHER
}
