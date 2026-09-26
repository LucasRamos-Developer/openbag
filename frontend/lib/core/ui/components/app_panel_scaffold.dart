import 'package:flutter/material.dart';

/// Destino de navegação de um painel (aba)
class AppPanelDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// Contador exibido sobre o ícone (0 = sem badge)
  final int badge;

  const AppPanelDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badge = 0,
  });
}

/// Scaffold de painel administrativo com navegação responsiva:
/// NavigationRail lateral em telas largas e NavigationBar inferior no celular.
///
/// ```dart
/// AppPanelScaffold(
///   appBar: AppBar(title: Text('Painel')),
///   destinations: const [
///     AppPanelDestination(icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: 'Visão geral'),
///   ],
///   selectedIndex: _tab,
///   onDestinationSelected: (i) => setState(() => _tab = i),
///   body: IndexedStack(index: _tab, children: [...]),
/// )
/// ```
class AppPanelScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final List<AppPanelDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;

  /// A partir desta largura a navegação vai para a lateral
  final double wideBreakpoint;

  const AppPanelScaffold({
    super.key,
    this.appBar,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.wideBreakpoint = 800,
  });

  Widget _icon(IconData icon, int badge) {
    if (badge <= 0) return Icon(icon);
    return Badge(label: Text('$badge'), child: Icon(icon));
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= wideBreakpoint;

    return Scaffold(
      appBar: appBar,
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(
                        icon: _icon(d.icon, d.badge),
                        selectedIcon: _icon(d.selectedIcon, d.badge),
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: [
                for (final d in destinations)
                  NavigationDestination(
                    icon: _icon(d.icon, d.badge),
                    selectedIcon: _icon(d.selectedIcon, d.badge),
                    label: d.label,
                  ),
              ],
            ),
    );
  }
}
