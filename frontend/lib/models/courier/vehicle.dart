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

  Vehicle({
    required this.id,
    required this.type,
    this.plate,
    this.model,
    this.color,
    this.photoUrl,
    this.active = false,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'],
        type: VehicleType.fromName(json['type']),
        plate: json['plate'],
        model: json['model'],
        color: json['color'],
        photoUrl: json['photoUrl'],
        active: json['active'] ?? false,
      );

  /// "Honda CG 160 · Vermelha"
  String get description => [model, color].whereType<String>().where((s) => s.isNotEmpty).join(' · ');

  /// Nome curto para listas: modelo ou tipo
  String get title => model?.isNotEmpty == true ? model! : type.label;
}
