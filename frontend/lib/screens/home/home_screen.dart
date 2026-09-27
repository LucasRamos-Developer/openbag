import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../services/restaurant_service.dart';
import '../../widgets/cart/cart_bar.dart';
import '../../widgets/navigation/storefront_scaffold.dart';
import '../../widgets/restaurant_card.dart';

/// Vitrine: restaurantes em grade (até 4 por linha)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RestaurantService>().fetchRestaurants();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<RestaurantService>();

    return StorefrontScaffold(
      current: StorefrontLink.restaurants,
      bottomNavigationBar: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
          child: const CartBar(),
        ),
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final padding = AppLayout.contentPadding(
          constraints.maxWidth,
          top: StorefrontScaffold.topInset(context) + 28,
          bottom: 40,
        );

        return RefreshIndicator(
          onRefresh: service.fetchRestaurants,
          child: ListView(
            padding: padding,
            children: [
              AppSectionHeader(
                title: 'Restaurantes',
                subtitle: service.isLoading || service.restaurants.isEmpty
                    ? 'Peça dos restaurantes da sua cidade'
                    : '${service.restaurants.length} ${service.restaurants.length == 1 ? 'loja' : 'lojas'} na sua região',
                leadingIcon: Icons.storefront_outlined,
              ),
              _buildContent(context, service),
            ],
          ),
        );
      }),
    );
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

    return AppResponsiveGrid(
      children: [
        for (final restaurant in service.restaurants)
          RestaurantCard(restaurant: restaurant, onTap: () => context.push('/r/${restaurant.slug}')),
      ],
    );
  }
}
