import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../models/menu/menu.dart';
import '../../services/api_client.dart';
import '../../services/restaurant_panel_service.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/menu/customization_group_editor.dart';
import '../../widgets/menu/menu_image.dart';
import '../../widgets/onboarding/compact_image_picker.dart';
import 'menu_form_route.dart';

/// Cadastro e edição de item do cardápio.
/// Em item novo, foto e complementos ficam em rascunho e são enviados logo após criar o item.
class MenuItemFormScreen extends StatefulWidget {
  final MenuItem? item;
  final int? initialSectionId;

  const MenuItemFormScreen({super.key, this.item, this.initialSectionId});

  @override
  State<MenuItemFormScreen> createState() => _MenuItemFormScreenState();
}

class _MenuItemFormScreenState extends State<MenuItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _promotionalPrice;
  late final TextEditingController _preparationTime;

  int? _sectionId;
  bool _available = true;
  bool _active = true;
  XFile? _newImage;
  late List<CustomizationGroup> _groups;
  late List<String> _badges;
  bool _isSaving = false;

  static const _badgeSuggestions = ['Tradicional', 'Especial', 'Novo', 'Picante', 'Vegano', 'Vegetariano', 'Sem glúten', 'Artesanal'];

  bool get _isNew => widget.item == null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name = TextEditingController(text: item?.name);
    _description = TextEditingController(text: item?.description);
    _price = TextEditingController(text: item != null ? moneyInput(item.price) : '');
    _promotionalPrice =
        TextEditingController(text: item?.promotionalPrice != null ? moneyInput(item!.promotionalPrice!) : '');
    _preparationTime = TextEditingController(text: item?.preparationTime?.toString());
    _sectionId = item?.sectionId ?? widget.initialSectionId;
    _available = item?.available ?? true;
    _active = item?.active ?? true;
    _groups = List.of(item?.customizationGroups ?? const []);
    _badges = List.of(item?.badges ?? const []);
  }

  @override
  void dispose() {
    for (final c in [_name, _description, _price, _promotionalPrice, _preparationTime]) {
      c.dispose();
    }
    super.dispose();
  }

  RestaurantPanelService get _service => context.read<RestaurantPanelService>();

  /// Item atualizado a partir do cardápio recarregado (após salvar grupos ou foto)
  MenuItem? _currentItem() {
    if (widget.item == null) return null;
    final items = _service.menu!.allItems.where((i) => i.id == widget.item!.id);
    return items.isEmpty ? null : items.first;
  }

  String? _validatePromotion(String? value) {
    final promo = parseMoney(value ?? '');
    final price = parseMoney(_price.text);
    if (promo != null && price != null && promo >= price) {
      return 'Deve ser menor que o preço normal';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final saved = await _service.saveItem(widget.item?.id, {
        'sectionId': _sectionId,
        'name': _name.text.trim(),
        'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
        'price': parseMoney(_price.text),
        'promotionalPrice': parseMoney(_promotionalPrice.text),
        'preparationTime': int.tryParse(_preparationTime.text),
        'badges': _badges,
        'available': _available,
        'active': _active,
      });

      // Em item novo, envia o que ficou em rascunho
      if (_newImage != null) {
        await _service.uploadItemImage(saved.id, _newImage!);
      }
      if (_isNew) {
        for (final group in _groups) {
          await _service.saveCustomizationGroup(saved.id, group);
        }
      }

      if (!mounted) return;
      AppToast.show(context, message: _isNew ? 'Item criado' : 'Item atualizado', type: ToastType.success);
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
      title: 'Excluir "${widget.item!.name}"?',
      message: 'O item sai do cardápio. Pedidos antigos continuam com o histórico.',
      confirmLabel: 'Excluir',
    );
    if (!confirmed || !mounted) return;
    try {
      await _service.deleteItem(widget.item!.id);
      if (!mounted) return;
      AppToast.show(context, message: 'Item excluído', type: ToastType.success);
      closeMenuForm(context);
    } on ApiException catch (e) {
      if (mounted) AppToast.show(context, message: e.message, type: ToastType.error, duration: const Duration(seconds: 6));
    }
  }

  Future<void> _removeImage() async {
    try {
      await _service.removeItemImage(widget.item!.id);
      if (mounted) setState(() {});
    } on ApiException catch (e) {
      if (mounted) AppToast.show(context, message: e.message, type: ToastType.error);
    }
  }

  // ============= Complementos =============

  Future<void> _editGroup(CustomizationGroup? group, {int? index}) async {
    final edited = await showCustomizationGroupEditor(context, group: group);
    if (edited == null || !mounted) return;

    if (_isNew) {
      setState(() => index == null ? _groups.add(edited) : _groups[index] = edited);
      return;
    }
    try {
      await _service.saveCustomizationGroup(widget.item!.id, edited);
      if (mounted) setState(() => _groups = List.of(_currentItem()?.customizationGroups ?? _groups));
    } on ApiException catch (e) {
      if (mounted) AppToast.show(context, message: e.message, type: ToastType.error, duration: const Duration(seconds: 6));
    }
  }

  Future<void> _deleteGroup(int index) async {
    final group = _groups[index];
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Excluir o grupo "${group.name}"?',
      message: 'As opções deste grupo deixam de aparecer para o cliente.',
      confirmLabel: 'Excluir',
    );
    if (!confirmed || !mounted) return;

    if (_isNew || group.id == null) {
      setState(() => _groups.removeAt(index));
      return;
    }
    try {
      await _service.deleteCustomizationGroup(group.id!);
      if (mounted) setState(() => _groups.removeAt(index));
    } on ApiException catch (e) {
      if (mounted) AppToast.show(context, message: e.message, type: ToastType.error, duration: const Duration(seconds: 6));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = context.watch<RestaurantPanelService>().menu!.sections;
    final currentImage = _currentItem()?.imageUrl;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => closeMenuForm(context)),
        title: Text(_isNew ? 'Novo item' : 'Editar item'),
        actions: [
          if (!_isNew)
            IconButton(tooltip: 'Excluir item', icon: const Icon(Icons.delete_outline), onPressed: _delete),
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
                const AppSectionHeader(title: 'Dados do item'),
                AppSelect<int>(
                  labelText: 'Seção',
                  variant: TextFieldVariant.filled,
                  value: _sectionId,
                  items: [for (final s in sections) SelectItem(value: s.id, label: s.name)],
                  validator: (v) => v == null ? 'Escolha a seção' : null,
                  onChanged: (v) => setState(() => _sectionId = v),
                ),
                const SizedBox(height: 28),
                AppTextField(
                  controller: _name,
                  labelText: 'Nome',
                  hintText: 'Ex: X-Burger',
                  variant: TextFieldVariant.filled,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => validateRequired(v, 'Nome'),
                ),
                const SizedBox(height: 28),
                AppTextField(
                  controller: _description,
                  labelText: 'Descrição (opcional)',
                  hintText: 'Ingredientes, tamanho, serve quantas pessoas...',
                  variant: TextFieldVariant.filled,
                  maxLines: 3,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 20),
                AppResponsiveRow(
                  children: [
                    AppTextField(
                      controller: _price,
                      labelText: 'Preço',
                      prefixText: 'R\$ ',
                      variant: TextFieldVariant.filled,
                      keyboardType: TextInputType.number,
                      inputFormatters: [MoneyFormatter()],
                      validator: (v) => (parseMoney(v ?? '') ?? 0) <= 0 ? 'Informe o preço' : null,
                    ),
                    AppTextField(
                      controller: _promotionalPrice,
                      labelText: 'Preço promocional (opcional)',
                      prefixText: 'R\$ ',
                      variant: TextFieldVariant.filled,
                      keyboardType: TextInputType.number,
                      inputFormatters: [MoneyFormatter()],
                      validator: _validatePromotion,
                    ),
                    AppTextField(
                      controller: _preparationTime,
                      labelText: 'Preparo (opcional)',
                      suffixText: 'min',
                      variant: TextFieldVariant.filled,
                      keyboardType: TextInputType.number,
                      inputFormatters: [IntegerFormatter()],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                AppTagField(
                  label: 'Selos',
                  helperText: 'Aparecem no card do item. Promoção e Combo são mostrados automaticamente.',
                  value: _badges,
                  suggestions: _badgeSuggestions,
                  onChanged: (badges) => setState(() => _badges = badges),
                ),
                const SizedBox(height: 28),
                _buildPhoto(currentImage),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Disponível'),
                  subtitle: const Text('Desligue quando o item esgotar'),
                  value: _available,
                  onChanged: (v) => setState(() => _available = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Visível no cardápio'),
                  subtitle: const Text('Itens ocultos não aparecem para os clientes'),
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                ),
                const SizedBox(height: 24),
                AppSectionHeader(
                  title: 'Complementos',
                  subtitle: 'Opções que o cliente escolhe, como ponto da carne ou adicionais',
                  action: AppButton(
                    text: 'Novo grupo',
                    icon: Icons.add,
                    variant: ButtonVariant.soft,
                    size: ButtonSize.small,
                    onPressed: () => _editGroup(null),
                  ),
                ),
                if (_groups.isEmpty)
                  Text('Nenhum complemento.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                for (var i = 0; i < _groups.length; i++) _buildGroup(i),
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
                      text: _isNew ? 'Criar item' : 'Salvar',
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

  Widget _buildPhoto(String? currentImage) {
    if (_isNew || currentImage == null) {
      return CompactImagePicker(
        label: 'Foto do item (opcional)',
        imageFile: _newImage,
        onImageSelected: (file) => setState(() => _newImage = file),
      );
    }
    return Row(
      children: [
        MenuImage(imageUrl: currentImage, size: 88),
        const SizedBox(width: 16),
        Expanded(
          child: CompactImagePicker(
            label: 'Trocar foto',
            imageFile: _newImage,
            onImageSelected: (file) => setState(() => _newImage = file),
          ),
        ),
        IconButton(tooltip: 'Remover foto', icon: const Icon(Icons.hide_image_outlined), onPressed: _removeImage),
      ],
    );
  }

  Widget _buildGroup(int index) {
    final group = _groups[index];
    final options = group.options
        .map((o) => o.priceModifier > 0 ? '${o.name} (+${formatMoney(o.priceModifier)})' : o.name)
        .join(', ');
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      borderColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
      borderWidth: 1,
      onTap: () => _editGroup(group, index: index),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(group.ruleLabel, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(options, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(tooltip: 'Excluir grupo', icon: const Icon(Icons.delete_outline), onPressed: () => _deleteGroup(index)),
        ],
      ),
    );
  }
}
