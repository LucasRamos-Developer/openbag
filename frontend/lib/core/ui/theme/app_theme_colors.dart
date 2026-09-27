import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_theme_presets.dart';

/// Tokens de cor do tema (padrão visual de layout/restaurante-padrão.png)
///
/// São 5 cores base + o brilho; o resto é derivado com contraste garantido:
///
/// | Token        | Uso                                                         |
/// |--------------|-------------------------------------------------------------|
/// | background   | fundo geral da página                                       |
/// | text         | títulos, nomes de produtos e textos principais              |
/// | primary      | cor da marca: degradês, ícones e destaques                   |
/// | secondary    | chips, selos e áreas destacadas (tom suave)                 |
/// | accent       | detalhes e pequenos destaques (sublinhado, ícones)          |
/// | action       | preenchimento de botões e chips ativos (primary ajustado)   |
/// | primaryText  | preço, links e textos na cor da marca (primary ajustado)    |
///
/// Em telas, leia sempre por `context.appColors` — nunca `Colors.x`/`AppColors.x` fixos.
/// Status (aberto/fechado) e avaliação usam as cores semânticas fixas ([success], [danger], [rating]).
@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Brightness brightness;
  final Color background;
  final Color text;
  final Color primary;
  final Color secondary;
  final Color accent;

  const AppThemeColors({
    required this.brightness,
    required this.background,
    required this.text,
    required this.primary,
    required this.secondary,
    required this.accent,
  });

  /// Tema com a cor da marca no lugar do primary de [base]; o secondary é derivado da marca
  factory AppThemeColors.fromBrand(Color brand, {AppThemePreset base = AppThemePreset.freshGreen}) {
    final colors = base.colors;
    return AppThemeColors(
      brightness: colors.brightness,
      background: colors.background,
      text: colors.text,
      primary: brand,
      secondary: Color.lerp(brand, colors.background, colors.isDark ? 0.78 : 0.86)!,
      accent: colors.accent,
    );
  }

  /// Preset + cor da marca opcional (#RRGGBB)
  static AppThemeColors resolve(AppThemePreset preset, {String? brandColor}) {
    final brand = parseHex(brandColor);
    return brand == null ? preset.colors : AppThemeColors.fromBrand(brand, base: preset);
  }

  bool get isDark => brightness == Brightness.dark;

  // ============= Derivados =============

  /// Cards e superfícies elevadas
  Color get surface => isDark ? Color.alphaBlend(text.withValues(alpha: 0.06), background) : Colors.white;

  /// Campos, placeholders e fundos alternativos
  Color get surfaceAlt => Color.alphaBlend(text.withValues(alpha: isDark ? 0.10 : 0.04), surface);

  /// Bordas sutis de cards e campos
  Color get border => Color.alphaBlend(text.withValues(alpha: isDark ? 0.14 : 0.09), surface);

  /// Textos secundários (descrições, metadados)
  Color get textMuted => ensureContrast(Color.alphaBlend(text.withValues(alpha: 0.64), surface), surface);

  /// Preenchimento de botões e chips ativos. Cores médias escurecem até o branco ter contraste AA;
  /// cores claras demais (ex: lima, amarelo) ficam como estão e recebem texto escuro.
  Color get action => contrastRatio(Colors.white, primary) >= 3 ? _darkenUntil(primary, Colors.white) : primary;

  /// Texto e ícones sobre [action]
  Color get onAction {
    if (contrastRatio(Colors.white, action) >= minContrast) return Colors.white;
    final ink = isDark ? background : text;
    return contrastRatio(ink, action) >= minContrast ? ink : Colors.black;
  }

  /// Cor da marca legível sobre [surface] (preço, links)
  Color get primaryText => ensureContrast(primary, surface);

  /// Texto sobre [secondary] (selos e chips suaves)
  Color get onSecondary => ensureContrast(primary, secondary);

  /// Degradê do banner: escurece da esquerda (onde fica o texto) para a direita
  List<Color> get heroGradient {
    final base = isDark ? Color.lerp(primary, background, 0.55)! : AppColors.darken(primary, 0.18);
    return [base, base.withValues(alpha: 0.85), base.withValues(alpha: 0.0)];
  }

  /// Sombra suave dos cards (no escuro, a borda faz esse papel)
  List<BoxShadow> get cardShadow => isDark
      ? const []
      : [BoxShadow(color: text.withValues(alpha: 0.06), blurRadius: 24, offset: const Offset(0, 8))];

  // ============= Semânticas fixas =============

  Color get success => isDark ? const Color(0xFF3DD68C) : const Color(0xFF0E8A4F);
  Color get danger => isDark ? const Color(0xFFFF7A6B) : const Color(0xFFD92D20);
  Color get rating => const Color(0xFFFFB400);

  // ============= Contraste =============

  /// Mínimo WCAG AA para texto normal
  static const double minContrast = 4.5;

  static double contrastRatio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  /// Escurece (fundo claro) ou clareia (fundo escuro) [fg] até ter contraste AA sobre [bg]
  static Color ensureContrast(Color fg, Color bg, [double min = minContrast]) {
    if (contrastRatio(fg, bg) >= min) return fg;
    final darken = bg.computeLuminance() > 0.18;
    var hsl = HSLColor.fromColor(fg);
    for (var i = 0; i < 50; i++) {
      final lightness = (hsl.lightness + (darken ? -0.02 : 0.02)).clamp(0.0, 1.0);
      hsl = hsl.withLightness(lightness);
      final color = hsl.toColor();
      if (contrastRatio(color, bg) >= min) return color;
      if (lightness == 0.0 || lightness == 1.0) break;
    }
    return darken ? Colors.black : Colors.white;
  }

  static Color _darkenUntil(Color bg, Color fg) {
    var hsl = HSLColor.fromColor(bg);
    while (hsl.lightness > 0 && contrastRatio(fg, hsl.toColor()) < minContrast) {
      hsl = hsl.withLightness((hsl.lightness - 0.02).clamp(0.0, 1.0));
    }
    return hsl.toColor();
  }

  static Color? parseHex(String? hex) {
    if (hex == null || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex)) return null;
    return Color(int.parse('FF${hex.substring(1)}', radix: 16));
  }

  static String toHex(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  // ============= ThemeExtension =============

  @override
  AppThemeColors copyWith({
    Brightness? brightness,
    Color? background,
    Color? text,
    Color? primary,
    Color? secondary,
    Color? accent,
  }) =>
      AppThemeColors(
        brightness: brightness ?? this.brightness,
        background: background ?? this.background,
        text: text ?? this.text,
        primary: primary ?? this.primary,
        secondary: secondary ?? this.secondary,
        accent: accent ?? this.accent,
      );

  @override
  AppThemeColors lerp(covariant AppThemeColors? other, double t) {
    if (other == null) return this;
    return AppThemeColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: Color.lerp(background, other.background, t)!,
      text: Color.lerp(text, other.text, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}

/// Raios padrão do design system
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;
}

extension AppThemeColorsContext on BuildContext {
  /// Tokens do tema atual (Fresh Green quando o tema não traz a extensão)
  AppThemeColors get appColors => Theme.of(this).extension<AppThemeColors>() ?? AppThemePreset.freshGreen.colors;
}
