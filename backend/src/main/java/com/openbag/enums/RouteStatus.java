package com.openbag.enums;

/**
 * Situação de uma rota de entrega (grupo de pedidos da mesma loja para um entregador só)
 */
public enum RouteStatus {
    /** Montada, esperando a hora de chamar o entregador */
    PLANNED,
    /** Procurando entregador */
    DISPATCHING,
    /** Com entregador, antes da primeira retirada */
    ASSIGNED,
    /** Entregador saiu com os pedidos */
    IN_PROGRESS,
    DONE,
    CANCELLED
}
