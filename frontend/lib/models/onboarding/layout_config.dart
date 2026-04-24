class LayoutConfig {
  String primaryColor; // #RRGGBB format
  String secondaryColor; // #RRGGBB format

  LayoutConfig({
    required this.primaryColor,
    required this.secondaryColor,
  });

  Map<String, dynamic> toJson() {
    return {
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
    };
  }

  factory LayoutConfig.fromJson(Map<String, dynamic> json) {
    return LayoutConfig(
      primaryColor: json['primaryColor'],
      secondaryColor: json['secondaryColor'],
    );
  }

  LayoutConfig copyWith({
    String? primaryColor,
    String? secondaryColor,
  }) {
    return LayoutConfig(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
    );
  }

  // Valores padrão
  static LayoutConfig get defaultConfig => LayoutConfig(
    primaryColor: '#FF5722',
    secondaryColor: '#212121',
  );
}
