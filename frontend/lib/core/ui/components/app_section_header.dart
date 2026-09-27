import 'package:flutter/material.dart';
import '../theme/app_theme_colors.dart';

/// Título de seção com subtítulo e ação opcionais (ex: botão "Cadastrar" à direita)
class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final IconData? leadingIcon;
  final EdgeInsetsGeometry padding;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.leadingIcon,
    this.padding = const EdgeInsets.only(bottom: 16),
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: leadingIcon != null ? CrossAxisAlignment.center : CrossAxisAlignment.start,
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
                  style: leadingIcon != null
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
        ],
      ),
    );
  }
}
