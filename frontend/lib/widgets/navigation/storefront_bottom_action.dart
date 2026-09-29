import 'package:flutter/material.dart';

/// Ação principal fixa no rodapé das telas da compra (carrinho e checkout).
/// Fica com a mesma largura do conteúdo (720), em vez de atravessar a tela inteira no desktop.
class StorefrontBottomAction extends StatelessWidget {
  final Widget child;

  /// Largura do conteúdo da tela
  final double maxWidth;

  const StorefrontBottomAction({super.key, required this.child, this.maxWidth = 720});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }
}
