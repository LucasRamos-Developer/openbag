import 'package:flutter/material.dart';
import '../theme/app_theme_colors.dart';

enum BadgeTone { primary, accent, danger, neutral }

/// Selo pequeno e arredondado (ex: "Combo", "Mais pedido", "Tradicional").
/// As cores vêm do tema; o texto sempre tem contraste AA com o fundo.
class AppBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final BadgeTone tone;

  const AppBadge({super.key, required this.label, this.icon, this.tone = BadgeTone.primary});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final (background, foreground) = switch (tone) {
      BadgeTone.primary => (c.secondary, c.onSecondary),
      BadgeTone.accent => _soft(c.accent, c.surface),
      BadgeTone.danger => _soft(c.danger, c.surface),
      BadgeTone.neutral => (c.surfaceAlt, c.textMuted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: foreground), const SizedBox(width: 4)],
          Text(label, style: TextStyle(color: foreground, fontSize: 12, fontWeight: FontWeight.w600, height: 1.2)),
        ],
      ),
    );
  }

  static (Color, Color) _soft(Color color, Color surface) {
    final background = Color.alphaBlend(color.withValues(alpha: 0.14), surface);
    return (background, AppThemeColors.ensureContrast(color, background));
  }
}
