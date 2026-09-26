import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/ui/ui.dart';
import '../../../models/menu/menu.dart';
import '../../../utils/feedback.dart';
import '../../../services/restaurant_panel_service.dart';
import '../../../widgets/menu/menu_item_tile.dart';
import '../combo_form_screen.dart';
import '../menu_item_form_screen.dart';

/// Aba Cardápio: seções (arraste para ordenar), itens e combos
class MenuTab extends StatelessWidget {
  const MenuTab({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<RestaurantPanelService>();
    final menu = service.menu!;
    final itemCount = menu.allItems.length;

    return RefreshIndicator(
      onRefresh: service.refreshMenu,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            sliver: SliverToBoxAdapter(
              child: AppSectionHeader(
                title: 'Cardápio',
                subtitle: '${menu.sections.length} seções · $itemCount itens',
                action: AppButton(
                  text: 'Nova seção',
                  icon: Icons.add,
                  onPressed: () => _editSection(context, null),
                ),
              ),
            ),
          ),
          if (menu.unsectionedItems.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(child: _UnsectionedWarning(items: menu.unsectionedItems)),
            ),
          if (menu.sections.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: AppEmptyState(
                icon: Icons.restaurant_menu_outlined,
                message: 'Seu cardápio está vazio.\nComece criando uma seção, como "Lanches" ou "Bebidas".',
                actionLabel: 'Criar primeira seção',
                onAction: () => _editSection(context, null),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              sliver: SliverReorderableList(
                itemCount: menu.sections.length,
                onReorder: (oldIndex, newIndex) => _reorderSections(context, menu, oldIndex, newIndex),
                itemBuilder: (context, index) {
                  final section = menu.sections[index];
                  return Padding(
                    key: ValueKey(section.id),
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _SectionCard(section: section, index: index),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _reorderSections(BuildContext context, Menu menu, int oldIndex, int newIndex) async {
    final ids = menu.sections.map((s) => s.id).toList();
    if (newIndex > oldIndex) newIndex -= 1;
    ids.insert(newIndex, ids.removeAt(oldIndex));
    await runWithFeedback(context, () => context.read<RestaurantPanelService>().reorderSections(ids));
  }
}

Future<void> _editSection(BuildContext context, MenuSection? section) async {
  final result = await showDialog<({String name, String? description})>(
    context: context,
    builder: (_) => _SectionDialog(section: section),
  );
  if (result == null || !context.mounted) return;

  final service = context.read<RestaurantPanelService>();
  await runWithFeedback(
    context,
    () => section == null
        ? service.createSection(result.name, description: result.description)
        : service.updateSection(section, name: result.name, description: result.description),
    success: section == null ? 'Seção criada' : 'Seção atualizada',
  );
}

class _SectionCard extends StatelessWidget {
  final MenuSection section;
  final int index;

  const _SectionCard({required this.section, required this.index});

  Future<void> _openItem(BuildContext context, {MenuItem? item}) => Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MenuItemFormScreen(item: item, initialSectionId: section.id)));

  Future<void> _openCombo(BuildContext context, {Combo? combo}) => Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ComboFormScreen(combo: combo, initialSectionId: section.id)));

  Future<void> _onMenuAction(BuildContext context, String action) async {
    final service = context.read<RestaurantPanelService>();
    switch (action) {
      case 'edit':
        await _editSection(context, section);
      case 'toggle':
        await runWithFeedback(context, () => service.updateSection(section,
            name: section.name, description: section.description, active: !section.active));
      case 'delete':
        final confirmed = await AppDialog.confirm(
          context,
          title: 'Excluir a seção "${section.name}"?',
          message: 'Só é possível excluir seções vazias.',
          confirmLabel: 'Excluir',
        );
        if (confirmed && context.mounted) {
          await runWithFeedback(context, () => service.deleteSection(section.id), success: 'Seção excluída');
        }
    }
  }

  Future<void> _reorderItems(BuildContext context, int oldIndex, int newIndex) async {
    final ids = section.items.map((i) => i.id).toList();
    if (newIndex > oldIndex) newIndex -= 1;
    ids.insert(newIndex, ids.removeAt(oldIndex));
    await runWithFeedback(context, () => context.read<RestaurantPanelService>().reorderItems(section.id, ids));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final service = context.read<RestaurantPanelService>();

    return AppCard(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      borderColor: colorScheme.outline.withValues(alpha: 0.15),
      borderWidth: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.drag_indicator),
                ),
              ),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(section.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    if (!section.active) const AppStatusChip(label: 'Oculta', color: AppColors.grey600),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opções da seção',
                onSelected: (action) => _onMenuAction(context, action),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'toggle', child: Text(section.active ? 'Ocultar do cardápio' : 'Mostrar no cardápio')),
                  const PopupMenuItem(value: 'delete', child: Text('Excluir')),
                ],
              ),
            ],
          ),
          if (section.description != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(48, 0, 16, 8),
              child: Text(section.description!,
                  style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6))),
            ),
          if (section.items.isEmpty && section.combos.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Nenhum item nesta seção ainda.',
                  style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6))),
            ),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: section.items.length,
            onReorder: (oldIndex, newIndex) => _reorderItems(context, oldIndex, newIndex),
            itemBuilder: (context, i) {
              final item = section.items[i];
              return Row(
                key: ValueKey('item-${item.id}'),
                children: [
                  ReorderableDragStartListener(
                    index: i,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.drag_handle, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                    ),
                  ),
                  Expanded(
                    child: MenuItemTile(
                      name: item.name,
                      description: item.description,
                      price: item.price,
                      promotionalPrice: item.promotionalPrice,
                      imageUrl: item.imageUrl,
                      available: item.available,
                      active: item.active,
                      subtitle: item.customizationGroups.isEmpty
                          ? null
                          : '${item.customizationGroups.length} grupo(s) de complementos',
                      onTap: () => _openItem(context, item: item),
                      trailing: _AvailabilitySwitch(
                        available: item.available,
                        onChanged: (v) => runWithFeedback(context, () => service.setItemAvailability(item.id, v)),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          for (final combo in section.combos)
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: MenuItemTile(
                name: '${combo.name}  ·  Combo',
                description: combo.description,
                price: combo.originalPrice > combo.price ? combo.originalPrice : combo.price,
                promotionalPrice: combo.originalPrice > combo.price ? combo.price : null,
                imageUrl: combo.imageUrl,
                available: combo.available,
                active: combo.active,
                subtitle: combo.itemsSummary,
                onTap: () => _openCombo(context, combo: combo),
                trailing: _AvailabilitySwitch(
                  available: combo.available,
                  onChanged: (v) => runWithFeedback(context, () => service.setComboAvailability(combo.id, v)),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              AppButton(
                text: 'Adicionar item',
                icon: Icons.add,
                variant: ButtonVariant.soft,
                size: ButtonSize.small,
                onPressed: () => _openItem(context),
              ),
              AppButton(
                text: 'Adicionar combo',
                icon: Icons.add,
                variant: ButtonVariant.text,
                size: ButtonSize.small,
                onPressed: section.items.isEmpty && context.read<RestaurantPanelService>().menu!.allItems.isEmpty
                    ? null
                    : () => _openCombo(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Liga/desliga a disponibilidade (esgotado) com um toque
class _AvailabilitySwitch extends StatelessWidget {
  final bool available;
  final ValueChanged<bool> onChanged;

  const _AvailabilitySwitch({required this.available, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: available ? 'Disponível — toque para marcar como esgotado' : 'Esgotado — toque para disponibilizar',
      child: Switch(value: available, onChanged: onChanged),
    );
  }
}

class _UnsectionedWarning extends StatelessWidget {
  final List<MenuItem> items;

  const _UnsectionedWarning({required this.items});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: AppColors.warningLighter.withValues(alpha: 0.5),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${items.length} item(ns) sem seção não aparecem no cardápio. Abra cada um e escolha uma seção:',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in items)
                ActionChip(
                  label: Text(item.name),
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => MenuItemFormScreen(item: item))),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionDialog extends StatefulWidget {
  final MenuSection? section;

  const _SectionDialog({this.section});

  @override
  State<_SectionDialog> createState() => _SectionDialogState();
}

class _SectionDialogState extends State<_SectionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: widget.section?.name);
  late final TextEditingController _description = TextEditingController(text: widget.section?.description);

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.section == null ? 'Nova seção' : 'Editar seção'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: _name,
                labelText: 'Nome',
                hintText: 'Ex: Lanches, Bebidas, Promoções',
                variant: TextFieldVariant.filled,
                textCapitalization: TextCapitalization.sentences,
                autofocus: true,
                validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome da seção' : null,
              ),
              const SizedBox(height: 28),
              AppTextField(
                controller: _description,
                labelText: 'Descrição (opcional)',
                variant: TextFieldVariant.filled,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
      ),
      actions: [
        AppButton(text: 'Cancelar', variant: ButtonVariant.text, onPressed: () => Navigator.of(context).pop()),
        AppButton(
          text: 'Salvar',
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final description = _description.text.trim();
            Navigator.of(context).pop((name: _name.text.trim(), description: description.isEmpty ? null : description));
          },
        ),
      ],
    );
  }
}
