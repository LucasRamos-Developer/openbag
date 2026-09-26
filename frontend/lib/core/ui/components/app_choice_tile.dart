import 'package:flutter/material.dart';

/// Linha selecionável com indicador de rádio (escolha única) ou checkbox (múltipla).
/// O toque em qualquer parte da linha seleciona.
class AppChoiceTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool selected;
  final bool multiple;
  final bool enabled;
  final VoidCallback onTap;

  const AppChoiceTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    required this.selected,
    this.multiple = false,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final muted = colorScheme.onSurface.withValues(alpha: 0.6);
    final icon = multiple
        ? (selected ? Icons.check_box : Icons.check_box_outline_blank)
        : (selected ? Icons.radio_button_checked : Icons.radio_button_unchecked);

    return ListTile(
      enabled: enabled,
      selected: selected,
      onTap: enabled ? onTap : null,
      leading: leading,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(color: muted)) : null,
      trailing: Icon(icon, color: selected ? colorScheme.primary : muted),
    );
  }
}
