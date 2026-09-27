import 'package:flutter/material.dart';
import 'app_theme_colors.dart';

/// Os 8 temas prontos da página do restaurante. [key] é o mesmo nome do enum
/// RestaurantThemePreset do backend. Fresh Green é o padrão do sistema.
enum AppThemePreset {
  freshGreen(
    'FRESH_GREEN',
    'Fresh Green',
    'Natural, fresco e moderno',
    AppThemeColors(
      brightness: Brightness.light,
      background: Color(0xFFF7FAF8),
      text: Color(0xFF17221D),
      primary: Color(0xFF00A878),
      secondary: Color(0xFFDDF4EC),
      accent: Color(0xFF8BCF3F),
    ),
  ),
  sunsetOrange(
    'SUNSET_ORANGE',
    'Sunset Orange',
    'Quente, apetitoso e divertido',
    AppThemeColors(
      brightness: Brightness.light,
      background: Color(0xFFFFF9F3),
      text: Color(0xFF291B15),
      primary: Color(0xFFF4511E),
      secondary: Color(0xFFFFE2D4),
      accent: Color(0xFFFFC107),
    ),
  ),
  berryPink(
    'BERRY_PINK',
    'Berry Pink',
    'Jovem, moderno, doces e cafés',
    AppThemeColors(
      brightness: Brightness.light,
      background: Color(0xFFFFF8FA),
      text: Color(0xFF29171F),
      primary: Color(0xFFD83A73),
      secondary: Color(0xFFF8DCE7),
      accent: Color(0xFFFF6B6B),
    ),
  ),
  oceanBlue(
    'OCEAN_BLUE',
    'Ocean Blue',
    'Limpo, bebidas e frutos do mar',
    AppThemeColors(
      brightness: Brightness.light,
      background: Color(0xFFF5FAFC),
      text: Color(0xFF17252B),
      primary: Color(0xFF008CC2),
      secondary: Color(0xFFDDF2FA),
      accent: Color(0xFF00B8A9),
    ),
  ),
  grapePurple(
    'GRAPE_PURPLE',
    'Grape Purple',
    'Criativo, marcante e premium',
    AppThemeColors(
      brightness: Brightness.light,
      background: Color(0xFFFAF8FC),
      text: Color(0xFF241B2B),
      primary: Color(0xFF7B3FC6),
      secondary: Color(0xFFEBDDFA),
      accent: Color(0xFFE94F9F),
    ),
  ),
  midnightGreen(
    'MIDNIGHT_GREEN',
    'Midnight Green',
    'Sofisticado e natural',
    AppThemeColors(
      brightness: Brightness.dark,
      background: Color(0xFF0F1916),
      text: Color(0xFFE8F2EE),
      primary: Color(0xFF19B887),
      secondary: Color(0xFF19352C),
      accent: Color(0xFF8BCF3F),
    ),
  ),
  midnightBlue(
    'MIDNIGHT_BLUE',
    'Midnight Blue',
    'Elegante e tecnológico',
    AppThemeColors(
      brightness: Brightness.dark,
      background: Color(0xFF101820),
      text: Color(0xFFE8F0F5),
      primary: Color(0xFF3BA7D6),
      secondary: Color(0xFF1B3441),
      accent: Color(0xFF42D6D0),
    ),
  ),
  graphite(
    'GRAPHITE',
    'Graphite',
    'Premium, bar e steakhouse',
    AppThemeColors(
      brightness: Brightness.dark,
      background: Color(0xFF171719),
      text: Color(0xFFF2F2F0),
      primary: Color(0xFFE05A47),
      secondary: Color(0xFF302B2A),
      accent: Color(0xFFD9A441),
    ),
  );

  final String key;
  final String label;
  final String mood;
  final AppThemeColors colors;

  const AppThemePreset(this.key, this.label, this.mood, this.colors);

  static const AppThemePreset fallback = AppThemePreset.freshGreen;

  bool get isDark => colors.isDark;

  /// Aceita a chave do backend (FRESH_GREEN) ou o formato de URL (fresh-green)
  static AppThemePreset fromKey(String? key) {
    if (key == null) return fallback;
    final normalized = key.trim().toUpperCase().replaceAll('-', '_');
    for (final preset in values) {
      if (preset.key == normalized) return preset;
    }
    return fallback;
  }

  /// Formato usado em URL: fresh-green
  String get slug => key.toLowerCase().replaceAll('_', '-');
}
