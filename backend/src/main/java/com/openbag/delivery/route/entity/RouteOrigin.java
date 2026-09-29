package com.openbag.delivery.route.entity;

/**
 * Quem montou a rota: o planejador automático (refaz enquanto espera) ou a loja (fica como está)
 */
public enum RouteOrigin {
    AUTO,
    MANUAL
}
