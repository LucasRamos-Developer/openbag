import 'package:flutter/material.dart';
import 'app_text_field.dart';

/// Select/Dropdown reutilizável baseado no design MUI Minimal
///
/// Suporta seleção única e múltipla com design consistente
///
/// Exemplo de uso:
/// ```dart
/// AppSelect<int>(
///   labelText: 'Categoria',
///   hintText: 'Selecione',
///   items: categories.map((c) => SelectItem(value: c.id, label: c.name)).toList(),
///   value: selectedId,
///   onChanged: (id) => setState(() => selectedId = id),
/// )
/// ```
class SelectItem<T> {
  final T value;
  final String label;
  final String? description;

  const SelectItem({
    required this.value,
    required this.label,
    this.description,
  });
}

class AppSelect<T> extends StatefulWidget {
  final String? labelText;
  final String? hintText;
  final List<SelectItem<T>> items;
  final T? value;
  final List<T>? values; // Para multi-select
  final ValueChanged<T?>? onChanged;
  final ValueChanged<List<T>>? onMultiChanged;
  final bool multiSelect;
  final String? Function(T?)? validator;
  final bool enabled;
  final TextFieldVariant variant;

  const AppSelect({
    super.key,
    this.labelText,
    this.hintText,
    required this.items,
    this.value,
    this.values,
    this.onChanged,
    this.onMultiChanged,
    this.multiSelect = false,
    this.validator,
    this.enabled = true,
    this.variant = TextFieldVariant.outlined,
  });

  @override
  State<AppSelect<T>> createState() => _AppSelectState<T>();
}

class _AppSelectState<T> extends State<AppSelect<T>> {
  String? _errorText;

  void _validate() {
    if (widget.validator != null) {
      setState(() {
        _errorText = widget.validator!(widget.value);
      });
    }
  }

  void _showSelectDialog() {
    if (!widget.enabled) return;

    showDialog(
      context: context,
      builder: (context) => _SelectDialog<T>(
        title: widget.labelText ?? 'Selecione',
        items: widget.items,
        selectedValue: widget.value,
        selectedValues: widget.values ?? [],
        multiSelect: widget.multiSelect,
        onChanged: (value) {
          widget.onChanged?.call(value);
          _validate();
        },
        onMultiChanged: (values) {
          widget.onMultiChanged?.call(values);
          _validate();
        },
      ),
    );
  }

  String _getDisplayText() {
    if (widget.multiSelect && widget.values != null && widget.values!.isNotEmpty) {
      final labels = widget.values!
          .map((v) => widget.items.firstWhere((item) => item.value == v).label)
          .toList();
      return labels.join(', ');
    }

    if (!widget.multiSelect && widget.value != null) {
      final item = widget.items.firstWhere(
        (item) => item.value == widget.value,
        orElse: () => SelectItem(value: widget.value as T, label: ''),
      );
      return item.label;
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayText = _getDisplayText();
    final hasValue = displayText.isNotEmpty;

    final borderColor = _errorText != null
        ? const Color(0xFFFF5630)
        : widget.variant == TextFieldVariant.filled
            ? Colors.transparent
            : colorScheme.outline;

    final fillColor = widget.variant == TextFieldVariant.filled
        ? colorScheme.surfaceContainerHighest.withOpacity(0.5)
        : Colors.transparent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _showSelectDialog,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.labelText != null && (hasValue || widget.variant == TextFieldVariant.filled))
                        Text(
                          widget.labelText!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      if (widget.labelText != null && hasValue) const SizedBox(height: 2),
                      Text(
                        hasValue ? displayText : (widget.hintText ?? widget.labelText ?? ''),
                        style: TextStyle(
                          fontSize: 16,
                          color: hasValue
                              ? colorScheme.onSurface
                              : colorScheme.onSurface.withOpacity(0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
        if (_errorText != null)
          Positioned(
            left: 0,
            top: 52,
            child: Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Text(
                _errorText!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFFF5630),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SelectDialog<T> extends StatefulWidget {
  final String title;
  final List<SelectItem<T>> items;
  final T? selectedValue;
  final List<T> selectedValues;
  final bool multiSelect;
  final ValueChanged<T?>? onChanged;
  final ValueChanged<List<T>>? onMultiChanged;

  const _SelectDialog({
    required this.title,
    required this.items,
    this.selectedValue,
    required this.selectedValues,
    required this.multiSelect,
    this.onChanged,
    this.onMultiChanged,
  });

  @override
  State<_SelectDialog<T>> createState() => _SelectDialogState<T>();
}

class _SelectDialogState<T> extends State<_SelectDialog<T>> {
  late List<T> _tempSelectedValues;

  @override
  void initState() {
    super.initState();
    _tempSelectedValues = List.from(widget.selectedValues);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Items list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  final isSelected = widget.multiSelect
                      ? _tempSelectedValues.contains(item.value)
                      : widget.selectedValue == item.value;

                  return ListTile(
                    title: Text(item.label),
                    subtitle: item.description != null ? Text(item.description!) : null,
                    leading: widget.multiSelect
                        ? Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleSelection(item.value),
                          )
                        : null,
                    trailing: !widget.multiSelect && isSelected
                        ? Icon(Icons.check, color: colorScheme.primary)
                        : null,
                    onTap: () => widget.multiSelect
                        ? _toggleSelection(item.value)
                        : _selectSingle(item.value),
                  );
                },
              ),
            ),

            // Footer (only for multiselect)
            if (widget.multiSelect) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        widget.onMultiChanged?.call(_tempSelectedValues);
                        Navigator.of(context).pop();
                      },
                      child: const Text('Confirmar'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _toggleSelection(T value) {
    setState(() {
      if (_tempSelectedValues.contains(value)) {
        _tempSelectedValues.remove(value);
      } else {
        _tempSelectedValues.add(value);
      }
    });
  }

  void _selectSingle(T value) {
    widget.onChanged?.call(value);
    Navigator.of(context).pop();
  }
}
