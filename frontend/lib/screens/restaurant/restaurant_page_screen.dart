import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../core/ui/ui.dart';
import '../../models/menu/menu.dart';
import '../../models/restaurant.dart';
import '../../services/api_client.dart';
import '../../services/cart_service.dart';
import '../../services/restaurant_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/cart/cart_bar.dart';
import '../../widgets/map_widget.dart';
import '../../widgets/menu/item_detail_sheet.dart';
import '../../widgets/menu/menu_item_tile.dart';
import '../../widgets/restaurant/opening_hours_list.dart';
import '../../widgets/restaurant/restaurant_logo.dart';

/// Página pública do restaurante: dados, cardápio por seção e carrinho
class RestaurantPageScreen extends StatefulWidget {
  final String slug;

  const RestaurantPageScreen({super.key, required this.slug});

  @override
  State<RestaurantPageScreen> createState() => _RestaurantPageScreenState();
}

class _RestaurantPageScreenState extends State<RestaurantPageScreen> {
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

  // ============= Seções: acompanha a rolagem e rola até a seção =============

  void _updateActiveSection() {
    int? active;
    for (final entry in _sectionKeys.entries) {
      final box = entry.value.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      if (box.localToGlobal(Offset.zero).dy <= 170) active = entry.key;
    }
    if (active != null && active != _activeSectionId) setState(() => _activeSectionId = active);
  }

  void _scrollToSection(int sectionId) {
    final context = _sectionKeys[sectionId]?.currentContext;
    if (context == null) return;
    setState(() => _activeSectionId = sectionId);
    Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut, alignment: 0.05);
  }

  // ============= Carrinho =============

  CartRestaurant get _cartRestaurant => CartRestaurant(
        id: _restaurant!.id,
        slug: _restaurant!.slug,
        name: _restaurant!.name,
        logoUrl: _restaurant!.logoUrl,
        deliveryFee: _restaurant!.deliveryFee,
        minimumOrder: _restaurant!.minimumOrder,
      );

  Future<void> _open({MenuItem? item, Combo? combo}) async {
    final line = await showItemDetailSheet(context, item: item, combo: combo, canOrder: _restaurant!.openNow);
    if (line == null || !mounted) return;

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

  // ============= Build =============

  bool _matches(String text) => text.toLowerCase().contains(_query.toLowerCase());

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: AppEmptyState(icon: Icons.storefront_outlined, message: _error!, actionLabel: 'Tentar novamente', onAction: _load),
      );
    }
    if (_restaurant == null || _menu == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final restaurant = _restaurant!;
    final sections = _menu!.sections
        .map((s) => (
              section: s,
              items: s.items.where((i) => _query.isEmpty || _matches(i.name) || _matches(i.description ?? '')).toList(),
              combos: s.combos.where((c) => _query.isEmpty || _matches(c.name) || _matches(c.itemsSummary)).toList(),
            ))
        .where((s) => s.items.isNotEmpty || s.combos.isNotEmpty)
        .toList();

    return Scaffold(
      bottomNavigationBar: CartBar(restaurantId: restaurant.id),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildAppBar(restaurant),
              SliverToBoxAdapter(child: _Header(restaurant: restaurant, onAbout: () => _showAbout(restaurant))),
              if (!restaurant.openNow) SliverToBoxAdapter(child: _ClosedBanner(restaurant: restaurant)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: AppTextField(
                    controller: _searchController,
                    hintText: 'Buscar no cardápio',
                    prefixIcon: const Icon(Icons.search),
                    variant: TextFieldVariant.filled,
                    size: TextFieldSize.small,
                    onChanged: (v) => setState(() => _query = v.trim()),
                  ),
                ),
              ),
              if (_query.isEmpty && _menu!.sections.length > 1)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SectionTabsDelegate(
                    sections: _menu!.sections,
                    activeId: _activeSectionId,
                    onSelected: _scrollToSection,
                  ),
                ),
              if (sections.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    icon: Icons.restaurant_menu_outlined,
                    message: _query.isEmpty ? 'O cardápio ainda está sendo preparado.' : 'Nada encontrado para "$_query".',
                  ),
                ),
              for (final s in sections) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    key: _query.isEmpty ? _sectionKeys[s.section.id] : null,
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
                    child: AppSectionHeader(title: s.section.name, subtitle: s.section.description, padding: EdgeInsets.zero),
                  ),
                ),
                SliverList.list(
                  children: [
                    for (final combo in s.combos)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: MenuItemTile(
                          name: combo.name,
                          description: combo.description,
                          subtitle: combo.itemsSummary,
                          price: combo.originalPrice > combo.price ? combo.originalPrice : combo.price,
                          promotionalPrice: combo.originalPrice > combo.price ? combo.price : null,
                          imageUrl: combo.imageUrl,
                          onTap: () => _open(combo: combo),
                        ),
                      ),
                    for (final item in s.items)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: MenuItemTile(
                          name: item.name,
                          description: item.description,
                          price: item.price,
                          promotionalPrice: item.promotionalPrice,
                          imageUrl: item.imageUrl,
                          onTap: () => _open(item: item),
                        ),
                      ),
                  ],
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(Restaurant restaurant) {
    final colorScheme = Theme.of(context).colorScheme;
    final brand = _parseColor(restaurant.primaryColor) ?? colorScheme.primary;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 180,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Voltar',
        onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
      title: Text(restaurant.name),
      flexibleSpace: FlexibleSpaceBar(
        background: restaurant.bannerUrl != null
            ? Image.network(AppConstants.fileUrl(restaurant.bannerUrl!), fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _BrandGradient(color: brand))
            : _BrandGradient(color: brand),
      ),
    );
  }

  static Color? _parseColor(String? hex) {
    if (hex == null || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex)) return null;
    return Color(int.parse('FF${hex.substring(1)}', radix: 16));
  }

  void _showAbout(Restaurant restaurant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => _AboutSheet(restaurant: restaurant),
    );
  }
}

