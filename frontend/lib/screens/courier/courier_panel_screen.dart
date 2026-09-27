import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../models/courier/courier_profile.dart';
import '../../models/panel_profile.dart';
import '../../services/auth_service.dart';
import '../../services/courier_service.dart';
import '../../widgets/courier/courier_avatar.dart';
import '../../widgets/navigation/panel_profiles.dart';
import '../../widgets/navigation/panel_routes.dart';
import '../../models/delivery/courier_link.dart';
import 'courier_section.dart';
import 'tabs/badge_tab.dart';
import 'tabs/earnings_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/restaurants_tab.dart';
import 'tabs/vehicles_tab.dart';
import 'tabs/work_tab.dart';

/// Painel do entregador: trabalhar (online, check-in, ofertas, entrega), ganhos, lojas (fixo e onde trabalhou),
/// veículos, perfil e placa de verificação
class CourierPanelScreen extends StatefulWidget {
  final CourierSection section;

  const CourierPanelScreen({super.key, this.section = CourierSection.work});

  @override
  State<CourierPanelScreen> createState() => _CourierPanelScreenState();
}

class _CourierPanelScreenState extends State<CourierPanelScreen> {
  final _earningsKey = GlobalKey<EarningsTabState>();
  final _storesKey = GlobalKey<CourierRestaurantsTabState>();

  List<AppPanelDestination> _destinations(CourierService service) => [
        for (final section in CourierSection.values)
          section.destination(
            // Convites de restaurantes aguardando resposta
            badge: section == CourierSection.stores
                ? service.links.where((l) => l.isPending && l.requestedBy == LinkRequester.RESTAURANT).length
                : 0,
          ),
      ];

  @override
  void initState() {
    super.initState();
    // Descarta dados de uma sessão anterior (outro entregador) antes de carregar
    final service = context.read<CourierService>()..clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => service.load());
  }

  @override
  void didUpdateWidget(CourierPanelScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.section == oldWidget.section) return;
    // Ganhos e histórico mudam a cada entrega: recarrega ao abrir
    if (widget.section == CourierSection.earnings) _earningsKey.currentState?.refresh();
    if (widget.section == CourierSection.stores) _storesKey.currentState?.refresh();
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
      return AppPanelScaffold(
        header: _buildHeader(null),
        title: 'Painel do entregador',
        onDestinationSelected: (_) {},
        onLogout: _logout,
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
      header: _buildHeader(profile),
      onLogout: _logout,
      destinations: _destinations(service),
      selectedIndex: widget.section.index,
      onDestinationSelected: (index) => context.go(CourierSection.values[index].path),
      body: IndexedStack(
        index: widget.section.index,
        children: [
          WorkTab(onOpenVehicles: () => context.go(CourierSection.vehicles.path)),
          EarningsTab(key: _earningsKey),
          CourierRestaurantsTab(key: _storesKey),
          const VehiclesTab(),
          const CourierProfileTab(),
          const BadgeTab(),
        ],
      ),
    );
  }

  Widget _buildHeader(CourierProfile? profile) {
    final name = profile?.fullName ?? 'Painel do entregador';
    final association = profile?.association?.name;

    return AppPanelProfileHeader(
      avatar: CourierAvatar(photoUrl: profile?.photoUrl, name: name, size: 40),
      title: name,
      subtitle: association != null ? '${PanelProfile.courier.label} · $association' : PanelProfile.courier.label,
      sections: [panelProfilesSection(context, current: PanelProfile.courier)],
    );
  }
}
