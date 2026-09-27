import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';

/// Aplica o tema escolhido pelo restaurante (preset + cor da marca opcional) aos filhos
class RestaurantThemeScope extends StatelessWidget {
  final String? themePreset;
  final String? brandColor;
  final Widget child;

  const RestaurantThemeScope({super.key, required this.themePreset, this.brandColor, required this.child});

  static AppThemeColors colorsFor(String? themePreset, String? brandColor) =>
      AppThemeColors.resolve(AppThemePreset.fromKey(themePreset), brandColor: brandColor);

  @override
  Widget build(BuildContext context) =>
      Theme(data: AppTheme.fromColors(colorsFor(themePreset, brandColor)), child: child);
}
