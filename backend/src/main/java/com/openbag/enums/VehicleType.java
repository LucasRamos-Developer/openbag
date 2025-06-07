package com.openbag.enums;

public enum VehicleType {
    BICYCLE("Bicicleta"),
    MOTORCYCLE("Motocicleta"),
    CAR("Carro"),
    FOOT("A pé");

    private final String displayName;

    VehicleType(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
