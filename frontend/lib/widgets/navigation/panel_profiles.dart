import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../models/panel_profile.dart';
import '../../services/auth_service.dart';

/// Seção "Seus perfis" do cabeçalho do painel: troca entre os painéis do usuário e a área de cliente
AppPanelProfileSection panelProfilesSection(BuildContext context, {required PanelProfile current}) {
  final user = context.read<AuthService>().currentUser;
  final profiles = user == null ? const <PanelProfile>[] : PanelProfile.of(user);

  return AppPanelProfileSection(
    title: 'Seus perfis',
    // Só um perfil: não há para onde trocar
    options: profiles.length < 2
        ? const []
        : [
            for (final profile in profiles)
              AppPanelProfileOption(
                icon: profile.icon,
                label: profile.label,
                selected: profile == current,
                onTap: () => context.go(profile.route),
              ),
          ],
  );
}

/// Botão de conta da vitrine: perfil, pedidos e, para quem tem, os painéis de gestão.
/// Sem login, vira o botão "Entrar".
class AccountMenuButton extends StatelessWidget {
  const AccountMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    if (user == null) {
      return AppButton(
        text: 'Entrar',
        icon: Icons.login_rounded,
        size: ButtonSize.small,
        onPressed: () => context.push(
          Uri(path: '/login', queryParameters: {'next': GoRouterState.of(context).uri.toString()}).toString(),
        ),
      );
    }

    final panels = PanelProfile.of(user).where((p) => p.isPanel).toList();
    final colors = context.appColors;
    Widget sectionTitle(String title) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
          child: Text(
            title,
            style: TextStyle(color: colors.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6),
          ),
        );

    return MenuAnchor(
      alignmentOffset: const Offset(0, 6),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(colors.surface),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8)),
      ),
      menuChildren: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.fullName, style: TextStyle(color: colors.text, fontWeight: FontWeight.w700)),
              Text(user.email, style: TextStyle(color: colors.textMuted, fontSize: 12)),
            ],
          ),
        ),
        Divider(height: 8, color: colors.border),
        // No celular os links da barra somem: ficam também aqui
        MenuItemButton(
          leadingIcon: const Icon(Icons.storefront_outlined),
          onPressed: () => context.go('/home'),
          child: const Text('Restaurantes'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.receipt_long_outlined),
          onPressed: () => context.push('/pedidos'),
          child: const Text('Meus pedidos'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.person_outline),
          onPressed: () => context.push('/profile'),
          child: const Text('Minha conta'),
        ),
        if (panels.isNotEmpty) ...[
          Divider(height: 12, color: colors.border),
          sectionTitle('MEUS PAINÉIS'),
          for (final panel in panels)
            MenuItemButton(
              leadingIcon: Icon(panel.icon),
              onPressed: () => context.go(panel.route),
              child: Text(panel.label),
            ),
        ],
      ],
      builder: (context, controller, _) => IconButton(
        tooltip: 'Minha conta',
        icon: CircleAvatar(
          radius: 16,
          backgroundColor: colors.primary.withValues(alpha: 0.14),
          child: Text(
            user.fullName.isEmpty ? '?' : user.fullName.characters.first.toUpperCase(),
            style: TextStyle(color: colors.primaryText, fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
        onPressed: () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}
