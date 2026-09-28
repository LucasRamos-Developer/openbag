import 'package:flutter/material.dart';
import '../theme/app_theme_colors.dart';

/// Lista de pares rótulo → valor em linhas (simulações, resumos curtos). Legível no celular, sem chips que
/// cortam texto; os valores ficam alinhados à direita com números tabulares.
class AppKeyValueList extends StatelessWidget {
  final List<(String, String)> rows;

  const AppKeyValueList({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: colors.border),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Text(rows[i].$1, style: TextStyle(color: colors.textMuted))),
                  Text(rows[i].$2,
                      style: TextStyle(
                          color: colors.text,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
