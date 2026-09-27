import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../theme/app_theme_colors.dart';

/// Campo que mostra uma cor (#RRGGBB) e abre um seletor ao tocar
class AppColorField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? helperText;

  const AppColorField({super.key, required this.label, required this.value, required this.onChanged, this.helperText});

  @override
  Widget build(BuildContext context) {
    final color = AppThemeColors.parseHex(value) ?? Colors.grey;
    final c = context.appColors;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => _pick(context, color),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, helperText: helperText, helperMaxLines: 2),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: c.border),
              ),
            ),
            const SizedBox(width: 12),
            Text(value.toUpperCase(), style: TextStyle(color: c.text, fontSize: 15, fontWeight: FontWeight.w600)),
            const Spacer(),
            Icon(Icons.colorize_outlined, color: c.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context, Color current) async {
    var picked = current;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: current,
            onColorChanged: (color) => picked = color,
            pickerAreaHeightPercent: 0.7,
            enableAlpha: false,
            labelTypes: const [],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Usar esta cor')),
        ],
      ),
    );
    if (confirmed == true) onChanged(AppThemeColors.toHex(picked));
  }
}
