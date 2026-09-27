import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/ui/ui.dart';
import '../../models/panel_profile.dart';
import '../../services/auth_service.dart';
import '../../widgets/navigation/storefront_footer.dart';
import '../../widgets/navigation/storefront_scaffold.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StorefrontScaffold(
      title: 'Minha conta',
      maxWidth: 720 - 32,
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          final user = authService.currentUser;
          final colors = context.appColors;
          final panels = user == null ? const <PanelProfile>[] : PanelProfile.of(user).where((p) => p.isPanel);
          
          // Mesma largura das outras telas de conta (lista de 720 com padding de 16)
          return AppPageListView(
            maxWidth: 720 - 32,
            top: 16,
            footer: const StorefrontFooter(),
            children: [
              if (user != null) ...[
                CircleAvatar(
                  radius: 50,
                  child: Text(
                    user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.fullName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  user.email,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: 32),
              ],
              if (panels.isNotEmpty) ...[
                const AppSectionHeader(title: 'Meus painéis'),
                for (final panel in panels)
                  ListTile(
                    leading: Icon(panel.icon),
                    title: Text(panel.label),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go(panel.route),
                  ),
                const Divider(),
              ],
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('Meus Pedidos'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/pedidos'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Endereços'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Funcionalidade em desenvolvimento')),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.payment),
                title: const Text('Pagamentos'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Funcionalidade em desenvolvimento')),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Configurações'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Funcionalidade em desenvolvimento')),
                  );
                },
              ),
              const Divider(),
              const SizedBox(height: 16),
              if (user != null)
                OutlinedButton.icon(
                  onPressed: () async {
                    await authService.logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.danger,
                    side: BorderSide(color: colors.danger),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
