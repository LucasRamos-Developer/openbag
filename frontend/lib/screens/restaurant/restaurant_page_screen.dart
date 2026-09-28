import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../models/menu/menu.dart';
import '../../models/restaurant.dart';
import '../../services/api_client.dart';
import '../../services/cart_service.dart';
import '../../services/restaurant_service.dart';
import '../../widgets/cart/cart_bar.dart';
import '../../widgets/menu/item_detail_sheet.dart';
import '../../widgets/menu/menu_product_card.dart';
import '../../widgets/menu/menu_section_icons.dart';
import '../../widgets/restaurant/opening_hours_list.dart';
import '../../widgets/restaurant/restaurant_header.dart';
import '../../widgets/restaurant/restaurant_page_skeleton.dart';
import '../../widgets/restaurant/restaurant_theme_scope.dart';
import '../../widgets/navigation/storefront_footer.dart';
import '../../widgets/navigation/storefront_scaffold.dart';
import '../../widgets/restaurant/open_in_maps_button.dart';

/// Página pública do restaurante (padrão visual: layout/restaurante-padrão.png)
///
/// Usa o tema escolhido pelo dono. [previewTheme]/[previewColor] (query `?tema=`/`?cor=`)
/// trocam só o visual, para o dono ver um tema antes de salvar.
class RestaurantPageScreen extends StatefulWidget {
  final String slug;
  final String? previewTheme;
  final String? previewColor;

  const RestaurantPageScreen({super.key, required this.slug, this.previewTheme, this.previewColor});

  @override
  State<RestaurantPageScreen> createState() => _RestaurantPageScreenState();
}

class _RestaurantPageScreenState extends State<RestaurantPageScreen> {
  static const double _maxWidth = AppLayout.maxContentWidth;
  static const double _tabsHeight = 64;

  /// Altura da barra de navegação transparente sobre a página (atualizada no build)
  double _topInset = 0;

  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final Map<int, GlobalKey> _sectionKeys = {};

