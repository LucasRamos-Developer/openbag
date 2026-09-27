import 'package:flutter/material.dart';

/// Medidas padrão de layout das telas
abstract final class AppLayout {
  /// Largura máxima do conteúdo de toda tela (painéis e vitrine)
  static const double maxContentWidth = 1200;

  /// Abaixo desta largura a tela é tratada como celular (gutter menor)
  static const double compactWidth = 600;

  static double gutter(double width) => width < compactWidth ? 16 : 24;

  /// Padding que centraliza o conteúdo em [maxWidth] mantendo o gutter nas laterais.
  /// Use em `ListView`/`SliverPadding` para a barra de rolagem ficar na borda da tela.
  static EdgeInsets contentPadding(
    double width, {
    double top = 24,
    double bottom = 32,
    double maxWidth = maxContentWidth,
  }) {
    final gutter = AppLayout.gutter(width);
    final side = width > maxWidth + gutter * 2 ? (width - maxWidth) / 2 : gutter;
    return EdgeInsets.fromLTRB(side, top, side, bottom);
  }
}

/// Conteúdo sem rolagem centralizado na largura padrão ([AppLayout.maxContentWidth])
class AppPageContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final double top;
  final double bottom;

  const AppPageContainer({
    super.key,
    required this.child,
    this.maxWidth = AppLayout.maxContentWidth,
    this.top = 24,
    this.bottom = 32,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Padding(
        padding: AppLayout.contentPadding(constraints.maxWidth, top: top, bottom: bottom, maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Lista rolável com o conteúdo centralizado na largura padrão; os filhos ocupam toda a largura útil
///
/// ```dart
/// AppPageListView(children: [
///   const AppSectionHeader(title: 'Avaliações'),
///   AppPanelCard(...),
/// ])
/// ```
class AppPageListView extends StatelessWidget {
  final List<Widget> children;
  final double maxWidth;
  final double top;
  final double bottom;

  const AppPageListView({
    super.key,
    required this.children,
    this.maxWidth = AppLayout.maxContentWidth,
    this.top = 24,
    this.bottom = 32,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        padding: AppLayout.contentPadding(constraints.maxWidth, top: top, bottom: bottom, maxWidth: maxWidth),
        children: children,
      ),
    );
  }
}
