import 'vehicle_type.dart';

/// Veículo do entregador
class Vehicle {
  final int id;
  final VehicleType type;
  final String? plate;
  final String? model;
  final String? color;
  final String? photoUrl;
  final bool active;

  /// Custos informados para o resultado estimado da aba Ganhos (nulos quando não informados)
  final double? fuelConsumptionKmPerLiter;
  final double? fuelPricePerLiter;
  final double? maintenancePerKm;
  final double? depreciationPerKm;

  Vehicle({
    required this.id,
    required this.type,
    this.plate,
    this.model,
    this.color,
    this.photoUrl,
    this.active = false,
    this.fuelConsumptionKmPerLiter,
    this.fuelPricePerLiter,
    this.maintenancePerKm,
    this.depreciationPerKm,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'],
        type: VehicleType.fromName(json['type']),
        plate: json['plate'],
        model: json['model'],
        color: json['color'],
        photoUrl: json['photoUrl'],
        active: json['active'] ?? false,
        fuelConsumptionKmPerLiter: (json['fuelConsumptionKmPerLiter'] as num?)?.toDouble(),
        fuelPricePerLiter: (json['fuelPricePerLiter'] as num?)?.toDouble(),
        maintenancePerKm: (json['maintenancePerKm'] as num?)?.toDouble(),
        depreciationPerKm: (json['depreciationPerKm'] as num?)?.toDouble(),
      );

  /// Moto e carro gastam combustível
  bool get usesFuel => type.requiresPlate;

  bool get hasCosts =>
      fuelConsumptionKmPerLiter != null || fuelPricePerLiter != null || maintenancePerKm != null || depreciationPerKm != null;

  /// "Honda CG 160 · Vermelha"
  String get description => [model, color].whereType<String>().where((s) => s.isNotEmpty).join(' · ');

  /// Nome curto para listas: modelo ou tipo
  String get title => model?.isNotEmpty == true ? model! : type.label;
}
