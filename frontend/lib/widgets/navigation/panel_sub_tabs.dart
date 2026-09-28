import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';

/// Seção de painel com sub-abas (Loja, Financeiro, Assembleia): título, pílulas roláveis na horizontal
/// (nunca quebram em duas linhas no celular) e o conteúdo da aba escolhida
class PanelSubTabs<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<SelectItem<T>> tabs;
  final T value;
  final ValueChanged<T> onSelected;
  final Widget child;

  /// No celular a barra do topo já mostra o nome da seção; o título só aparece se disser algo a mais
  /// (ex: o nome da associação na área do cooperado)
  final bool titleOnCompact;

  const PanelSubTabs({
    super.key,
    required this.title,
    this.subtitle,
    required this.tabs,
    required this.value,
    required this.onSelected,
    required this.child,
    this.titleOnCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final compact = constraints.maxWidth < AppLayout.compactWidth;
          final padding = AppLayout.contentPadding(constraints.maxWidth, top: compact ? 16 : 24, bottom: 0);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!compact || titleOnCompact)
                Padding(
                  padding: padding,
                  child: AppSectionHeader(
                    title: title,
                    // No celular o subtítulo sai: a tela é curta e as pílulas já dizem o que há na seção
                    subtitle: compact ? null : subtitle,
                    padding: const EdgeInsets.only(bottom: 8),
                  ),
                ),
              AppFilterChips<T>(
                items: tabs,
                value: value,
                onSelected: onSelected,
                padding: EdgeInsets.fromLTRB(padding.left, compact && !titleOnCompact ? 12 : 8, padding.right, 8),
              ),
            ],
          );
        }),
        Expanded(child: child),
      ],
    );
  }
}
