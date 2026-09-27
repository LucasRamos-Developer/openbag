import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/ui/ui.dart';
import '../brand/openbag_logo.dart';
import '../cart/cart_nav_button.dart';
import 'panel_profiles.dart';

/// Link ativo da barra da vitrine
enum StorefrontLink { restaurants, orders, none }

/// Estrutura das telas do cliente: barra horizontal de vidro no topo (logo, links, carrinho e conta)
/// com o conteúdo passando por baixo dela.
///
/// - Sem [title]: o [body] ocupa a tela inteira e deve reservar o topo com [StorefrontScaffold.topInset]
///   (ex: banner que começa atrás da barra).
/// - Com [title]: mostra uma linha de título com voltar e [actions], na largura [maxWidth].
class StorefrontScaffold extends StatelessWidget {
  final Widget body;
  final StorefrontLink current;
  final String? title;
  final List<Widget> actions;

  /// Largura do título; use a mesma do conteúdo da página
  final double maxWidth;
  final Widget? bottomNavigationBar;

  /// Ação do voltar do título; padrão: tela anterior ou a vitrine
  final VoidCallback? onBack;

  const StorefrontScaffold({
    super.key,
    required this.body,
    this.current = StorefrontLink.none,
    this.title,
    this.actions = const [],
    this.maxWidth = AppLayout.maxContentWidth,
    this.bottomNavigationBar,
    this.onBack,
  });

  /// Altura ocupada pela barra (e pela área do sistema) sobre o conteúdo
  static double topInset(BuildContext context) => MediaQuery.paddingOf(context).top;

  static void back(BuildContext context) => context.canPop() ? context.pop() : context.go('/home');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppTopNavBar(
        logo: OpenBagLogo(onTap: () => context.go('/home')),
        links: [
          AppNavLink(
            label: 'Restaurantes',
            icon: Icons.storefront_outlined,
            selected: current == StorefrontLink.restaurants,
            onTap: () => context.go('/home'),
          ),
          AppNavLink(
            label: 'Meus pedidos',
            icon: Icons.receipt_long_outlined,
            selected: current == StorefrontLink.orders,
            onTap: () => context.go('/pedidos'),
          ),
        ],
        trailing: const [CartNavButton(), SizedBox(width: 4), AccountMenuButton()],
      ),
      bottomNavigationBar: bottomNavigationBar,
      // O Builder lê a altura da barra de dentro do Scaffold (fora dele ela ainda não foi descontada)
      body: title == null ? body : Builder(builder: _withTitle),
    );
  }

  Widget _withTitle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: topInset(context)),
        LayoutBuilder(builder: (context, constraints) {
          final padding = AppLayout.contentPadding(constraints.maxWidth, top: 16, bottom: 4, maxWidth: maxWidth);
          return Padding(
            // O botão voltar fica um pouco para fora, alinhando o título ao conteúdo
            padding: padding.copyWith(left: padding.left - 8),
            child: Row(
              children: [
                IconButton(tooltip: 'Voltar', icon: const Icon(Icons.arrow_back), onPressed: onBack ?? () => back(context)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                ...actions,
              ],
            ),
          );
        }),
        // O título já reserva o topo: o conteúdo não precisa descontar a barra de novo
        Expanded(child: MediaQuery.removePadding(context: context, removeTop: true, child: body)),
      ],
    );
  }
}
