import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';

/// Escolha de tema da página: cards com a amostra das 5 cores, nome e sensação,
/// agrupados em claros e escuros
class ThemePresetPicker extends StatelessWidget {
  final AppThemePreset value;
  final ValueChanged<AppThemePreset> onChanged;

  const ThemePresetPicker({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 640 ? 4 : 2;
      final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
      Widget group(String title, bool dark) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final preset in AppThemePreset.values.where((p) => p.isDark == dark))
                    SizedBox(
                      width: width,
                      child: _PresetCard(preset: preset, selected: preset == value, onTap: () => onChanged(preset)),
                    ),
                ],
              ),
            ],
          );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [group('Claros', false), const SizedBox(height: 16), group('Escuros', true)],
      );
    });
  }
}

class _PresetCard extends StatelessWidget {
  final AppThemePreset preset;
  final bool selected;
  final VoidCallback onTap;

  const _PresetCard({required this.preset, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ui = context.appColors;
    final t = preset.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Tema ${preset.label}',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: t.background,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: selected ? ui.primaryText : ui.border, width: selected ? 2.5 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (final color in [t.primary, t.secondary, t.accent, t.text])
                    Expanded(
                      child: Container(
                        height: 26,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: t.text.withValues(alpha: 0.08)),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(preset.label,
                        style: TextStyle(color: t.text, fontWeight: FontWeight.w800, fontSize: 14), overflow: TextOverflow.ellipsis),
                  ),
                  if (selected) Icon(Icons.check_circle, size: 18, color: t.primaryText),
                ],
              ),
              const SizedBox(height: 2),
              Text(preset.mood, maxLines: 2, style: TextStyle(color: t.textMuted, fontSize: 12, height: 1.3)),
              if (preset == AppThemePreset.fallback) ...[
                const SizedBox(height: 6),
                Text('Padrão', style: TextStyle(color: t.primaryText, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
