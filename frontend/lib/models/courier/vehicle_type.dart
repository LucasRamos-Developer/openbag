import 'package:flutter/material.dart';

enum VehicleType {
  MOTORCYCLE('Moto', Icons.two_wheeler),
  BICYCLE('Bicicleta', Icons.pedal_bike),
  CAR('Carro', Icons.directions_car),
  FOOT('A pé', Icons.directions_walk);

  final String label;
  final IconData icon;
  const VehicleType(this.label, this.icon);

  bool get requiresPlate => this == MOTORCYCLE || this == CAR;

  static VehicleType fromName(String? name) =>
      values.firstWhere((e) => e.name == name, orElse: () => MOTORCYCLE);
}