  Restaurant? _restaurant;
  Menu? _menu;
  String? _error;
  String _query = '';
  int? _activeSectionId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateActiveSection);
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final service = context.read<RestaurantService>();
      final results = await Future.wait([service.fetchRestaurant(widget.slug), service.fetchMenu(widget.slug)]);
      if (!mounted) return;
      setState(() {
        _restaurant = results[0] as Restaurant;
        _menu = results[1] as Menu;
        _sectionKeys
          ..clear()
          ..addEntries(_menu!.sections.map((s) => MapEntry(s.id, GlobalKey())));
        _activeSectionId = _menu!.sections.isNotEmpty ? _menu!.sections.first.id : null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  bool get _previewing => widget.previewTheme != null || widget.previewColor != null;

  // ============= Seções: acompanha a rolagem e rola até a seção =============

  void _updateActiveSection() {
    int? active;
    for (final entry in _sectionKeys.entries) {
      final box = entry.value.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      if (box.localToGlobal(Offset.zero).dy <= _topInset + _tabsHeight + 110) active = entry.key;
    }
    if (active != null && active != _activeSectionId) setState(() => _activeSectionId = active);
  }

  // ============= Acordeão das seções =============

  /// Seções recolhidas pelo cliente (o toque no título ou na seta)
  final Set<int> _collapsed = {};

  bool _isCollapsed(int sectionId) => _query.isEmpty && _collapsed.contains(sectionId);

  void _toggleSection(int sectionId) => setState(() {
        if (!_collapsed.remove(sectionId)) _collapsed.add(sectionId);
      });

  static String _countLabel(int count) => '$count ${count == 1 ? 'item' : 'itens'}';

  void _scrollToSection(int sectionId) {
    // O chip de uma seção recolhida abre a seção antes de rolar até ela
    if (_collapsed.remove(sectionId)) {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSection(sectionId));
      return;
    }
    final context = _sectionKeys[sectionId]?.currentContext;
    if (context == null) return;
    setState(() => _activeSectionId = sectionId);
    // Para logo abaixo da barra de navegação e dos chips de seção fixos
    final box = context.findRenderObject() as RenderBox;
    final position = _scrollController.position;
    final target = position.pixels + box.localToGlobal(Offset.zero).dy - _topInset - _tabsHeight - 8;
    _scrollController.animateTo(
      target.clamp(position.minScrollExtent, position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  // ============= Carrinho =============

  CartRestaurant get _cartRestaurant => CartRestaurant(
        id: _restaurant!.id,
        slug: _restaurant!.slug,
        name: _restaurant!.name,
        logoUrl: _restaurant!.logoUrl,
        deliveryFee: _restaurant!.deliveryFee,
        deliveryFeeByDistance: _restaurant!.deliveryFeeByDistance,
        minimumOrder: _restaurant!.minimumOrder,
      );

  /// Abre os detalhes; [themedContext] fica abaixo do tema do restaurante, então a folha herda as cores
  Future<void> _open(BuildContext themedContext, {MenuItem? item, Combo? combo}) async {
    final line = await showItemDetailSheet(themedContext, item: item, combo: combo, canOrder: _restaurant!.openNow);
    if (line == null || !mounted) return;
    await _addToCart(line);
  }

  /// Botão de carrinho do card: adiciona direto quando não há complementos para escolher
  Future<void> _quickAdd(BuildContext themedContext, {MenuItem? item, Combo? combo}) async {
    if (item != null && item.customizationGroups.isNotEmpty) {
      return _open(themedContext, item: item);
    }
    await _addToCart(CartLine(
      productId: item?.id,
      comboId: combo?.id,
      name: item?.name ?? combo!.name,
      imageUrl: item?.imageUrl ?? combo?.imageUrl,
      unitPrice: item?.currentPrice ?? combo!.price,
      quantity: 1,
    ));
  }

  Future<void> _addToCart(CartLine line) async {
    final cart = context.read<CartService>();
    try {
      cart.add(line, _cartRestaurant);
    } on CartConflictException catch (e) {
      final replace = await AppDialog.confirm(
        context,
        title: 'Começar um novo carrinho?',
        message: 'Seu carrinho tem itens de ${e.currentRestaurant}. Para pedir aqui, os itens atuais serão removidos.',
        confirmLabel: 'Limpar e adicionar',
      );
      if (!replace || !mounted) return;
      cart.add(line, _cartRestaurant, replace: true);
    }
    if (mounted) AppToast.show(context, message: '${line.name} adicionado ao carrinho', type: ToastType.success);
  }

  void _back() => StorefrontScaffold.back(context);

  // ============= Build =============

  bool _matches(String text) => text.toLowerCase().contains(_query.toLowerCase());

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return StorefrontScaffold(
        title: 'Restaurante',
        body: AppEmptyState(
            icon: Icons.storefront_outlined, message: _error!, actionLabel: 'Tentar novamente', onAction: _load),
      );
    }
    if (_restaurant == null || _menu == null) {
      return StorefrontScaffold(
        body: Builder(
          builder: (context) => Padding(
            padding: EdgeInsets.only(top: StorefrontScaffold.topInset(context)),
            child: const RestaurantPageSkeleton(),
          ),
        ),
      );
    }

    final restaurant = _restaurant!;
    return RestaurantThemeScope(
      themePreset: widget.previewTheme ?? restaurant.themePreset,
      brandColor: _previewing ? widget.previewColor : restaurant.brandColor,
      child: Builder(builder: (themedContext) => _buildPage(themedContext, restaurant)),
    );
  }

  Widget _buildPage(BuildContext context, Restaurant restaurant) {
    final colors = context.appColors;
    final canOrder = restaurant.openNow;
    final sections = _menu!.sections
        .map((s) => (
              section: s,
              items: s.items.where((i) => _query.isEmpty || _matches(i.name) || _matches(i.description ?? '')).toList(),
              combos: s.combos.where((c) => _query.isEmpty || _matches(c.name) || _matches(c.itemsSummary)).toList(),
            ))
        .where((s) => s.items.isNotEmpty || s.combos.isNotEmpty)
        .toList();

    return StorefrontScaffold(
      bottomNavigationBar: CartBar(restaurantId: restaurant.id),
      body: LayoutBuilder(builder: (context, constraints) {
        _topInset = StorefrontScaffold.topInset(context);
        final side = constraints.maxWidth > _maxWidth ? (constraints.maxWidth - _maxWidth) / 2 : 0.0;
        final compact = constraints.maxWidth < 600;
        final gutter = compact ? 12.0 : 24.0;
        final content = EdgeInsets.symmetric(horizontal: side + gutter);

        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            if (_previewing)
              SliverToBoxAdapter(child: _PreviewStrip(onClose: () => context.go('/r/${restaurant.slug}'))),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: side),
              sliver: SliverToBoxAdapter(
                child: RestaurantHeader(
                  restaurant: restaurant,
                  onBack: _back,
                  onAbout: () => _showAbout(context, restaurant),
                  topInset: _topInset,
                ),
              ),
            ),
            if (!restaurant.openNow)
              SliverPadding(padding: content, sliver: SliverToBoxAdapter(child: _ClosedBanner(restaurant: restaurant))),
            // Busca + chips de seção num bloco só: rolando, a busca some e os chips ficam fixos abaixo da barra
            SliverPersistentHeader(
              pinned: true,
              delegate: _SearchAndTabsDelegate(
                search: AppSearchBar(
                  controller: _searchController,
                  hintText: 'Buscar no cardápio...',
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
                sections: _query.isEmpty && _menu!.sections.length > 1 ? _menu!.sections : const [],
                activeId: _activeSectionId,
                onSelected: _scrollToSection,
                horizontal: side + gutter,
                background: colors.background,
                topInset: _topInset,
              ),
            ),
            if (sections.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppEmptyState(
                  icon: Icons.restaurant_menu_outlined,
                  message:
                      _query.isEmpty ? 'O cardápio ainda está sendo preparado.' : 'Nada encontrado para "$_query".',
                ),
              ),
            for (final s in sections) ...[
              SliverPadding(
                padding: content.copyWith(top: 28, bottom: 14),
                sliver: SliverToBoxAdapter(
                  child: AppSectionTitle(
                    key: _query.isEmpty ? _sectionKeys[s.section.id] : null,
                    title: s.section.name,
                    subtitle: _isCollapsed(s.section.id)
                        ? _countLabel(s.items.length + s.combos.length)
                        : s.section.description,
                    padding: EdgeInsets.zero,
                    // Acordeão: o toque no título ou na seta recolhe; na busca as seções ficam sempre abertas
                    onTap: _query.isEmpty ? () => _toggleSection(s.section.id) : null,
                    expanded: _query.isEmpty ? !_isCollapsed(s.section.id) : null,
                    trailing: _query.isEmpty
                        ? Tooltip(
                            message: _isCollapsed(s.section.id) ? 'Mostrar' : 'Recolher',
                            child: AnimatedRotation(
                              turns: _isCollapsed(s.section.id) ? -0.25 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(Icons.keyboard_arrow_down_rounded, size: 28, color: colors.textMuted),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              if (!_isCollapsed(s.section.id))
                SliverPadding(
                  padding: content,
                  sliver: SliverList.list(
                    children: [
                      for (final combo in s.combos)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: MenuProductCard(
                            name: combo.name,
                            description: combo.description ?? combo.itemsSummary,
                            imageUrl: combo.imageUrl,
                            price: combo.originalPrice > combo.price ? combo.originalPrice : combo.price,
                            promotionalPrice: combo.originalPrice > combo.price ? combo.price : null,
                            isCombo: true,
                            available: combo.available,
                            onTap: () => _open(context, combo: combo),
                            onAdd: canOrder && combo.available ? () => _quickAdd(context, combo: combo) : null,
                          ),
                        ),
                      for (final item in s.items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: MenuProductCard(
                            name: item.name,
                            description: item.description,
                            imageUrl: item.imageUrl,
                            price: item.price,
                            promotionalPrice: item.promotionalPrice,
                            badges: item.badges,
                            available: item.available,
                            onTap: () => _open(context, item: item),
                            onAdd: canOrder && item.available ? () => _quickAdd(context, item: item) : null,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 48)),
            StorefrontFooter.sliver(),
          ],
        );
      }),
    );
  }

  void _showAbout(BuildContext themedContext, Restaurant restaurant) {
    showModalBottomSheet(
      context: themedContext,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => _AboutSheet(restaurant: restaurant),
    );
  }
}

class _PreviewStrip extends StatelessWidget {
  final VoidCallback onClose;

  const _PreviewStrip({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      color: c.text,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.visibility_outlined, color: c.background, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pré-visualização do tema — ainda não salvo. Seus clientes veem o tema atual.',
              style: TextStyle(color: c.background, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onClose,
            style: TextButton.styleFrom(foregroundColor: c.background),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}

class _ClosedBanner extends StatelessWidget {
  final Restaurant restaurant;

  const _ClosedBanner({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    String two(int v) => v.toString().padLeft(2, '0');
    final until = restaurant.pausedUntil;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color.alphaBlend(c.danger.withValues(alpha: 0.10), c.surface),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Icon(Icons.storefront_outlined, color: c.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              until != null
                  ? 'O restaurante pausou os pedidos até ${two(until.hour)}:${two(until.minute)}. Você pode ver o cardápio.'
                  : 'Fechado no momento. Você pode ver o cardápio; confira os horários em "Sobre".',
              style: TextStyle(color: c.text),
            ),
          ),
        ],
      ),
    );
  }
}

/// Busca e chips de seção. Ao rolar, a busca desaparece e os chips ficam fixos logo abaixo da
/// barra de navegação transparente ([topInset]).
class _SearchAndTabsDelegate extends SliverPersistentHeaderDelegate {
  static const double _searchBlock = 20 + 56 + 4;

  final Widget search;

  /// Vazia = sem chips (busca ativa ou cardápio de uma seção só)
  final List<MenuSection> sections;
  final int? activeId;
  final ValueChanged<int> onSelected;
  final double horizontal;
  final Color background;
  final double topInset;

  _SearchAndTabsDelegate({
    required this.search,
    required this.sections,
    required this.activeId,
    required this.onSelected,
    required this.horizontal,
    required this.background,
    required this.topInset,
  });

  double get _tabs => sections.isEmpty ? 0 : _RestaurantPageScreenState._tabsHeight;

  @override
  double get minExtent => topInset + _tabs;

  @override
  double get maxExtent => math.max(_searchBlock + _tabs, minExtent);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final range = maxExtent - minExtent;
    final collapsed = range <= 0 ? (shrinkOffset > 0 ? 1.0 : 0.0) : (shrinkOffset / range).clamp(0.0, 1.0);

    return Material(
      color: background,
      elevation: collapsed >= 1 && sections.isNotEmpty ? 2 : 0,
      shadowColor: Colors.black26,
      child: Stack(
        children: [
          Positioned(
            top: -shrinkOffset,
            left: 0,
            right: 0,
            height: _searchBlock,
            child: IgnorePointer(
              ignoring: collapsed >= 1,
              child: Opacity(
                opacity: 1 - collapsed,
                child: Padding(padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 4), child: search),
              ),
            ),
          ),
          if (sections.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: _tabs,
              child: AppFilterChips<int?>(
                height: _tabs,
                padding: EdgeInsets.fromLTRB(horizontal, 10, horizontal, 10),
                items: [
                  for (final section in sections)
                    SelectItem(
                      value: section.id,
                      label: section.name,
                      icon: MenuSectionIcons.of(section.icon ?? MenuSectionIcons.suggest(section.name)),
                    ),
                ],
                value: activeId,
                onSelected: (id) {
                  if (id != null) onSelected(id);
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SearchAndTabsDelegate old) => true;
}

class _AboutSheet extends StatelessWidget {
  final Restaurant restaurant;

  const _AboutSheet({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final address = restaurant.address;
    final hasLocation = address?.latitude != null && address?.longitude != null;
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          AppSectionHeader(title: restaurant.name, subtitle: restaurant.description),
          if (address != null) ...[
            const AppSectionHeader(title: 'Endereço', padding: EdgeInsets.only(top: 8, bottom: 8)),
            Row(
              children: [
                Expanded(child: Text(address.fullAddress)),
                const SizedBox(width: 12),
                OpenInMapsButton(address: address, label: restaurant.name),
              ],
            ),
            if (hasLocation) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 200,
                  child: AppMap(
                    center: AppMapPoint(address.latitude!, address.longitude!),
                    zoom: 15,
                    markers: [
                      AppMapMarker(
                        point: AppMapPoint(address.latitude!, address.longitude!),
                        color: Theme.of(context).colorScheme.primary,
                        caption: restaurant.name,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
          const AppSectionHeader(title: 'Horário de funcionamento', padding: EdgeInsets.only(top: 24, bottom: 8)),
          OpeningHoursList(hours: restaurant.openingHours),
          const AppSectionHeader(title: 'Formas de pagamento na entrega', padding: EdgeInsets.only(top: 24, bottom: 8)),
          for (final method in restaurant.paymentMethods)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                  children: [Icon(method.icon, size: 20, color: muted), const SizedBox(width: 12), Text(method.label)]),
            ),
          const SizedBox(height: 24),
          if (restaurant.phoneNumber != null)
            Text('Telefone: ${restaurant.phoneNumber}', style: TextStyle(color: muted)),
          if (restaurant.cnpj != null) Text('CNPJ: ${restaurant.cnpj}', style: TextStyle(color: muted)),
        ],
      ),
    );
  }
}
