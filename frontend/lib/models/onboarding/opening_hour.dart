class OpeningHour {
  String? label;
  int weekday; // 1=segunda, 7=domingo
  String openTime; // HH:mm:ss format
  String closeTime; // HH:mm:ss format
  String? observation;

  OpeningHour({
    this.label,
    required this.weekday,
    required this.openTime,
    required this.closeTime,
    this.observation,
  });

  Map<String, dynamic> toJson() {
    return {
      if (label != null && label!.isNotEmpty) 'label': label,
      'weekday': weekday,
      'openTime': openTime,
      'closeTime': closeTime,
      if (observation != null && observation!.isNotEmpty) 'observation': observation,
    };
  }

  factory OpeningHour.fromJson(Map<String, dynamic> json) {
    return OpeningHour(
      label: json['label'],
      weekday: json['weekday'],
      openTime: json['openTime'],
      closeTime: json['closeTime'],
      observation: json['observation'],
    );
  }

  OpeningHour copyWith({
    String? label,
    int? weekday,
    String? openTime,
    String? closeTime,
    String? observation,
  }) {
    return OpeningHour(
      label: label ?? this.label,
      weekday: weekday ?? this.weekday,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      observation: observation ?? this.observation,
    );
  }

  // Helper method para validar se o horário está correto
  bool isValid() {
    final open = _timeToMinutes(openTime);
    final close = _timeToMinutes(closeTime);
    return close > open;
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return 0;
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
