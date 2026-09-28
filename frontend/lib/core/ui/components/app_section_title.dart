import 'package:flutter/material.dart';
import '../theme/app_theme_colors.dart';

/// Título de seção com sublinhado: o texto na cor da marca, um traço da mesma cor na largura do texto
/// e uma linha fina até o fim. [trailing] fica à direita, na mesma linha (ex: "4 lojas").
///
/// ```dart
/// AppSectionTitle(title: 'Restaurantes', trailing: Text('4 lojas'))
/// ```
class AppSectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  /// Cor do título e do traço; padrão: a cor da marca do tema
  final Color? color;
  final EdgeInsetsGeometry padding;

  const AppSectionTitle({
    super.key,
    required this.title,
    this.trailing,
    this.color,
    this.padding = const EdgeInsets.only(bottom: 20),
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final accent = color ?? c.primaryText;

    return Padding(
      padding: padding,
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          // Linha fina até o fim, atrás do traço
          Container(height: 1, color: c.border),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      style: TextStyle(color: accent, fontSize: 24, fontWeight: FontWeight.w800, height: 1.2),
                    ),
                    const SizedBox(height: 12),
                    Container(height: 3, color: accent),
                  ],
                ),
              ),
              const Spacer(),
              if (trailing != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: DefaultTextStyle.merge(style: TextStyle(color: c.textMuted, fontSize: 13), child: trailing!),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
