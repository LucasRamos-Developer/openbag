import 'package:flutter/material.dart';
import '../theme/app_theme_colors.dart';
import 'app_page_container.dart';

/// Abre um formulário ou detalhe no formato certo para a tela:
/// - celular ([AppLayout.isCompact]): página em tela cheia, com ✕ no topo;
/// - telas largas: diálogo centralizado.
///
/// O [builder] normalmente devolve um [AppAdaptiveSheet], que monta o layout de cada formato.
/// ```dart
/// final saved = await showAppAdaptive<bool>(
///   context,
///   builder: (context) => AppAdaptiveSheet(
///     title: 'Novo convênio',
///     body: form,
///     actions: [AppButton(text: 'Salvar', onPressed: _save)],
///   ),
/// );
/// ```
Future<T?> showAppAdaptive<T>(BuildContext context, {required WidgetBuilder builder}) {
  if (AppLayout.isCompact(context)) {
    return Navigator.of(context).push<T>(MaterialPageRoute(fullscreenDialog: true, builder: builder));
  }
  return showDialog<T>(context: context, builder: builder);
}

/// Conteúdo de [showAppAdaptive]: título, corpo rolável e ações.
///
/// No celular as ações ficam fixas no rodapé ([AppStickyActionBar]), ocupando a largura toda,
/// com a principal (a última da lista) mais à direita. No diálogo ficam alinhadas à direita.
class AppAdaptiveSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget> actions;

  /// Largura máxima do diálogo em telas largas
  final double maxWidth;

  /// Ação ao fechar pelo ✕ (padrão: `Navigator.pop()` sem resultado)
  final VoidCallback? onClose;

  const AppAdaptiveSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    this.actions = const [],
    this.maxWidth = 560,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final compact = AppLayout.isCompact(context);
    final close = onClose ?? () => Navigator.of(context).maybePop();

    if (compact) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(tooltip: 'Fechar', icon: const Icon(Icons.close), onPressed: close),
          titleSpacing: 0,
          title: _Title(title: title, subtitle: subtitle),
        ),
        body: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), child: body),
        bottomNavigationBar: actions.isEmpty ? null : AppStickyActionBar(children: actions),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: MediaQuery.sizeOf(context).height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(child: _Title(title: title, subtitle: subtitle)),
                  IconButton(tooltip: 'Fechar', icon: const Icon(Icons.close), onPressed: close),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 16), child: body),
            ),
            if (actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 12,
                  children: actions,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _Title({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700), maxLines: 2,
            overflow: TextOverflow.ellipsis),
        if (subtitle != null)
          Text(subtitle!, style: textTheme.bodyMedium?.copyWith(color: context.appColors.textMuted),
              maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

/// Barra de ações fixa no rodapé da tela (celular): botões lado a lado ocupando a largura toda,
/// acima da área segura do aparelho
class AppStickyActionBar extends StatelessWidget {
  final List<Widget> children;

  const AppStickyActionBar({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: children[i]),
            ],
          ],
        ),
      ),
    );
  }
}

/// Opção de [showAppActionSheet]
class AppSheetAction<T> {
  final T value;
  final String label;
  final String? description;
  final IconData? icon;

  /// Ação destrutiva (encerrar, remover): aparece em vermelho
  final bool destructive;

  /// Opção atual (em listas de escolha, como filtros): aparece com ✓
  final bool selected;

  const AppSheetAction({
    required this.value,
    required this.label,
    this.description,
    this.icon,
    this.destructive = false,
    this.selected = false,
  });
}

/// Lista de ações ou de opções:
/// - celular: menu de baixo para cima, com itens grandes e fáceis de tocar;
/// - telas largas: menu suspenso junto do botão que abriu (o [context] deve ser o do botão).
///
/// Devolve o `value` escolhido ou null se o usuário fechou.
Future<T?> showAppActionSheet<T>(
  BuildContext context, {
  String? title,
  required List<AppSheetAction<T>> actions,
}) {
  if (AppLayout.isCompact(context)) {
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Text(title,
                      style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
              for (final action in actions) _SheetTile(action: action),
            ],
          ),
        ),
      ),
    );
  }

  final box = context.findRenderObject() as RenderBox?;
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
  final position = box != null && overlay != null
      ? RelativeRect.fromRect(
          Rect.fromPoints(
            box.localToGlobal(Offset(0, box.size.height), ancestor: overlay),
            box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
          ),
          Offset.zero & overlay.size,
        )
      : RelativeRect.fill;

  return showMenu<T>(
    context: context,
    position: position,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    items: [
      for (final action in actions)
        PopupMenuItem<T>(
          value: action.value,
          child: _MenuRow(action: action),
        ),
    ],
  );
}

class _SheetTile<T> extends StatelessWidget {
  final AppSheetAction<T> action;

  const _SheetTile({required this.action});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = action.destructive ? colors.danger : null;
    return ListTile(
      minTileHeight: 56,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: action.icon != null ? Icon(action.icon, color: color ?? colors.primaryText) : null,
      title: Text(action.label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      subtitle: action.description != null ? Text(action.description!) : null,
      trailing: action.selected ? Icon(Icons.check, color: colors.primaryText) : null,
      onTap: () => Navigator.of(context).pop(action.value),
    );
  }
}

class _MenuRow<T> extends StatelessWidget {
  final AppSheetAction<T> action;

  const _MenuRow({required this.action});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = action.destructive ? colors.danger : null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (action.icon != null) ...[
          Icon(action.icon, size: 20, color: color ?? colors.primaryText),
          const SizedBox(width: 12),
        ],
        Flexible(child: Text(action.label, style: TextStyle(color: color))),
        if (action.selected) ...[
          const SizedBox(width: 12),
          Icon(Icons.check, size: 18, color: colors.primaryText),
        ],
      ],
    );
  }
}
