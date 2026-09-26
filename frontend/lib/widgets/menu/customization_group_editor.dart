import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/menu/menu.dart';
import '../../utils/formatters.dart';

/// Abre o editor de grupo de complementos. Retorna o grupo editado ou null se cancelado.
Future<CustomizationGroup?> showCustomizationGroupEditor(BuildContext context, {CustomizationGroup? group}) {
  return showDialog<CustomizationGroup>(
    context: context,
    builder: (_) => _CustomizationGroupEditor(group: group),
  );
}

class _OptionDraft {
  final int? id;
  final TextEditingController name;
  final TextEditingController price;
  bool available;

  _OptionDraft({this.id, String name = '', double price = 0, this.available = true})
      : name = TextEditingController(text: name),
        price = TextEditingController(text: moneyInput(price));

  void dispose() {
    name.dispose();
    price.dispose();
  }
}

class _CustomizationGroupEditor extends StatefulWidget {
  final CustomizationGroup? group;

  const _CustomizationGroupEditor({this.group});

  @override
  State<_CustomizationGroupEditor> createState() => _CustomizationGroupEditorState();
}

class _CustomizationGroupEditorState extends State<_CustomizationGroupEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late int _min;
  late int _max;
  late final List<_OptionDraft> _options;

  @override
  void initState() {
    super.initState();
    final group = widget.group;
    _name = TextEditingController(text: group?.name);
    _min = group?.minSelections ?? 0;
    _max = group?.maxSelections ?? 1;
    _options = group == null
        ? [_OptionDraft()]
        : group.options
            .map((o) => _OptionDraft(id: o.id, name: o.name, price: o.priceModifier, available: o.available))
            .toList();
  }

  @override
  void dispose() {
    _name.dispose();
    for (final option in _options) {
      option.dispose();
    }
    super.dispose();
  }

  void _addOption() => setState(() => _options.add(_OptionDraft()));

  void _removeOption(int index) {
    setState(() {
      _options.removeAt(index).dispose();
      _max = _max.clamp(1, _options.length);
      _min = _min.clamp(0, _max);
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(CustomizationGroup(
      id: widget.group?.id,
      name: _name.text.trim(),
      minSelections: _min,
      maxSelections: _max,
      options: [
        for (final o in _options)
          CustomizationOption(
            id: o.id,
            name: o.name.text.trim(),
            priceModifier: parseMoney(o.price.text) ?? 0,
            available: o.available,
          ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final count = _options.length;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.group == null ? 'Novo grupo de complementos' : 'Editar grupo de complementos'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _name,
                  labelText: 'Nome do grupo',
                  hintText: 'Ex: Ponto da carne, Adicionais, Escolha a bebida',
                  variant: TextFieldVariant.filled,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome do grupo' : null,
                ),
                const SizedBox(height: 24),
                AppResponsiveRow(
                  breakpoint: 400,
                  children: [
                    AppSelect<int>(
                      labelText: 'Mínimo de escolhas',
                      variant: TextFieldVariant.filled,
                      value: _min,
                      items: [
                        for (var i = 0; i <= _max; i++)
                          SelectItem(value: i, label: i == 0 ? '0 (opcional)' : '$i (obrigatório)'),
                      ],
                      onChanged: (v) => setState(() => _min = v ?? 0),
                    ),
                    AppSelect<int>(
                      labelText: 'Máximo de escolhas',
                      variant: TextFieldVariant.filled,
                      value: _max,
                      items: [for (var i = 1; i <= count; i++) SelectItem(value: i, label: '$i')],
                      onChanged: (v) => setState(() {
                        _max = v ?? 1;
                        _min = _min.clamp(0, _max);
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Opções', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                for (var i = 0; i < count; i++) ...[
                  _OptionRow(
                    key: ObjectKey(_options[i]),
                    draft: _options[i],
                    canRemove: count > 1,
                    onRemove: () => _removeOption(i),
                    onAvailabilityChanged: (v) => setState(() => _options[i].available = v),
                  ),
                  const SizedBox(height: 28),
                ],
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppButton(
                    text: 'Adicionar opção',
                    icon: Icons.add,
                    variant: ButtonVariant.text,
                    onPressed: _addOption,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        AppButton(text: 'Cancelar', variant: ButtonVariant.text, onPressed: () => Navigator.of(context).pop()),
        AppButton(text: 'Salvar grupo', onPressed: _save),
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  final _OptionDraft draft;
  final bool canRemove;
  final VoidCallback onRemove;
  final ValueChanged<bool> onAvailabilityChanged;

  const _OptionRow({
    super.key,
    required this.draft,
    required this.canRemove,
    required this.onRemove,
    required this.onAvailabilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: AppTextField(
            controller: draft.name,
            labelText: 'Opção',
            variant: TextFieldVariant.filled,
            size: TextFieldSize.small,
            textCapitalization: TextCapitalization.sentences,
            validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome' : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: AppTextField(
            controller: draft.price,
            labelText: 'Preço adicional',
            prefixText: 'R\$ ',
            variant: TextFieldVariant.filled,
            size: TextFieldSize.small,
            keyboardType: TextInputType.number,
            inputFormatters: [MoneyFormatter()],
          ),
        ),
        Tooltip(
          message: draft.available ? 'Disponível' : 'Indisponível',
          child: Switch(value: draft.available, onChanged: onAvailabilityChanged),
        ),
        IconButton(
          tooltip: 'Remover opção',
          icon: const Icon(Icons.delete_outline),
          onPressed: canRemove ? onRemove : null,
        ),
      ],
    );
  }
}
