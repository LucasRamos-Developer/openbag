import 'package:flutter/material.dart';

/// O que atrapalhou a entrega, relatado pelo entregador. A loja vê no pedido e a cooperativa vê a contagem;
/// nunca vira nota nem penalidade do entregador.
enum IncidentType {
  ORDER_NOT_READY('Pedido não estava pronto', Icons.hourglass_bottom),
  WRONG_ADDRESS('Endereço incorreto', Icons.wrong_location_outlined),
  CUSTOMER_NOT_FOUND('Cliente não localizado', Icons.person_search_outlined),
  ORDER_MISMATCH('Pedido não confere', Icons.rule),
  RESTAURANT_CLOSED('Restaurante fechado', Icons.storefront_outlined),
  VEHICLE_PROBLEM('Problema no veículo', Icons.build_outlined),
  ACCESS_PROBLEM('Sem acesso ao local', Icons.lock_outline),
  OTHER('Outro problema', Icons.more_horiz);

  final String label;
  final IconData icon;
  const IncidentType(this.label, this.icon);

  static IncidentType fromName(String? name) => values.firstWhere((e) => e.name == name, orElse: () => OTHER);
}

class OrderIncident {
  final int id;
  final IncidentType type;
  final String? note;
  final String? reportedBy;
  final DateTime? at;

  OrderIncident({required this.id, required this.type, this.note, this.reportedBy, this.at});

  factory OrderIncident.fromJson(Map<String, dynamic> json) => OrderIncident(
        id: json['id'],
        type: IncidentType.fromName(json['type']),
        note: json['note'],
        reportedBy: json['reportedBy'],
        at: json['at'] is String ? DateTime.tryParse(json['at']) : null,
      );

  /// "Cliente não localizado" ou, em "outro", a observação
  String get title => type == IncidentType.OTHER && note != null ? note! : type.label;
}
