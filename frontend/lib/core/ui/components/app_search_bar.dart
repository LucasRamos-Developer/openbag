import 'package:flutter/material.dart';
import '../theme/app_theme_colors.dart';

/// Campo de busca em pílula, com botão de limpar quando há texto
class AppSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  const AppSearchBar({super.key, required this.controller, this.hintText = 'Buscar', this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      borderSide: BorderSide(color: c.border),
    );

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: TextStyle(color: c.text, fontSize: 15),
        decoration: InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor: c.surface,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Icon(Icons.search, color: c.textMuted),
          ),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close, color: c.textMuted),
                  tooltip: 'Limpar busca',
                  onPressed: () {
                    controller.clear();
                    onChanged?.call('');
                  },
                ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(borderSide: BorderSide(color: c.primaryText, width: 1.5)),
        ),
      ),
    );
  }
}
