import 'package:flutter/material.dart';
import '../theme/app_theme_colors.dart';

/// Título de seção com subtítulo e ação opcionais (ex: botão "Cadastrar" à direita).
///
/// Com [onToggle], vira cabeçalho de acordeão: o toque no título ou na seta recolhe e mostra o
/// conteúdo, que a tela esconde conforme [expanded].
class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final IconData? leadingIcon;
  final EdgeInsetsGeometry padding;

  /// Título grande (o mesmo de quando há [leadingIcon]), para seções de destaque como as do cardápio
  final bool prominent;

  /// Acordeão: se o conteúdo está aberto e o que fazer ao tocar (null = cabeçalho comum)
  final bool expanded;
  final VoidCallback? onToggle;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.leadingIcon,
    this.padding = const EdgeInsets.only(bottom: 16),
    this.prominent = false,
    this.expanded = true,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final large = prominent || leadingIcon != null;
    final header = Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment:
            leadingIcon != null || onToggle != null ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: 34, color: context.appColors.primaryText),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: large
                      ? textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 26)
                      : textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 12), action!],
          if (onToggle != null) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: expanded ? 'Recolher' : 'Mostrar',
              onPressed: onToggle,
              icon: AnimatedRotation(
                turns: expanded ? 0 : -0.25,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.keyboard_arrow_down_rounded, size: 30, color: context.appColors.textMuted),
              ),
            ),
          ],
        ],
      ),
    );

    if (onToggle == null) return header;
    return Semantics(
      button: true,
      expanded: expanded,
      child: InkWell(onTap: onToggle, borderRadius: BorderRadius.circular(AppRadius.md), child: header),
    );
  }
}
