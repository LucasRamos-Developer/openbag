import 'package:flutter/material.dart';

/// Linha de campos que empilha em coluna quando não há largura suficiente
///
/// ```dart
/// AppResponsiveRow(
///   flex: const [1, 2],
///   children: [numeroField, complementoField],
/// )
/// ```
class AppResponsiveRow extends StatelessWidget {
  final List<Widget> children;

  /// Proporção de cada filho na linha (padrão: todos 1)
  final List<int>? flex;

  /// Abaixo desta largura os filhos são empilhados
  final double breakpoint;

  /// Espaço entre os filhos (na horizontal e na vertical)
  final double spacing;

  const AppResponsiveRow({
    super.key,
    required this.children,
    this.flex,
    this.breakpoint = 480,
    this.spacing = 16,
  }) : assert(flex == null || flex.length == children.length);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < breakpoint;
        final items = <Widget>[];

        for (var i = 0; i < children.length; i++) {
          if (i > 0) items.add(SizedBox(width: spacing, height: spacing));
          items.add(stacked ? children[i] : Expanded(flex: flex?[i] ?? 1, child: children[i]));
        }

        return stacked
            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: items)
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: items);
      },
    );
  }
}
