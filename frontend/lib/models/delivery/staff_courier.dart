/// Entregador da equipe própria da loja (sem o app)
class StaffCourier {
  final int id;
  final String name;
  final String? phone;

  /// Valor pago por entrega; nulo = a taxa de entrega cobrada do cliente
  final double? feePerDelivery;

  StaffCourier({required this.id, required this.name, this.phone, this.feePerDelivery});

  factory StaffCourier.fromJson(Map<String, dynamic> json) => StaffCourier(
        id: json['id'],
        name: json['name'] ?? '',
        phone: json['phone'],
        feePerDelivery: (json['feePerDelivery'] as num?)?.toDouble(),
      );
}
