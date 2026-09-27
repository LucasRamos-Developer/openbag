import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme_colors.dart';

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

/// Scaffold dos painéis de gestão com menu lateral flutuante (padrão do app fieng)
///
/// - Telas largas: painel arredondado sobre o conteúdo, recolhido (só ícones) ou expandido (ícone + rótulo).
///   O estado fica salvo entre as sessões.
/// - Celular: o mesmo menu vira gaveta, aberta pelo ☰ de uma barra mínima.
///
/// ```dart
/// AppPanelScaffold(
///   header: AppPanelProfileHeader(avatar: ..., title: 'Burger da Vila', subtitle: 'Restaurante', sections: [...]),
///   status: AppPanelStatus(color: Colors.green, label: 'Aberta', detail: 'Recebendo pedidos'),
///   destinations: const [
///     AppPanelDestination(icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: 'Visão geral'),
///   ],
///   selectedIndex: _tab,
///   onDestinationSelected: (i) => setState(() => _tab = i),
///   onLogout: _logout,
///   body: IndexedStack(index: _tab, children: [...]),
/// )
/// ```
class AppPanelScaffold extends StatefulWidget {
  /// Bloco do topo do menu, normalmente um [AppPanelProfileHeader]
  final Widget? header;
  final List<AppPanelDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;

  /// Situação exibida logo abaixo do cabeçalho do menu, normalmente um [AppPanelStatus]
  final Widget? status;

  /// Título da barra do celular quando não há destino selecionado
  final String? title;

  /// Item "Sair" no rodapé do menu
  final VoidCallback? onLogout;

  /// A partir desta largura o menu fica fixo na lateral; abaixo, vira gaveta
  final double wideBreakpoint;

  const AppPanelScaffold({
    super.key,
    this.header,
    this.destinations = const [],
    this.selectedIndex = 0,
    required this.onDestinationSelected,
    required this.body,
    this.status,
    this.title,
    this.onLogout,
    this.wideBreakpoint = 800,
  });

  static const _prefsKey = 'panel_menu_expanded';

  @override
  State<AppPanelScaffold> createState() => _AppPanelScaffoldState();
}

class _AppPanelScaffoldState extends State<AppPanelScaffold> {
  static const _outerPadding = EdgeInsets.fromLTRB(12, 12, 10, 12);
  static const _collapsedWidth = 84.0;
  static const _expandedWidth = 256.0;
  static const _reservedWidth = 12 + _collapsedWidth + 10;

  bool _expanded = false;

  /// Rótulos só aparecem depois que o painel termina de abrir (evita overflow na animação)
  bool _showLabels = false;

  @override
  void initState() {
    super.initState();
    _restoreExpanded();
  }

  Future<void> _restoreExpanded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expanded = prefs.getBool(AppPanelScaffold._prefsKey) ?? false;
      if (mounted && expanded) setState(() => _expanded = _showLabels = true);
    } catch (_) {
      // Sem armazenamento disponível: começa recolhido
    }
  }

  Future<void> _toggleExpanded() async {
    setState(() {
      _expanded = !_expanded;
      if (!_expanded) _showLabels = false;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppPanelScaffold._prefsKey, _expanded);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          constraints.maxWidth >= widget.wideBreakpoint ? _buildWide(context) : _buildNarrow(context),
    );
  }

  Widget _buildWide(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: _reservedWidth),
            child: widget.body,
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            child: Padding(
              padding: _outerPadding,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: _expanded ? _expandedWidth : _collapsedWidth,
                onEnd: () {
                  if (_expanded && !_showLabels) setState(() => _showLabels = true);
                },
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(
                      color: colors.text.withValues(alpha: colors.isDark ? 0.3 : 0.10),
                      blurRadius: 20,
                      offset: const Offset(6, 0),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: _AppPanelMenuScope(
                  expanded: _showLabels,
                  child: _PanelMenu(
                    header: widget.header,
                    status: widget.status,
                    destinations: widget.destinations,
                    selectedIndex: widget.selectedIndex,
                    onDestinationSelected: widget.onDestinationSelected,
                    onLogout: widget.onLogout,
                    onToggle: _toggleExpanded,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrow(BuildContext context) {
    final colors = context.appColors;
    final hasSelection = widget.selectedIndex >= 0 && widget.selectedIndex < widget.destinations.length;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          hasSelection ? widget.destinations[widget.selectedIndex].label : (widget.title ?? ''),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      drawer: Drawer(
        width: 288,
        backgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(AppRadius.xl)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Builder(
              // Fecha a gaveta antes de executar a ação do item
              builder: (drawerContext) => _AppPanelMenuScope(
                expanded: true,
                child: _PanelMenu(
                  header: widget.header,
                  status: widget.status,
                  destinations: widget.destinations,
                  selectedIndex: widget.selectedIndex,
                  onDestinationSelected: (index) {
                    Navigator.of(drawerContext).pop();
                    widget.onDestinationSelected(index);
                  },
                  onLogout: widget.onLogout,
                ),
              ),
            ),
          ),
        ),
      ),
      body: widget.body,
    );
  }
}

