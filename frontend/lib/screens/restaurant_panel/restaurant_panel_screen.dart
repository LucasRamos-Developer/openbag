import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../models/panel_profile.dart';
import '../../services/auth_service.dart';
import '../../services/restaurant_delivery_service.dart';
import '../../services/restaurant_orders_service.dart';
import '../../services/restaurant_panel_service.dart';
import '../../widgets/navigation/panel_profiles.dart';
import '../../widgets/navigation/panel_routes.dart';
import '../../widgets/restaurant/restaurant_logo.dart';
import '../../widgets/restaurant/store_status_menu_tile.dart';
import 'restaurant_section.dart';
import 'tabs/cash_tab.dart';
import 'tabs/couriers_tab.dart';
import 'tabs/menu_tab.dart';
import 'tabs/orders_tab.dart';
import 'tabs/reviews_tab.dart';
import 'tabs/routes_tab.dart';
import 'tabs/store_tab.dart';

/// Painel do dono do restaurante: pedidos, cardápio, entregadores, avaliações e loja.
/// A seção vem do endereço (`/restaurante/<secao>[/<aba>]`).
class RestaurantPanelScreen extends StatefulWidget {
  final RestaurantSection section;
  final StoreSection storeSection;

  const RestaurantPanelScreen({
    super.key,
    this.section = RestaurantSection.orders,
    this.storeSection = StoreSection.general,
  });

  @override
  State<RestaurantPanelScreen> createState() => _RestaurantPanelScreenState();
}

class _RestaurantPanelScreenState extends State<RestaurantPanelScreen> {
  List<AppPanelDestination> _destinations(int newOrders) => [
        for (final section in RestaurantSection.values)
          section.destination(badge: section == RestaurantSection.orders ? newOrders : 0),
      ];

  @override
  void initState() {
    super.initState();
    // Descarta dados de uma sessão anterior (outro dono) antes de carregar
    final service = context.read<RestaurantPanelService>()..clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => service.load());
  }

  // Recriada ao trocar de restaurante; recarrega o caixa ao entrar na seção
  GlobalKey<CashTabState> _cashKey = GlobalKey();
  int? _cashRestaurantId;

  @override
  void didUpdateWidget(RestaurantPanelScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.section == RestaurantSection.cash && oldWidget.section != widget.section) {
      _cashKey.currentState?.refresh();
    }
    // A taxa de entrega pode ter mudado na Loja
    final selectedId = context.read<RestaurantPanelService>().selectedId;
    if (widget.section == RestaurantSection.couriers && oldWidget.section != widget.section && selectedId != null) {
      context.read<RestaurantDeliveryService>().load(selectedId);
    }
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
    final store = service.store;
    if (_cashRestaurantId != service.selectedId) {
      _cashRestaurantId = service.selectedId;
      _cashKey = GlobalKey();
    }

    if (store == null || service.menu == null) {
      return AppPanelScaffold(
        header: _buildHeader(service),
        title: 'Meu restaurante',
        onDestinationSelected: (_) {},
        onLogout: _logout,
        body: _buildLoadingOrEmpty(service),
      );
    }

    return AppPanelScaffold(
      header: _buildHeader(service),
      status: StoreStatusMenuTile(store: store),
      destinations: _destinations(context.watch<RestaurantOrdersService>().pending.length),
      selectedIndex: widget.section.index,
      onDestinationSelected: (index) => context.go(RestaurantSection.values[index].path),
      onLogout: _logout,
      body: IndexedStack(
        index: widget.section.index,
        // A chave recria a aba de pedidos ao trocar de restaurante
        children: [
          OrdersTab(key: ValueKey(service.selectedId)),
          RoutesTab(key: ValueKey('routes-${service.selectedId}')),
          const MenuTab(),
          CouriersTab(key: ValueKey('couriers-${service.selectedId}')),
          CashTab(key: _cashKey),
          const ReviewsTab(),
          StoreTab(section: widget.storeSection),
        ],
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

  Widget _buildHeader(RestaurantPanelService service) {
    final name = service.store?.name ?? 'Meu restaurante';

    return AppPanelProfileHeader(
      avatar: RestaurantLogo(logoUrl: service.store?.logoUrl, name: name, size: 40),
      title: name,
      subtitle: PanelProfile.restaurant.label,
      sections: [
        AppPanelProfileSection(
          title: 'Seus restaurantes',
          options: service.restaurants.length < 2
              ? const []
              : [
                  for (final r in service.restaurants)
                    AppPanelProfileOption(
                      icon: Icons.storefront_outlined,
                      label: r.name,
                      selected: r.id == service.selectedId,
                      onTap: () => service.selectRestaurant(r.id),
                    ),
                ],
        ),
        panelProfilesSection(context, current: PanelProfile.restaurant),
      ],
    );
  }
}
