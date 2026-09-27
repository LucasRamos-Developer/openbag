import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme_colors.dart';

/// Bloco de carregamento com brilho animado. Envolva vários [AppSkeleton] com [AppSkeleton.group]
/// para um brilho só atravessar a tela inteira.
class AppSkeleton extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const AppSkeleton({super.key, this.width, this.height = 16, this.radius = AppRadius.sm});

  static Widget group({required Widget child}) => Builder(builder: (context) {
        final c = context.appColors;
        return Shimmer.fromColors(baseColor: c.surfaceAlt, highlightColor: c.surface, child: child);
      });

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: context.appColors.surfaceAlt, borderRadius: BorderRadius.circular(radius)),
      );
}
