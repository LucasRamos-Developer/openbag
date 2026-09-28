import 'package:flutter/material.dart';
import '../theme/app_theme_colors.dart';
import 'app_select.dart';

/// Escolha compacta em pílula, do mesmo tamanho da busca ([AppSearchBar]): mostra a opção atual e abre
/// um menu com as outras. Boa para ordenação ou filtro de uma lista.
///
/// ```dart
/// AppPillSelect(icon: Icons.swap_vert, items: [...], value: sort, onChanged: (v) => setState(() => sort = v))
/// ```
class AppPillSelect<T> extends StatelessWidget {
  final List<SelectItem<T>> items;
  final T value;
  final ValueChanged<T> onChanged;
  final IconData? icon;

  /// Rótulo de acessibilidade e dica (ex: "Ordenar por")
  final String? tooltip;

  const AppPillSelect({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.icon,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final current = items.firstWhere((i) => i.value == value, orElse: () => items.first);

    return MenuAnchor(
      alignmentOffset: const Offset(0, 6),
      menuChildren: [
        for (final item in items)
          MenuItemButton(
            leadingIcon: Icon(item.value == value ? Icons.check : null, size: 18, color: c.primaryText),
            onPressed: () => onChanged(item.value),
            child: Text(item.label),
          ),
      ],
      builder: (context, controller, _) => Semantics(
        label: tooltip,
        button: true,
        child: Material(
          color: c.surface,
          shape: StadiumBorder(side: BorderSide(color: c.border)),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => controller.isOpen ? controller.close() : controller.open(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[Icon(icon, size: 20, color: c.textMuted), const SizedBox(width: 10)],
                    Flexible(
                      child: Text(
                        current.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: c.text, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.keyboard_arrow_down_rounded, color: c.textMuted),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
