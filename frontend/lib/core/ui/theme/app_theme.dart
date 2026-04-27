import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Configuração de tema da aplicação
/// 
/// Define o tema claro e escuro seguindo Material Design 3.
/// Pode ser facilmente customizado ou exportado para outros projetos.
class AppTheme {
  AppTheme._(); // Construtor privado

  // ========== TEMA CLARO ==========
  
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    
    // Color Scheme
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryLight.withOpacity(0.3),
      onPrimaryContainer: AppColors.primaryDark,
      
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.secondary.withOpacity(0.2),
      onSecondaryContainer: AppColors.secondaryDark,
      
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.error.withOpacity(0.2),
      onErrorContainer: AppColors.error,
      
      background: AppColors.backgroundMain,
      onBackground: AppColors.textTitle,
      
      surface: AppColors.backgroundSurface,
      onSurface: AppColors.textTitle,
      surfaceVariant: AppColors.backgroundAlt,
      onSurfaceVariant: AppColors.textBody,
      
      outline: AppColors.borderLine,
      outlineVariant: AppColors.borderLine.withOpacity(0.5),
    ),
    
    // Typography
    textTheme: _buildTextTheme(AppColors.textTitle, AppColors.textBody),
    
    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundSurface,
      foregroundColor: AppColors.textTitle,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textTitle,
        letterSpacing: 0,
      ),
    ),
    
    // Card
    cardTheme: CardThemeData(
      color: AppColors.backgroundSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.borderLine,
          width: 1,
        ),
      ),
    ),
    
    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.backgroundSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Color(0xFFDFE3E8), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Color(0xFFDFE3E8), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Color(0xFF000000), width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.error, width: 1),
      ),
      
      labelStyle: TextStyle(
        fontSize: 14,
        color: AppColors.textBody,
        fontWeight: FontWeight.w400,
      ),
      floatingLabelStyle: TextStyle(
        fontSize: 14,
        color: Color(0xFF000000),
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
    ),
    
    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: AppColors.primary.withOpacity(0.24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    ),
    
    // Outlined Button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    ),
    
    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    ),
    
    // Divider
    dividerTheme: DividerThemeData(
      color: AppColors.borderLine,
      thickness: 1,
      space: 1,
    ),
    
    // Scaffold
    scaffoldBackgroundColor: AppColors.backgroundMain,
  );

  // ========== TEMA ESCURO ==========
  
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    
    // Color Scheme
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryLight,
      onPrimary: Colors.black,
      primaryContainer: AppColors.primary,
      onPrimaryContainer: Colors.white,
      
      secondary: AppColors.secondary,
      onSecondary: Colors.black,
      secondaryContainer: AppColors.secondaryDark,
      onSecondaryContainer: Colors.white,
      
      error: AppColors.error,
      onError: Colors.black,
      errorContainer: AppColors.error.withOpacity(0.3),
      onErrorContainer: Colors.white,
      
      background: const Color(0xFF121212),
      onBackground: Colors.white,
      
      surface: const Color(0xFF1E1E1E),
      onSurface: Colors.white,
      surfaceVariant: const Color(0xFF2C2C2C),
      onSurfaceVariant: const Color(0xFFE0E0E0),
      
      outline: const Color(0xFF424242),
      outlineVariant: const Color(0xFF2C2C2C),
    ),
    
    // Typography
    textTheme: _buildTextTheme(Colors.white, const Color(0xFFE0E0E0)),
    
    scaffoldBackgroundColor: const Color(0xFF121212),
  );

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
