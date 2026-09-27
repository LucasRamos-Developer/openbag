import 'package:flutter/material.dart';
import '../theme/app_theme_colors.dart';

/// Número de destaque (KPI): rótulo, valor grande e uma linha de apoio opcional.
/// Use em grade (`AppResponsiveGrid`) para resumos como o caixa do dia.
class AppStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final String? caption;

  /// Destaca o bloco principal com o fundo suave da cor da marca
  final bool highlighted;

  const AppStatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.caption,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlighted ? c.primary.withValues(alpha: 0.10) : c.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: highlighted ? c.primary.withValues(alpha: 0.25) : c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: c.primaryText),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: c.text,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.1,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(caption!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.textMuted, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}
