import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../models/admin/admin_rows.dart';
import '../../models/panel_profile.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/navigation/panel_profiles.dart';
import '../../widgets/navigation/panel_routes.dart';
import 'admin_section.dart';
import 'tabs/associations_tab.dart';
import 'tabs/couriers_tab.dart';
import 'tabs/orders_tab.dart';
import 'tabs/overview_tab.dart';
import 'tabs/restaurants_tab.dart';
import 'tabs/users_tab.dart';

/// Painel do super admin: visão geral e listas de toda a plataforma (somente leitura),
/// mais a moderação de associações
class AdminPanelScreen extends StatefulWidget {
  final AdminSection section;

  const AdminPanelScreen({super.key, this.section = AdminSection.overview});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  late final AdminService _service;
  AdminOverview? _overview;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = AdminService(context.read<AuthService>().apiClient);
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    try {
      final overview = await _service.overview();
      if (mounted) {
        setState(() {
          _overview = overview;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _logout() async {
    await context.read<AuthService>().logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    return AppPanelScaffold(
      header: AppPanelProfileHeader(
        avatar: AppImageAvatar(url: null, name: user?.fullName ?? 'Admin', size: 40),
        title: user?.fullName ?? 'Administração',
        subtitle: PanelProfile.admin.label,
        sections: [panelProfilesSection(context, current: PanelProfile.admin)],
      ),
      destinations: [
        for (final section in AdminSection.values)
          section.destination(
            badge: section == AdminSection.associations ? _overview?.associationsPending ?? 0 : 0,
          ),
      ],
      selectedIndex: widget.section.index,
      onDestinationSelected: (index) => context.go(AdminSection.values[index].path),
      onLogout: _logout,
      body: IndexedStack(
        index: widget.section.index,
        children: [
          OverviewTab(
            overview: _overview,
            error: _error,
            onRefresh: _loadOverview,
            onOpen: (section) => context.go(section.path),
          ),
          RestaurantsTab(service: _service),
          AssociationsTab(onChanged: _loadOverview),
          CouriersTab(service: _service),
          UsersTab(service: _service),
          OrdersTab(service: _service),
        ],
      ),
    );
  }
}
