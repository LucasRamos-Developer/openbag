/// Restaurante resumido (seletor do painel do dono)
class RestaurantSummary {
  final int id;
  final String name;
  final String slug;
  final String? logoUrl;
  final bool active;
  final bool openNow;

  RestaurantSummary({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    required this.active,
    required this.openNow,
  });

  factory RestaurantSummary.fromJson(Map<String, dynamic> json) => RestaurantSummary(
        id: json['id'],
        name: json['name'] ?? '',
        slug: json['slug'] ?? '',
        logoUrl: json['logoUrl'],
        active: json['active'] ?? false,
        openNow: json['openNow'] ?? false,
      );
}

enum AcceptanceMode {
  MANUAL('Aceite manual', 'Cada pedido chega com alerta e você aceita ou recusa dentro do prazo.'),
  AUTO('Aceite automático', 'Todo pedido entra direto como confirmado e vai para a cozinha.');

  final String label;
  final String description;
  const AcceptanceMode(this.label, this.description);

  static AcceptanceMode fromName(String? name) => values.firstWhere((e) => e.name == name, orElse: () => MANUAL);
}

/// Horário de funcionamento (weekday 1 = segunda ... 7 = domingo; "HH:mm")
class OpeningHour {
  final int weekday;
  final String openTime;
  final String closeTime;

  const OpeningHour({required this.weekday, required this.openTime, required this.closeTime});

  static const weekdayNames = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];

  String get weekdayName => weekdayNames[weekday - 1];

  /// Fecha no dia seguinte (ex: 18:00–02:00)
  bool get overnight => closeTime.compareTo(openTime) <= 0;

  factory OpeningHour.fromJson(Map<String, dynamic> json) => OpeningHour(
        weekday: json['weekday'],
        openTime: _hhmm(json['openTime']),
        closeTime: _hhmm(json['closeTime']),
      );

  Map<String, dynamic> toJson() => {'weekday': weekday, 'openTime': openTime, 'closeTime': closeTime};

  OpeningHour copyWith({int? weekday, String? openTime, String? closeTime}) => OpeningHour(
        weekday: weekday ?? this.weekday,
        openTime: openTime ?? this.openTime,
        closeTime: closeTime ?? this.closeTime,
      );

  // O backend manda "HH:mm:ss" ou "HH:mm"
  static String _hhmm(dynamic value) => (value as String).substring(0, 5);
}

/// Situação e configurações de operação da loja
class Store {
  final int id;
  final String name;
  final String slug;
  final String? logoUrl;
  final bool active;
  final bool open;
  final bool openNow;
  final DateTime? pausedUntil;
  final AcceptanceMode acceptanceMode;
  final int acceptanceTimeoutMinutes;
  final int defaultPreparationMinutes;
  final double deliveryFee;
  final double minimumOrder;
  final int deliveryTimeMin;
  final int deliveryTimeMax;
  final String? priceRange;
  final bool autoPrintTicket;
  final List<OpeningHour> openingHours;

  Store({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    required this.active,
    required this.open,
    required this.openNow,
    this.pausedUntil,
    required this.acceptanceMode,
    required this.acceptanceTimeoutMinutes,
    required this.defaultPreparationMinutes,
    required this.deliveryFee,
    required this.minimumOrder,
    required this.deliveryTimeMin,
    required this.deliveryTimeMax,
    this.priceRange,
    required this.autoPrintTicket,
    required this.openingHours,
  });

  bool get paused => pausedUntil != null;

  factory Store.fromJson(Map<String, dynamic> json) => Store(
        id: json['id'],
        name: json['name'] ?? '',
        slug: json['slug'] ?? '',
        logoUrl: json['logoUrl'],
        active: json['active'] ?? false,
        open: json['open'] ?? false,
        openNow: json['openNow'] ?? false,
        pausedUntil: json['pausedUntil'] != null ? DateTime.tryParse(json['pausedUntil']) : null,
        acceptanceMode: AcceptanceMode.fromName(json['acceptanceMode']),
        acceptanceTimeoutMinutes: json['acceptanceTimeoutMinutes'] ?? 8,
        defaultPreparationMinutes: json['defaultPreparationMinutes'] ?? 20,
        deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0,
        minimumOrder: (json['minimumOrder'] as num?)?.toDouble() ?? 0,
        deliveryTimeMin: json['deliveryTimeMin'] ?? 30,
        deliveryTimeMax: json['deliveryTimeMax'] ?? 45,
        priceRange: json['priceRange'],
        autoPrintTicket: json['autoPrintTicket'] ?? false,
        openingHours: (json['openingHours'] as List? ?? []).map((e) => OpeningHour.fromJson(e)).toList(),
      );
}
