class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://localhost:8080/api';
  
  // App Configuration
  static const String appName = 'Open Bag';
  static const String appVersion = '1.0.0';
  
  // Web Configuration
  static const double webMaxWidth = 1200.0;
  static const double tabletBreakpoint = 768.0;
  static const double mobileBreakpoint = 480.0;
  
  // Colors
  static const primaryColor = Color(0xFFE91E63);
  static const secondaryColor = Color(0xFFFF6B6B);
  static const accentColor = Color(0xFFFFB74D);
  static const backgroundColor = Color(0xFFF8F9FA);
  static const surfaceColor = Colors.white;
  static const errorColor = Color(0xFFE53E3E);
  static const successColor = Color(0xFF38A169);
  
  // Text Colors
  static const textPrimary = Color(0xFF2D3748);
  static const textSecondary = Color(0xFF718096);
  static const textLight = Color(0xFFA0AEC0);
  
  // Spacing
  static const double paddingXS = 4.0;
  static const double paddingSM = 8.0;
  static const double paddingMD = 16.0;
  static const double paddingLG = 24.0;
  static const double paddingXL = 32.0;
  
  // Border Radius
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  
  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
}

// Platform Detection
class PlatformUtils {
  static bool get isWeb => kIsWeb;
  static bool get isMobile => !kIsWeb;
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width > AppConstants.tabletBreakpoint;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= AppConstants.mobileBreakpoint && width <= AppConstants.tabletBreakpoint;
  }
  
  static bool isMobileSize(BuildContext context) {
    return MediaQuery.of(context).size.width < AppConstants.mobileBreakpoint;
  }
}
