import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/cart/cart_line_tile.dart';
import '../../widgets/order/price_summary.dart';
import '../../widgets/restaurant/restaurant_logo.dart';
import '../../widgets/navigation/storefront_scaffold.dart';

/// Carrinho: itens com complementos, quantidades, totais e pedido mínimo
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  /// Largura útil da lista (720 menos o padding de 16 de cada lado), usada para alinhar o título
  static const double _contentWidth = 720 - 32;

  void _checkout(BuildContext context) {
    final auth = context.read<AuthService>();
    if (!auth.isAuthenticated) {
      AppToast.show(context, message: 'Entre na sua conta para finalizar o pedido', type: ToastType.info);
      context.go('/login?next=/checkout');
      return;
    }
    context.push('/checkout');
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final restaurant = cart.restaurant;
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    return StorefrontScaffold(
      title: 'Carrinho',
      maxWidth: _contentWidth,
      actions: [
          if (!cart.isEmpty)
            AppButton(
              text: 'Limpar',
              variant: ButtonVariant.text,
              onPressed: () async {
                final ok = await AppDialog.confirm(context,
                    title: 'Limpar o carrinho?', message: 'Todos os itens serão removidos.', confirmLabel: 'Limpar');
                if (ok) cart.clear();
              },
            ),
      ],
      body: cart.isEmpty
          ? AppEmptyState(
              icon: Icons.shopping_bag_outlined,
              message: 'Seu carrinho está vazio.',
              actionLabel: 'Ver restaurantes',
              onAction: () => context.go('/home'),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (restaurant != null)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: RestaurantLogo(logoUrl: restaurant.logoUrl, name: restaurant.name, size: 44),
                        title: Text(restaurant.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Adicionar mais itens'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('/r/${restaurant.slug}'),
                      ),
                    const Divider(),
                    for (final line in cart.lines)
                      CartLineTile(line: line, onQuantityChanged: (v) => cart.updateQuantity(line, v)),
                    const SizedBox(height: 16),
                    PriceSummary(
                      subtotal: cart.subtotal,
                      deliveryFee: cart.deliveryFee,
                      total: cart.total,
                      deliveryFeeFrom: cart.deliveryFeeByDistance,
                    ),
                    if (cart.deliveryFeeByDistance) ...[
                      const SizedBox(height: 4),
                      Text('A taxa depende da distância e aparece certinha no endereço de entrega.',
                          style: TextStyle(color: muted, fontSize: 12)),
                    ],
                    if (cart.missingForMinimum > 0) ...[
                      const SizedBox(height: 12),
                      AppCard(
                        padding: const EdgeInsets.all(12),
                        backgroundColor: AppColors.warningLighter.withValues(alpha: 0.5),
                        child: Text(
                          'Faltam ${formatMoney(cart.missingForMinimum)} para o pedido mínimo de '
                          '${formatMoney(restaurant!.minimumOrder)}.',
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text('Os preços são confirmados pelo restaurante ao finalizar.', style: TextStyle(color: muted, fontSize: 12)),
                  ],
                ),
              ),
            ),
      floatingBottomBar: false,
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppButton(
                  text: cart.missingForMinimum > 0 ? 'Pedido mínimo não atingido' : 'Continuar  ·  ${formatMoney(cart.total)}',
                  size: ButtonSize.large,
                  fullWidth: true,
                  onPressed: cart.missingForMinimum > 0 ? null : () => _checkout(context),
                ),
              ),
            ),
    );
  }
}
