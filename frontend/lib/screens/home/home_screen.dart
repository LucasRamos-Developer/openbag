import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../models/restaurant.dart';
import '../../services/customer_location_service.dart';
import '../../services/restaurant_service.dart';
import '../../utils/search.dart';
import '../../widgets/cart/cart_bar.dart';
import '../../widgets/navigation/storefront_footer.dart';
import '../../widgets/navigation/storefront_scaffold.dart';
import '../../widgets/restaurant/restaurant_sort.dart';
import '../../widgets/restaurant_card.dart';

/// Vitrine: restaurantes em grade (até 4 por linha), com busca e ordenação
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  String _query = '';
  RestaurantSort _sort = RestaurantSort.recommended;

  /// "Mais perto" só aparece se der para localizar o cliente (GPS ou último endereço)
  bool _nearestAvailable = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Lojas da busca, na ordem escolhida. A busca olha nome, categorias, bairro e cidade
  List<Restaurant> _visible(List<Restaurant> all) => _sort.apply([
        for (final r in all)
          if (matchesSearch(_query, [r.name, ...r.categories, r.address?.neighborhood, r.address?.city])) r,
      ], origin: context.read<CustomerLocationService>().origin);

  Future<void> _changeSort(RestaurantSort sort) async {
    if (sort != RestaurantSort.nearest) {
      setState(() => _sort = sort);
      return;
    }
    final location = context.read<CustomerLocationService>();
    if (await location.locate()) {
      if (mounted) setState(() => _sort = sort);
    } else if (mounted) {
      AppToast.show(context,
          message: 'Não conseguimos sua localização. Libere o acesso no navegador ou faça um pedido para usarmos o endereço.',
          type: ToastType.warning,
          duration: const Duration(seconds: 6));
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<RestaurantService>().fetchRestaurants();
      final available = await context.read<CustomerLocationService>().isAvailable();
      if (mounted) setState(() => _nearestAvailable = available);
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<RestaurantService>();
    context.watch<CustomerLocationService>();

    return StorefrontScaffold(
      current: StorefrontLink.restaurants,
      bottomNavigationBar: const CartBar(),
      body: LayoutBuilder(builder: (context, constraints) {
        final padding = AppLayout.contentPadding(
          constraints.maxWidth,
          top: StorefrontScaffold.topInset(context) + 28,
          bottom: 48,
        );

        return RefreshIndicator(
          onRefresh: service.fetchRestaurants,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: padding,
                sliver: SliverList.list(
                  children: [
                    AppSectionTitle(
                      title: 'Restaurantes',
                      trailing: service.restaurants.isEmpty
                          ? null
                          : Text('${service.restaurants.length} ${service.restaurants.length == 1 ? 'loja' : 'lojas'}'),
                    ),
                    _buildToolbar(constraints.maxWidth < AppLayout.compactWidth),
                    const SizedBox(height: 24),
                    _buildContent(context, service),
                  ],
                ),
              ),
              StorefrontFooter.sliver(),
            ],
          ),
        );
      }),
    );
  }

  /// Busca e ordenação: lado a lado no desktop, uma embaixo da outra no celular
  Widget _buildToolbar(bool compact) {
    final search = AppSearchBar(
      controller: _search,
      hintText: 'Buscar por nome, categoria ou bairro',
      onChanged: (value) => setState(() => _query = value.trim()),
    );
    final sort = AppPillSelect<RestaurantSort>(
      tooltip: 'Ordenar por',
      icon: Icons.swap_vert_rounded,
      items: [
        for (final option in RestaurantSort.values)
          if (option != RestaurantSort.nearest || _nearestAvailable) SelectItem(value: option, label: option.label),
      ],
      value: _sort,
      onChanged: _changeSort,
    );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [search, const SizedBox(height: 12), sort],
      );
    }
    return Row(children: [Expanded(child: search), const SizedBox(width: 12), sort]);
  }

  Widget _buildContent(BuildContext context, RestaurantService service) {
    if (service.isLoading && service.restaurants.isEmpty) {
      return AppSkeleton.group(
        child: AppResponsiveGrid(children: List.generate(8, (_) => const RestaurantCardSkeleton())),
      );
    }
    if (service.error != null && service.restaurants.isEmpty) {
      return AppEmptyState(
        icon: Icons.cloud_off_outlined,
        message: service.error!,
        actionLabel: 'Tentar novamente',
        onAction: service.fetchRestaurants,
      );
    }
    if (service.restaurants.isEmpty) {
      return const AppEmptyState(icon: Icons.storefront_outlined, message: 'Nenhum restaurante disponível por aqui ainda.');
    }

    final visible = _visible(service.restaurants);
    if (visible.isEmpty) {
      return AppEmptyState(
        icon: Icons.search_off_rounded,
        message: 'Nenhuma loja encontrada para "$_query".',
        actionLabel: 'Limpar busca',
        onAction: () => setState(() {
          _search.clear();
          _query = '';
        }),
      );
    }

    final location = context.read<CustomerLocationService>();
    final grid = AppResponsiveGrid(
      children: [
        for (final restaurant in visible)
          RestaurantCard(
            restaurant: restaurant,
            distanceKm: RestaurantSort.distanceKm(restaurant, location.origin),
            onTap: () => context.push('/r/${restaurant.slug}'),
          ),
      ],
    );
    if (_sort != RestaurantSort.nearest || location.source == null) return grid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Icon(Icons.near_me_outlined, size: 16, color: context.appColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Distâncias a partir de ${location.source!.label}, em linha reta',
                    style: TextStyle(color: context.appColors.textMuted, fontSize: 13)),
              ),
            ],
          ),
        ),
        grid,
      ],
    );
  }
}
