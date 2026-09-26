import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../models/courier/courier_profile.dart';
import '../../services/auth_service.dart';
import '../../services/courier_service.dart';
import '../../widgets/courier/courier_avatar.dart';
import '../../models/delivery/courier_link.dart';
import 'tabs/badge_tab.dart';
import 'tabs/earnings_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/restaurants_tab.dart';
import 'tabs/vehicles_tab.dart';
import 'tabs/work_tab.dart';

/// Painel do entregador: trabalhar (online, check-in, ofertas, entrega), ganhos, lojas (fixo e onde trabalhou),
/// veículos, perfil e placa de verificação
class CourierPanelScreen extends StatefulWidget {
  const CourierPanelScreen({super.key});

  @override
  State<CourierPanelScreen> createState() => _CourierPanelScreenState();
}

class _CourierPanelScreenState extends State<CourierPanelScreen> {
  int _tabIndex = 0;

  static const _earningsTab = 1;
  static const _storesTab = 2;
  static const _vehiclesTab = 3;
  final _earningsKey = GlobalKey<EarningsTabState>();
  final _storesKey = GlobalKey<CourierRestaurantsTabState>();

  List<AppPanelDestination> _destinations(CourierService service) => [
        const AppPanelDestination(icon: Icons.bolt_outlined, selectedIcon: Icons.bolt, label: 'Trabalhar'),
        const AppPanelDestination(icon: Icons.payments_outlined, selectedIcon: Icons.payments, label: 'Ganhos'),
        AppPanelDestination(
          icon: Icons.storefront_outlined,
          selectedIcon: Icons.storefront,
          label: 'Lojas',
          // Convites de restaurantes aguardando resposta
          badge: service.links.where((l) => l.isPending && l.requestedBy == LinkRequester.RESTAURANT).length,
        ),
        const AppPanelDestination(icon: Icons.two_wheeler_outlined, selectedIcon: Icons.two_wheeler, label: 'Veículos'),
        const AppPanelDestination(icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Perfil'),
        const AppPanelDestination(icon: Icons.qr_code_2_outlined, selectedIcon: Icons.qr_code_2, label: 'Placa'),
      ];

  @override
  void initState() {
    super.initState();
    // Descarta dados de uma sessão anterior (outro entregador) antes de carregar
    final service = context.read<CourierService>()..clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => service.load());
  }

  Future<void> _logout() async {
    final courierService = context.read<CourierService>();
    await context.read<AuthService>().logout();
    courierService.clear();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<CourierService>();
    final profile = service.profile;

    if (profile == null) {
      return Scaffold(
        appBar: _buildAppBar(null),
        body: service.isLoading || service.error == null
            ? const Center(child: CircularProgressIndicator())
            : AppEmptyState(
                icon: Icons.cloud_off_outlined,
                message: service.error!,
                actionLabel: 'Tentar novamente',
                onAction: service.load,
              ),
      );
    }

    return AppPanelScaffold(
      appBar: _buildAppBar(profile),
      destinations: _destinations(service),
      selectedIndex: _tabIndex,
      onDestinationSelected: (index) {
        // Ganhos e histórico mudam a cada entrega: recarrega ao abrir
        if (index == _earningsTab) _earningsKey.currentState?.refresh();
        if (index == _storesTab) _storesKey.currentState?.refresh();
        setState(() => _tabIndex = index);
      },
      body: IndexedStack(
        index: _tabIndex,
        children: [
          WorkTab(onOpenVehicles: () => setState(() => _tabIndex = _vehiclesTab)),
          EarningsTab(key: _earningsKey),
          CourierRestaurantsTab(key: _storesKey),
          const VehiclesTab(),
          const CourierProfileTab(),
          const BadgeTab(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(CourierProfile? profile) {
    return AppBar(
      titleSpacing: 16,
      title: Row(
        children: [
          if (profile != null) ...[
            CourierAvatar(photoUrl: profile.photoUrl, name: profile.fullName, size: 36),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.fullName ?? 'Painel do entregador',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (profile?.association != null)
                  Text(profile!.association!.name, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(tooltip: 'Sair', icon: const Icon(Icons.logout), onPressed: _logout),
        const SizedBox(width: 8),
      ],
    );
  }
}