/// Informa aos itens do menu se ele está expandido (com rótulos)
class _AppPanelMenuScope extends InheritedWidget {
  final bool expanded;

  const _AppPanelMenuScope({required this.expanded, required super.child});

  static bool expandedOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AppPanelMenuScope>()?.expanded ?? true;

  @override
  bool updateShouldNotify(_AppPanelMenuScope oldWidget) => expanded != oldWidget.expanded;
}

class _PanelMenu extends StatelessWidget {
  final Widget? header;
  final Widget? status;
  final List<AppPanelDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback? onLogout;

  /// Null na gaveta do celular, que é sempre expandida
  final VoidCallback? onToggle;

  const _PanelMenu({
    required this.header,
    this.status,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onLogout,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final expanded = _AppPanelMenuScope.expandedOf(context);
    final divider = Divider(height: 24, indent: 8, endIndent: 8, color: context.appColors.border);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onToggle != null) ...[
          _PanelMenuItem(
            icon: expanded ? Icons.menu_open : Icons.menu,
            label: 'Menu',
            tooltip: expanded ? 'Recolher menu' : 'Expandir menu',
            onTap: onToggle!,
          ),
          const SizedBox(height: 8),
        ],
        if (header != null) header!,
        if (status != null) ...[const SizedBox(height: 4), status!],
        if (header != null || status != null) divider,
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              for (var i = 0; i < destinations.length; i++)
                _PanelMenuItem(
                  icon: i == selectedIndex ? destinations[i].selectedIcon : destinations[i].icon,
                  label: destinations[i].label,
                  badge: destinations[i].badge,
                  selected: i == selectedIndex,
                  onTap: () => onDestinationSelected(i),
                ),
            ],
          ),
        ),
        if (onLogout != null) ...[
          divider,
          _PanelMenuItem(icon: Icons.logout, label: 'Sair', onTap: onLogout!),
        ],
      ],
    );
  }
}

class _PanelMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final int badge;
  final String? tooltip;

  const _PanelMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.badge = 0,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final expanded = _AppPanelMenuScope.expandedOf(context);
    final foreground = selected ? colors.primaryText : colors.textMuted;

    Widget iconWidget = Icon(icon, color: foreground, size: 22);
    if (badge > 0 && !expanded) {
      iconWidget = Badge(
        label: Text('$badge'),
        backgroundColor: colors.danger,
        textColor: colors.isDark ? colors.background : Colors.white,
        child: iconWidget,
      );
    }

    final button = Material(
      color: selected ? colors.primary.withValues(alpha: 0.12) : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              if (expanded) ...[
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? colors.primaryText : colors.text,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (badge > 0) _Counter(value: badge),
              ],
            ],
          ),
        ),
      ),
    );

    final item = Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      // Recolhido, o Center mantém o ícone centralizado em vez de esticado
      child: expanded ? button : Center(child: button),
    );

    if (expanded && tooltip == null) return item;
    return Tooltip(message: tooltip ?? label, child: item);
  }
}

