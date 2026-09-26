/// Tabela de valores de entrega da associação: valor base até [baseDistanceKm] e [extraPerKm] por km acima disso
class DeliveryRate {
  final double? baseFee;
  final double? baseDistanceKm;
  final double extraPerKm;
  final bool configured;

  const DeliveryRate({this.baseFee, this.baseDistanceKm, this.extraPerKm = 0, this.configured = false});

  factory DeliveryRate.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DeliveryRate();
    return DeliveryRate(
      baseFee: (json['baseFee'] as num?)?.toDouble(),
      baseDistanceKm: (json['baseDistanceKm'] as num?)?.toDouble(),
      extraPerKm: (json['extraPerKm'] as num?)?.toDouble() ?? 0,
      configured: json['configured'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {'baseFee': baseFee, 'baseDistanceKm': baseDistanceKm, 'extraPerKm': extraPerKm};

  bool get hasExtra => extraPerKm > 0;

  /// Mesmo cálculo do backend (DeliveryRateCalculator)
  double feeFor(double km) {
    final base = baseFee ?? 0;
    final extraKm = km - (baseDistanceKm ?? 0);
    final fee = extraKm > 0 && hasExtra ? base + extraKm * extraPerKm : base;
    return (fee * 100).roundToDouble() / 100;
  }
}
