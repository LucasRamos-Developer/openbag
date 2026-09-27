import 'package:flutter/material.dart';
import '../theme/app_theme_colors.dart';

/// Metadado com ícone (ex: "30-45 min", "Entrega R$ 5,00")
class AppMetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const AppMetaItem({super.key, required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? context.appColors.textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: foreground),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: foreground, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

/// Linha de metadados separados por um traço vertical; quebra linha quando não cabe.
/// Em telas estreitas use [separators] = false (o traço ficaria sobrando no fim da linha).
class AppMetaRow extends StatelessWidget {
  final List<Widget> children;
  final bool separators;

  const AppMetaRow({super.key, required this.children, this.separators = true});

  @override
  Widget build(BuildContext context) {
    final border = context.appColors.border;
    return Wrap(
      spacing: separators ? 12 : 16,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0 && separators) Container(width: 1, height: 18, color: border),
          children[i],
        ],
      ],
    );
  }
}