class _Counter extends StatelessWidget {
  final int value;

  const _Counter({required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: colors.danger, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(
        '$value',
        style: TextStyle(
          color: colors.isDark ? colors.background : Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Opção do menu do cabeçalho (um perfil ou um restaurante)
class AppPanelProfileOption {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const AppPanelProfileOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });
}

/// Grupo de opções com título (ex: "Seus perfis", "Seus restaurantes")
class AppPanelProfileSection {
  final String title;
  final List<AppPanelProfileOption> options;

  const AppPanelProfileSection({required this.title, required this.options});
}

/// Cabeçalho do menu do painel: avatar, nome e perfil ativo; um toque abre a troca de perfil
///
/// Recolhido mostra só o avatar. Seções vazias não aparecem; sem nenhuma opção, não abre menu.
class AppPanelProfileHeader extends StatelessWidget {
  final Widget avatar;
  final String title;
  final String? subtitle;
  final List<AppPanelProfileSection> sections;

  const AppPanelProfileHeader({
    super.key,
    required this.avatar,
    required this.title,
    this.subtitle,
    this.sections = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final expanded = _AppPanelMenuScope.expandedOf(context);
    final visibleSections = sections.where((s) => s.options.isNotEmpty).toList();
    final hasMenu = visibleSections.isNotEmpty;

    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(colors.surface),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8)),
      ),
      menuChildren: [
        for (var s = 0; s < visibleSections.length; s++) ...[
          if (s > 0) Divider(height: 12, color: colors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
            child: Text(
              visibleSections[s].title.toUpperCase(),
              style: TextStyle(color: colors.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6),
            ),
          ),
          for (final option in visibleSections[s].options)
            MenuItemButton(
              leadingIcon: Icon(option.icon, size: 20, color: option.selected ? colors.primaryText : colors.textMuted),
              trailingIcon: option.selected ? Icon(Icons.check, size: 18, color: colors.primaryText) : null,
              onPressed: option.selected ? null : option.onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 160),
                child: Text(
                  option.label,
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: option.selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ],
      builder: (context, controller, _) {
        void toggle() => controller.isOpen ? controller.close() : controller.open();

        final content = expanded
            ? Row(
                children: [
                  avatar,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.text, fontWeight: FontWeight.w700),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: colors.textMuted, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  if (hasMenu) Icon(Icons.unfold_more, size: 20, color: colors.textMuted),
                ],
              )
            : Center(child: avatar);

        return Tooltip(
          message: hasMenu ? 'Trocar perfil' : title,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: hasMenu ? toggle : null,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: expanded ? 8 : 0),
                child: content,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Situação atual exibida no menu do painel (ex: loja aberta, entregador online).
/// Recolhido mostra só um ponto colorido; um toque abre [menuChildren] com as ações.
class AppPanelStatus extends StatelessWidget {
  /// Cor semântica da situação (verde = ativo, âmbar = pausado, vermelho = parado)
  final Color color;
  final String label;
  final String? detail;
  final List<Widget> menuChildren;

  const AppPanelStatus({
    super.key,
    required this.color,
    required this.label,
    this.detail,
    this.menuChildren = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final expanded = _AppPanelMenuScope.expandedOf(context);
    final dot = Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 6, spreadRadius: 1)],
      ),
    );

    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(colors.surface),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8)),
      ),
      menuChildren: menuChildren,
      builder: (context, controller, _) {
        final onTap = menuChildren.isEmpty ? null : () => controller.isOpen ? controller.close() : controller.open();

        final content = expanded
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    dot,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: colors.text, fontWeight: FontWeight.w700, fontSize: 13)),
                          if (detail != null)
                            Text(detail!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: colors.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (onTap != null) Icon(Icons.expand_more, size: 20, color: colors.textMuted),
                  ],
                ),
              )
            : SizedBox(height: 40, child: Center(child: dot));

        return Tooltip(
          message: detail == null ? label : '$label · $detail',
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: onTap,
              child: content,
            ),
          ),
        );
      },
    );
  }
}
