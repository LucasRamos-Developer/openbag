import 'package:flutter/material.dart';
import '../theme/app_theme_colors.dart';
import 'app_badge.dart';

/// Campo de etiquetas curtas: mostra as escolhidas (removíveis), sugestões de um toque
/// e um campo para escrever uma nova. Respeita [max] etiquetas de até [maxLength] caracteres.
class AppTagField extends StatefulWidget {
  final String label;
  final String? helperText;
  final List<String> value;
  final List<String> suggestions;
  final int max;
  final int maxLength;
  final ValueChanged<List<String>> onChanged;

  const AppTagField({
    super.key,
    required this.label,
    this.helperText,
    required this.value,
    this.suggestions = const [],
    this.max = 2,
    this.maxLength = 20,
    required this.onChanged,
  });

  @override
  State<AppTagField> createState() => _AppTagFieldState();
}

class _AppTagFieldState extends State<AppTagField> {
  final _input = TextEditingController();

  bool get _full => widget.value.length >= widget.max;

  bool _has(String tag) => widget.value.any((t) => t.toLowerCase() == tag.toLowerCase());

  void _add(String raw) {
    final tag = raw.trim();
    if (tag.isEmpty || _full || _has(tag)) return;
    widget.onChanged([...widget.value, tag]);
    _input.clear();
  }

  void _remove(String tag) => widget.onChanged(widget.value.where((t) => t != tag).toList());

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final available = widget.suggestions.where((s) => !_has(s)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${widget.label} (${widget.value.length}/${widget.max})', style: textTheme.titleSmall),
        if (widget.helperText != null) ...[
          const SizedBox(height: 2),
          Text(widget.helperText!, style: textTheme.bodySmall?.copyWith(color: c.textMuted)),
        ],
        const SizedBox(height: 10),
        if (widget.value.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in widget.value)
                InputChip(
                  label: Text(tag),
                  onDeleted: () => _remove(tag),
                  deleteButtonTooltipMessage: 'Remover $tag',
                  backgroundColor: c.secondary,
                  labelStyle: TextStyle(color: c.onSecondary, fontWeight: FontWeight.w600),
                  deleteIconColor: c.onSecondary,
                  side: BorderSide.none,
                ),
            ],
          ),
        if (!_full) ...[
          if (widget.value.isNotEmpty) const SizedBox(height: 12),
          TextField(
            controller: _input,
            maxLength: widget.maxLength,
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: _add,
            decoration: InputDecoration(
              hintText: 'Escreva e tecle Enter',
              counterText: '',
              suffixIcon: IconButton(icon: const Icon(Icons.add), tooltip: 'Adicionar', onPressed: () => _add(_input.text)),
            ),
          ),
          if (available.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final suggestion in available)
                  InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    onTap: () => _add(suggestion),
                    child: AppBadge(label: '+ $suggestion', tone: BadgeTone.neutral),
                  ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}
