import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/cart_service.dart';
import '../../utils/formatters.dart';

/// Botão flutuante do carrinho no pé da tela: "Ver carrinho · 3 itens · R$ 45,00".
/// Some quando o carrinho está vazio ou é de outro restaurante ([restaurantId]).
/// Use como `bottomNavigationBar` do [StorefrontScaffold], que reserva o espaço dele no fim da rolagem.
class CartBar extends StatelessWidget {
  final int? restaurantId;

  /// Largura máxima do botão (centralizado em telas largas)
  static const double maxWidth = 560;

  const CartBar({super.key, this.restaurantId});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    if (cart.isEmpty || (restaurantId != null && cart.restaurant?.id != restaurantId)) {
      return const SizedBox.shrink();
    }
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Material(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.35),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.push('/cart'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    children: [
                      Icon(Icons.shopping_bag_outlined, color: colorScheme.onPrimary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ver carrinho',
                          style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      ),
                      Text(
                        '${cart.itemCount} ${cart.itemCount == 1 ? 'item' : 'itens'}  ·  ${formatMoney(cart.subtotal)}',
                        style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
