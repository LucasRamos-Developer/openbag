import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../services/cart_service.dart';

/// Botão do carrinho da barra da vitrine, com a quantidade de itens
class CartNavButton extends StatelessWidget {
  const CartNavButton({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.watch<CartService>().itemCount;
    final colors = context.appColors;

    return IconButton(
      tooltip: 'Carrinho',
      onPressed: () => context.push('/cart'),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        backgroundColor: colors.action,
        textColor: colors.onAction,
        child: const Icon(Icons.shopping_bag_outlined),
      ),
    );
  }
}
