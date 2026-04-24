import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

/// Widget para selecionar uma cor em formato hexadecimal (#RRGGBB)
class ColorPickerField extends StatelessWidget {
  final String label;
  final String value; // Formato: #RRGGBB
  final ValueChanged<String> onColorChanged;

  const ColorPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final Color currentColor = _parseColor(value);

    return InkWell(
      onTap: () => _showColorPicker(context, currentColor),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: currentColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
          ),
        ),
        child: Text(
          value.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.grey;
    }
  }

  void _showColorPicker(BuildContext context, Color currentColor) {
    Color pickedColor = currentColor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Escolha a $label'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Color picker com paleta
              ColorPicker(
                pickerColor: currentColor,
                onColorChanged: (color) {
                  pickedColor = color;
                },
                pickerAreaHeightPercent: 0.8,
                displayThumbColor: true,
                enableAlpha: false,
                labelTypes: const [],
              ),
              
              const SizedBox(height: 16),
              
              // Preview da cor selecionada
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: pickedColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Center(
                  child: Text(
                    _colorToHex(pickedColor),
                    style: TextStyle(
                      color: _getContrastColor(pickedColor),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              onColorChanged(_colorToHex(pickedColor));
              Navigator.of(context).pop();
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  Color _getContrastColor(Color color) {
    // Calcula a luminância para determinar se o texto deve ser branco ou preto
    final luminance = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
