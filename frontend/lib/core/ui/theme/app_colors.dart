import 'package:flutter/material.dart';

/// Sistema de cores da aplicação baseado no MUI Minimal
/// 
/// Define todas as cores usadas no app seguindo padrões de design system.
/// Pode ser facilmente customizado ou exportado para outros projetos.
class AppColors {
  AppColors._(); // Construtor privado para classe utilitária

  // ========== PRIMARY (Verde) ==========
  
  static const Color primaryLighter = Color(0xFFC8E6C9);
  static const Color primaryLight = Color(0xFF81C784);
  static const Color primary = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF388E3C);
  static const Color primaryDarker = Color(0xFF1B5E20);
  
  // ========== SECONDARY (Roxo) ==========
  
  static const Color secondaryLighter = Color(0xFFE1BEE7);
  static const Color secondaryLight = Color(0xFFBA68C8);
  static const Color secondary = Color(0xFF9C27B0);
  static const Color secondaryDark = Color(0xFF7B1FA2);
  static const Color secondaryDarker = Color(0xFF4A148C);

  // ========== INFO (Ciano) ==========
  
  static const Color infoLighter = Color(0xFFB2EBF2);
  static const Color infoLight = Color(0xFF4DD0E1);
  static const Color info = Color(0xFF00BCD4);
  static const Color infoDark = Color(0xFF0097A7);
  static const Color infoDarker = Color(0xFF006064);
  
  // ========== SUCCESS (Verde) ==========
  
  static const Color successLighter = Color(0xFFC8E6C9);
  static const Color successLight = Color(0xFF81C784);
  static const Color success = Color(0xFF4CAF50);
  static const Color successDark = Color(0xFF388E3C);
  static const Color successDarker = Color(0xFF1B5E20);
  
  // ========== WARNING (Laranja/Amarelo) ==========
  
  static const Color warningLighter = Color(0xFFFFECB3);
  static const Color warningLight = Color(0xFFFFD54F);
  static const Color warning = Color(0xFFFFC107);
  static const Color warningDark = Color(0xFFFFA000);
  static const Color warningDarker = Color(0xFFFF6F00);
  
  // ========== ERROR (Vermelho) ==========
  
  static const Color errorLighter = Color(0xFFFFCCBC);
  static const Color errorLight = Color(0xFFFF8A65);
  static const Color error = Color(0xFFFF5722);
  static const Color errorDark = Color(0xFFE64A19);
  static const Color errorDarker = Color(0xFFBF360C);

  // ========== GREY ==========
  
  static const Color grey100 = Color(0xFFF9FAFB);
  static const Color grey200 = Color(0xFFF4F6F8);
  static const Color grey300 = Color(0xFFDFE3E8);
  static const Color grey400 = Color(0xFFC4CDD5);
  static const Color grey500 = Color(0xFF919EAB);
  static const Color grey600 = Color(0xFF637381);
  static const Color grey700 = Color(0xFF454F5B);
  static const Color grey800 = Color(0xFF212B36);
  static const Color grey900 = Color(0xFF161C24);

  // ========== CORES DE SUPERFÍCIE ==========
  
  /// Branco - Cards e superfícies elevadas
  static const Color backgroundSurface = Color(0xFFFFFFFF);
  
  /// Cinza muito claro - Fundo principal
  static const Color backgroundMain = grey100;
  
  /// Cinza claro - Superfícies alternativas
  static const Color backgroundAlt = grey200;

  // ========== CORES DE TEXTO ==========
  
  /// Azul escuro - Títulos e textos principais
  static const Color textTitle = grey800;
  
  /// Cinza médio - Textos do corpo
  static const Color textBody = grey600;
  
  /// Cinza claro - Textos secundários
  static const Color textSecondary = grey500;
  
  /// Cinza muito claro - Textos desabilitados
  static const Color textDisabled = grey400;

  // ========== CORES DE BORDA ==========
  
  /// Cinza muito claro - Bordas sutis
  static const Color borderLine = grey300;
  
  /// Cinza claro - Bordas em foco
  static const Color borderFocused = grey400;
  
  /// Cinza médio - Bordas destacadas
  static const Color borderStrong = grey500;

  // ========== GRADIENTES ==========
  
  /// Gradiente verde (primary)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Gradiente roxo (secondary)
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ========== MÉTODOS UTILITÁRIOS ==========
  
  /// Retorna uma cor com opacidade ajustada
  static Color withAlpha(Color color, double opacity) {
    return color.withOpacity(opacity.clamp(0.0, 1.0));
  }
  
  /// Retorna cor de contraste (preto ou branco) baseado na luminosidade
  static Color getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
  
  /// Clareia uma cor
  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
  
  /// Escurece uma cor
  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}