class _BrandGradient extends StatelessWidget {
  final Color color;

  const _BrandGradient({required this.color});

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withValues(alpha: 0.6)],
          ),
        ),
      );
}

class _Header extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onAbout;

  const _Header({required this.restaurant, required this.onAbout});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    final tags = [...restaurant.categories, if (restaurant.priceRange != null) restaurant.priceRange!];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RestaurantLogo(logoUrl: restaurant.logoUrl, name: restaurant.name, size: 64),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(restaurant.name, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    if (tags.isNotEmpty) Text(tags.join(' · '), style: TextStyle(color: muted)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 18, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text(
                          restaurant.totalReviews > 0
                              ? '${restaurant.formattedRating} (${restaurant.totalReviews} avaliações)'
                              : 'Novo no OpenBag',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppStatusChip(
                label: restaurant.openNow ? 'Aberto agora' : (restaurant.paused ? 'Pausado' : 'Fechado'),
                color: restaurant.openNow ? AppColors.successDark : AppColors.errorDark,
              ),
              _Info(icon: Icons.schedule, text: restaurant.deliveryTimeRange),
              _Info(
                icon: Icons.delivery_dining_outlined,
                text: restaurant.deliveryFee > 0 ? 'Entrega ${formatMoney(restaurant.deliveryFee)}' : 'Entrega grátis',
              ),
              if (restaurant.minimumOrder > 0) _Info(icon: Icons.shopping_bag_outlined, text: 'Mínimo ${formatMoney(restaurant.minimumOrder)}'),
              AppButton(
                text: 'Sobre',
                icon: Icons.info_outline,
                variant: ButtonVariant.text,
                size: ButtonSize.small,
                onPressed: onAbout,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Info({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 18, color: muted), const SizedBox(width: 4), Text(text, style: TextStyle(color: muted))],
    );
  }
}

class _ClosedBanner extends StatelessWidget {
  final Restaurant restaurant;

  const _ClosedBanner({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    String two(int v) => v.toString().padLeft(2, '0');
    final until = restaurant.pausedUntil;
    return AppCard(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      backgroundColor: AppColors.errorLighter.withValues(alpha: 0.4),
      child: Row(
        children: [
          const Icon(Icons.storefront_outlined, color: AppColors.errorDark),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              until != null
                  ? 'O restaurante pausou os pedidos até ${two(until.hour)}:${two(until.minute)}. Você pode ver o cardápio.'
                  : 'Fechado no momento. Você pode ver o cardápio; confira os horários em "Sobre".',
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTabsDelegate extends SliverPersistentHeaderDelegate {
  final List<MenuSection> sections;
  final int? activeId;
  final ValueChanged<int> onSelected;

  _SectionTabsDelegate({required this.sections, required this.activeId, required this.onSelected});

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: overlapsContent ? 2 : 0,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => ChoiceChip(
          label: Text(sections[i].name),
          selected: sections[i].id == activeId,
          onSelected: (_) => onSelected(sections[i].id),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SectionTabsDelegate old) => old.activeId != activeId || old.sections != sections;
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
            Text(address.fullAddress),
            if (hasLocation) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 200,
                  child: MapWidget(
                    initialLocation: LatLng(address.latitude!, address.longitude!),
                    zoom: 15,
                    showCurrentLocation: false,
                    markers: [MapMarker(position: LatLng(address.latitude!, address.longitude!), title: restaurant.name)],
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
              child: Row(children: [Icon(method.icon, size: 20, color: muted), const SizedBox(width: 12), Text(method.label)]),
            ),
          const SizedBox(height: 24),
          if (restaurant.phoneNumber != null) Text('Telefone: ${restaurant.phoneNumber}', style: TextStyle(color: muted)),
          if (restaurant.cnpj != null) Text('CNPJ: ${restaurant.cnpj}', style: TextStyle(color: muted)),
        ],
      ),
    );
  }
}
