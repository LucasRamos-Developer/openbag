import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../services/auth_service.dart';
import '../../services/restaurant_orders_service.dart';
import '../../services/restaurant_panel_service.dart';
import '../../widgets/restaurant/store_status_chip.dart';
import 'tabs/menu_tab.dart';
import 'tabs/orders_tab.dart';
import 'tabs/store_tab.dart';

/// Painel do dono do restaurante: cardápio e operação da loja
class RestaurantPanelScreen extends StatefulWidget {
  const RestaurantPanelScreen({super.key});

  @override
  State<RestaurantPanelScreen> createState() => _RestaurantPanelScreenState();
}

class _RestaurantPanelScreenState extends State<RestaurantPanelScreen> {
  int _tabIndex = 0;

  List<AppPanelDestination> _destinations(int newOrders) => [
        AppPanelDestination(
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
          label: 'Pedidos',
          badge: newOrders,
        ),
        const AppPanelDestination(icon: Icons.restaurant_menu_outlined, selectedIcon: Icons.restaurant_menu, label: 'Cardápio'),
        const AppPanelDestination(icon: Icons.storefront_outlined, selectedIcon: Icons.storefront, label: 'Loja'),
      ];

  @override
  void initState() {
    super.initState();
    // Descarta dados de uma sessão anterior (outro dono) antes de carregar
    final service = context.read<RestaurantPanelService>()..clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => service.load());
  }

  Future<void> _logout() async {
    final panel = context.read<RestaurantPanelService>();
    await context.read<AuthService>().logout();
    panel.clear();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<RestaurantPanelService>();

    if (service.store == null || service.menu == null) {
      return Scaffold(
        appBar: _buildAppBar(service),
        body: _buildLoadingOrEmpty(service),
      );
    }

    return AppPanelScaffold(
      appBar: _buildAppBar(service),
      destinations: _destinations(context.watch<RestaurantOrdersService>().pending.length),
      selectedIndex: _tabIndex,
      onDestinationSelected: (index) => setState(() => _tabIndex = index),
      body: IndexedStack(
        index: _tabIndex,
        // A chave recria a aba de pedidos ao trocar de restaurante
        children: [OrdersTab(key: ValueKey(service.selectedId)), const MenuTab(), const StoreTab()],
      ),
    );
  }

  Widget _buildLoadingOrEmpty(RestaurantPanelService service) {
    if (service.isLoading || (service.error == null && service.restaurants.isNotEmpty)) {
      return const Center(child: CircularProgressIndicator());
    }
    if (service.error != null) {
      return AppEmptyState(
        icon: Icons.cloud_off_outlined,
        message: service.error!,
        actionLabel: 'Tentar novamente',
        onAction: service.load,
      );
    }
    return AppEmptyState(
      icon: Icons.storefront_outlined,
      message: 'Nenhum restaurante vinculado à sua conta.',
      actionLabel: 'Cadastrar restaurante',
      onAction: () => context.go('/registrar/restaurante'),
    );
  }

  PreferredSizeWidget _buildAppBar(RestaurantPanelService service) {
    final store = service.store;
    final hasSeveral = service.restaurants.length > 1;

    return AppBar(
      titleSpacing: 16,
      title: Row(
        children: [
          Flexible(
            child: hasSeveral
                ? PopupMenuButton<int>(
                    tooltip: 'Trocar de restaurante',
                    onSelected: service.selectRestaurant,
                    itemBuilder: (_) => [
                      for (final r in service.restaurants)
                        CheckedPopupMenuItem(value: r.id, checked: r.id == service.selectedId, child: Text(r.name)),
                    ],
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(child: _title(store?.name ?? 'Meu restaurante')),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  )
                : _title(store?.name ?? 'Meu restaurante'),
          ),
          if (store != null) ...[
            const SizedBox(width: 12),
            StoreStatusChip(store: store),
          ],
        ],
      ),
      actions: [
        IconButton(tooltip: 'Sair', icon: const Icon(Icons.logout), onPressed: _logout),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _title(String text) =>
      Text(text, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600));
}
