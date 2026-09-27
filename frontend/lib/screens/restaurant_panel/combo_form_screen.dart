import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../models/menu/menu.dart';
import '../../services/api_client.dart';
import '../../services/restaurant_panel_service.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/menu/menu_image.dart';
import '../../widgets/onboarding/compact_image_picker.dart';
import 'menu_form_route.dart';

class _ComboLine {
  int? productId;
  int quantity;

  _ComboLine({this.productId, this.quantity = 1});
}

/// Cadastro e edição de combo (itens do cardápio vendidos juntos por um preço)
class ComboFormScreen extends StatefulWidget {
  final Combo? combo;
  final int? initialSectionId;

  const ComboFormScreen({super.key, this.combo, this.initialSectionId});

  @override
  State<ComboFormScreen> createState() => _ComboFormScreenState();
}

class _ComboFormScreenState extends State<ComboFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  int? _sectionId;
  bool _available = true;
  bool _active = true;
  XFile? _newImage;
  late final List<_ComboLine> _lines;
  bool _isSaving = false;

  bool get _isNew => widget.combo == null;

  RestaurantPanelService get _service => context.read<RestaurantPanelService>();

  @override
  void initState() {
    super.initState();
    final combo = widget.combo;
    _name = TextEditingController(text: combo?.name);
    _description = TextEditingController(text: combo?.description);
    _price = TextEditingController(text: combo != null ? moneyInput(combo.price) : '');
    _sectionId = combo?.sectionId ?? widget.initialSectionId;
    _available = combo?.available ?? true;
    _active = combo?.active ?? true;
    _lines = combo == null
        ? [_ComboLine(), _ComboLine()]
        : combo.items.map((i) => _ComboLine(productId: i.productId, quantity: i.quantity)).toList();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  /// Soma dos itens se comprados separadamente (pelo preço atual)
  double _originalPrice(List<MenuItem> items) {
    final byId = {for (final i in items) i.id: i};
    return _lines.fold(0, (sum, l) => sum + (byId[l.productId]?.currentPrice ?? 0) * l.quantity);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final lines = _lines.where((l) => l.productId != null).toList();
    if (lines.isEmpty) {
      AppToast.show(context, message: 'Adicione pelo menos um item ao combo', type: ToastType.warning);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final saved = await _service.saveCombo(widget.combo?.id, {
        'sectionId': _sectionId,
        'name': _name.text.trim(),
        'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
        'price': parseMoney(_price.text),
        'available': _available,
        'active': _active,
        'items': [for (final l in lines) {'productId': l.productId, 'quantity': l.quantity}],
      });
      if (_newImage != null) {
        await _service.uploadComboImage(saved.id, _newImage!);
      }
      if (!mounted) return;
      AppToast.show(context, message: _isNew ? 'Combo criado' : 'Combo atualizado', type: ToastType.success);
      closeMenuForm(context);
    } on ApiException catch (e) {
      if (mounted) AppToast.show(context, message: e.message, type: ToastType.error, duration: const Duration(seconds: 6));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Excluir o combo "${widget.combo!.name}"?',
      message: 'O combo sai do cardápio. Os itens continuam disponíveis separadamente.',
      confirmLabel: 'Excluir',
    );
    if (!confirmed || !mounted) return;
    try {
      await _service.deleteCombo(widget.combo!.id);
      if (!mounted) return;
      AppToast.show(context, message: 'Combo excluído', type: ToastType.success);
      closeMenuForm(context);
    } on ApiException catch (e) {
      if (mounted) AppToast.show(context, message: e.message, type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<RestaurantPanelService>().menu!;
    final items = menu.allItems;
    final original = _originalPrice(items);
    final price = parseMoney(_price.text) ?? 0;
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => closeMenuForm(context)),
        title: Text(_isNew ? 'Novo combo' : 'Editar combo'),
        actions: [
          if (!_isNew) IconButton(tooltip: 'Excluir combo', icon: const Icon(Icons.delete_outline), onPressed: _delete),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const AppSectionHeader(title: 'Dados do combo'),
                AppSelect<int>(
                  labelText: 'Seção',
                  variant: TextFieldVariant.filled,
                  value: _sectionId,
                  items: [for (final s in menu.sections) SelectItem(value: s.id, label: s.name)],
                  validator: (v) => v == null ? 'Escolha a seção' : null,
                  onChanged: (v) => setState(() => _sectionId = v),
                ),
                const SizedBox(height: 28),
                AppTextField(
                  controller: _name,
                  labelText: 'Nome',
                  hintText: 'Ex: Combo X-Burger + Refri',
                  variant: TextFieldVariant.filled,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => validateRequired(v, 'Nome'),
                ),
                const SizedBox(height: 28),
                AppTextField(
                  controller: _description,
                  labelText: 'Descrição (opcional)',
                  variant: TextFieldVariant.filled,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 32),
                const AppSectionHeader(title: 'Itens do combo'),
                for (var i = 0; i < _lines.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: AppSelect<int>(
                            labelText: 'Item ${i + 1}',
                            variant: TextFieldVariant.filled,
                            value: _lines[i].productId,
                            items: [
                              for (final item in items)
                                SelectItem(value: item.id, label: item.name, description: formatMoney(item.currentPrice)),
                            ],
                            onChanged: (v) => setState(() => _lines[i].productId = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AppQuantityStepper(
                          value: _lines[i].quantity,
                          max: 20,
                          onChanged: (v) => setState(() => _lines[i].quantity = v),
                        ),
                        IconButton(
                          tooltip: 'Remover item',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: _lines.length > 1 ? () => setState(() => _lines.removeAt(i)) : null,
                        ),
                      ],
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppButton(
                    text: 'Adicionar item',
                    icon: Icons.add,
                    variant: ButtonVariant.text,
                    onPressed: () => setState(() => _lines.add(_ComboLine())),
                  ),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _price,
                  labelText: 'Preço do combo',
                  prefixText: 'R\$ ',
                  variant: TextFieldVariant.filled,
                  keyboardType: TextInputType.number,
                  inputFormatters: [MoneyFormatter()],
                  onChanged: (_) => setState(() {}),
                  validator: (v) => (parseMoney(v ?? '') ?? 0) <= 0 ? 'Informe o preço' : null,
                ),
                const SizedBox(height: 28),
                Text(
                  original > 0
                      ? 'Separados: ${formatMoney(original)}'
                          '${price > 0 && price < original ? ' · o cliente economiza ${formatMoney(original - price)}' : ''}'
                      : 'Escolha os itens para ver o valor separado',
                  style: TextStyle(color: muted),
                ),
                const SizedBox(height: 24),
                if (!_isNew && widget.combo!.imageUrl != null && _newImage == null) ...[
                  MenuImage(imageUrl: widget.combo!.imageUrl, size: 88),
                  const SizedBox(height: 12),
                ],
                CompactImagePicker(
                  label: _isNew || widget.combo!.imageUrl == null ? 'Foto do combo (opcional)' : 'Trocar foto',
                  imageFile: _newImage,
                  onImageSelected: (file) => setState(() => _newImage = file),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Disponível'),
                  value: _available,
                  onChanged: (v) => setState(() => _available = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Visível no cardápio'),
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                      text: 'Cancelar',
                      variant: ButtonVariant.text,
                      onPressed: _isSaving ? null : () => closeMenuForm(context),
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      text: _isNew ? 'Criar combo' : 'Salvar',
                      icon: Icons.check,
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : _save,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
