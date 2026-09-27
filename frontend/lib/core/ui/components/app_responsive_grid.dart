import 'package:flutter/material.dart';

/// Grade de colunas iguais que se ajusta à largura: cabe quantas colunas de pelo menos
/// [minItemWidth] couberem, até [maxColumns]. Cada linha tem a altura do seu maior item.
///
/// ```dart
/// AppResponsiveGrid(children: [for (final r in restaurants) RestaurantCard(restaurant: r)])
/// ```
class AppResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int maxColumns;
  final double minItemWidth;
  final double spacing;
  final double runSpacing;

  const AppResponsiveGrid({
    super.key,
    required this.children,
    this.maxColumns = 4,
    this.minItemWidth = 220,
    this.spacing = 16,
    this.runSpacing = 20,
  });

  static int columnsFor(double width, {int maxColumns = 4, double minItemWidth = 220, double spacing = 16}) =>
      ((width + spacing) / (minItemWidth + spacing)).floor().clamp(1, maxColumns);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final columns = columnsFor(constraints.maxWidth, maxColumns: maxColumns, minItemWidth: minItemWidth, spacing: spacing);
      final itemWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: runSpacing,
        children: [for (final child in children) SizedBox(width: itemWidth, child: child)],
      );
    });
  }
}
