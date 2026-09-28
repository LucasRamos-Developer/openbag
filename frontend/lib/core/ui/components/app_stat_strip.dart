import 'package:flutter/material.dart';
import '../theme/app_theme_colors.dart';

/// Um número da [AppStatStrip]
class AppStat {
  final String label;
  final String value;
  final String? caption;

  const AppStat({required this.label, required this.value, this.caption});
}

/// Faixa de números lado a lado num card só (ex: Total · Pago · Em aberto). Ocupa uma linha também no celular,
/// no lugar de vários [AppStatTile] empilhados; os valores encolhem para caber.
class AppStatStrip extends StatelessWidget {
  final List<AppStat> stats;

  const AppStatStrip({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < stats.length; i++) ...[
              if (i > 0) VerticalDivider(width: 1, color: colors.border),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stats[i].label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(stats[i].value,
                            style: TextStyle(
                                color: colors.text,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                fontFeatures: const [FontFeature.tabularFigures()])),
                      ),
                      if (stats[i].caption != null) ...[
                        const SizedBox(height: 2),
                        Text(stats[i].caption!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: colors.textMuted, fontSize: 11)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
