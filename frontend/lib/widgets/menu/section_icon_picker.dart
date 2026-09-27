import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import 'menu_section_icons.dart';

/// Grade de ícones para a seção do cardápio (catálogo de [MenuSectionIcons])
class SectionIconPicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const SectionIconPicker({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in MenuSectionIcons.catalog.entries)
          Tooltip(
            message: entry.value.label,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: () => onChanged(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: entry.key == value ? c.action : c.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(entry.value.icon, color: entry.key == value ? c.onAction : c.textMuted),
              ),
            ),
          ),
      ],
    );
  }
}
