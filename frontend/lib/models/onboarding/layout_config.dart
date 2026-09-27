/// Aparência escolhida no cadastro: tema pronto + cor da marca opcional (#RRGGBB)
class LayoutConfig {
  String themePreset;
  String? brandColor;

  LayoutConfig({required this.themePreset, this.brandColor});

  Map<String, dynamic> toJson() => {'themePreset': themePreset, 'brandColor': brandColor};

  factory LayoutConfig.fromJson(Map<String, dynamic> json) =>
      LayoutConfig(themePreset: json['themePreset'] ?? 'FRESH_GREEN', brandColor: json['brandColor']);

  LayoutConfig copyWith({String? themePreset, String? brandColor}) =>
      LayoutConfig(themePreset: themePreset ?? this.themePreset, brandColor: brandColor ?? this.brandColor);

  static LayoutConfig get defaultConfig => LayoutConfig(themePreset: 'FRESH_GREEN');
}
