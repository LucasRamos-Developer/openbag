import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/app_theme_colors.dart';
import 'app_page_container.dart';

/// Link da barra de navegação superior
class AppNavLink {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const AppNavLink({required this.label, required this.icon, required this.onTap, this.selected = false});
}

/// Barra de navegação horizontal com efeito vidro (fundo translúcido e desfocado).
///
/// Feita para `Scaffold(extendBodyBehindAppBar: true)`: o conteúdo passa por baixo da barra.
/// O conteúdo interno segue a largura padrão ([AppLayout.maxContentWidth]). Em telas estreitas
/// ([compactBreakpoint]) os [links] saem da barra; ofereça-os também em algum menu do [trailing].
///
/// ```dart
/// Scaffold(
///   extendBodyBehindAppBar: true,
///   appBar: AppTopNavBar(
///     logo: const OpenBagLogo(),
///     links: [AppNavLink(label: 'Restaurantes', icon: Icons.storefront_outlined, selected: true, onTap: ...)],
///     trailing: [CartButton(), AccountMenuButton()],
///   ),
///   body: ...,
/// )
/// ```
class AppTopNavBar extends StatelessWidget implements PreferredSizeWidget {
  /// Opcional: a vitrine deixa a barra livre (a marca fica no rodapé)
  final Widget? logo;
  final List<AppNavLink> links;
  final List<Widget> trailing;
  final double height;
  final double compactBreakpoint;

  const AppTopNavBar({
    super.key,
    this.logo,
    this.links = const [],
    this.trailing = const [],
    this.height = 64,
    this.compactBreakpoint = 700,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: colors.isDark ? 0.62 : 0.72),
            border: Border(bottom: BorderSide(color: colors.border.withValues(alpha: 0.7))),
            boxShadow: [
              BoxShadow(color: colors.text.withValues(alpha: colors.isDark ? 0.18 : 0.05), blurRadius: 18),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: height,
              child: LayoutBuilder(builder: (context, constraints) {
                final compact = constraints.maxWidth < compactBreakpoint;
                return Padding(
                  padding: AppLayout.contentPadding(constraints.maxWidth, top: 0, bottom: 0),
                  child: Row(
                    children: [
                      if (logo != null) logo!,
                      if (!compact && links.isNotEmpty) ...[
                        if (logo != null) const SizedBox(width: 32),
                        for (final link in links) ...[_NavLinkButton(link: link), const SizedBox(width: 4)],
                      ],
                      const Spacer(),
                      ...trailing,
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavLinkButton extends StatelessWidget {
  final AppNavLink link;

  const _NavLinkButton({required this.link});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final foreground = link.selected ? colors.primaryText : colors.text;

    return Material(
      color: link.selected ? colors.primary.withValues(alpha: 0.12) : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: link.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(link.icon, size: 19, color: link.selected ? colors.primaryText : colors.textMuted),
              const SizedBox(width: 8),
              Text(
                link.label,
                style: TextStyle(
                  color: foreground,
                  fontWeight: link.selected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
