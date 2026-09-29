package com.openbag.account.entity;

public enum UserType {
    CUSTOMER("Cliente"),
    RESTAURANT_OWNER("Proprietário de Restaurante"), 
    DELIVERY_PERSON("Entregador"),
    ADMIN("Administrador"),
    ORGANIZATION("Organização");

    private final String displayName;

    UserType(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
