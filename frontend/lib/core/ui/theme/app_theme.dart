import 'package:flutter/material.dart';
import 'app_theme_colors.dart';
import 'app_theme_presets.dart';

/// Tema da aplicação (Material 3) gerado a partir dos tokens [AppThemeColors]
///
/// O padrão do app é o Fresh Green; a página do restaurante aplica o tema escolhido
/// pelo dono com `Theme(data: AppTheme.fromColors(...))`.
class AppTheme {
  AppTheme._(); // Construtor privado

  static const String fontFamily = 'PlusJakartaSans';

  static ThemeData get light => fromColors(AppThemePreset.freshGreen.colors);

  static ThemeData get dark => fromColors(AppThemePreset.midnightGreen.colors);

  static ThemeData fromColors(AppThemeColors c) {
    final fieldRadius = BorderRadius.circular(AppRadius.md);
    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md));
    const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 12);
    const buttonText = TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.2);

    return ThemeData(
      useMaterial3: true,
      brightness: c.brightness,
      fontFamily: fontFamily,
      extensions: [c],

      colorScheme: ColorScheme(
        brightness: c.brightness,
        primary: c.action,
        onPrimary: c.onAction,
        primaryContainer: c.secondary,
        onPrimaryContainer: c.onSecondary,
        secondary: c.primaryText,
        onSecondary: c.surface,
        secondaryContainer: c.secondary,
        onSecondaryContainer: c.onSecondary,
        tertiary: c.accent,
        onTertiary: c.text,
        error: c.danger,
        onError: Colors.white,
        errorContainer: c.danger.withValues(alpha: 0.14),
        onErrorContainer: c.danger,
        surface: c.surface,
        onSurface: c.text,
        onSurfaceVariant: c.textMuted,
        surfaceContainerLowest: c.surface,
        surfaceContainerLow: c.surface,
        surfaceContainer: c.surface,
        surfaceContainerHigh: c.surfaceAlt,
        surfaceContainerHighest: c.surfaceAlt,
        outline: c.border,
        outlineVariant: c.border,
        shadow: Colors.black,
      ),

      textTheme: _buildTextTheme(c.text, c.textMuted),
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,

      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w700, color: c.text),
      ),

      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: c.border),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: fieldRadius, borderSide: BorderSide(color: c.border)),
        enabledBorder: OutlineInputBorder(borderRadius: fieldRadius, borderSide: BorderSide(color: c.border)),
        focusedBorder: OutlineInputBorder(borderRadius: fieldRadius, borderSide: BorderSide(color: c.primaryText, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: fieldRadius, borderSide: BorderSide(color: c.danger)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: fieldRadius, borderSide: BorderSide(color: c.danger, width: 1.5)),
        labelStyle: TextStyle(fontSize: 14, color: c.textMuted),
        floatingLabelStyle: TextStyle(fontSize: 14, color: c.primaryText, fontWeight: FontWeight.w600),
        hintStyle: TextStyle(fontSize: 14, color: c.textMuted),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.action,
          foregroundColor: c.onAction,
          elevation: 0,
          shape: buttonShape,
          padding: buttonPadding,
          textStyle: buttonText,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.action,
          foregroundColor: c.onAction,
          shape: buttonShape,
          padding: buttonPadding,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primaryText,
          side: BorderSide(color: c.border, width: 1.5),
          shape: buttonShape,
          padding: buttonPadding,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primaryText,
          shape: buttonShape,
          padding: buttonPadding,
          textStyle: buttonText,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: c.surface,
        selectedColor: c.action,
        secondarySelectedColor: c.action,
        checkmarkColor: c.onAction,
        side: BorderSide(color: c.border),
        shape: const StadiumBorder(),
        labelStyle: TextStyle(fontFamily: fontFamily, color: c.text, fontWeight: FontWeight.w600, fontSize: 14),
        secondaryLabelStyle: TextStyle(fontFamily: fontFamily, color: c.onAction, fontWeight: FontWeight.w600, fontSize: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: c.border,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: c.text),
    );
  }

  // ========== TEXT THEME ==========
  
  static TextTheme _buildTextTheme(Color titleColor, Color bodyColor) {
    return TextTheme(
      // Display
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: titleColor,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: titleColor,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: titleColor,
      ),
      
      // Headline
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: titleColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: titleColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: titleColor,
      ),
      
      // Title
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: titleColor,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: titleColor,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: titleColor,
      ),
      
      // Body
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: bodyColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: bodyColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: bodyColor,
      ),
      
      // Label
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: titleColor,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: titleColor,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: bodyColor,
      ),
    );
  }
}
