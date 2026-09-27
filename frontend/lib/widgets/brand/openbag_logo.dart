import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';

/// Logo do OpenBag na barra da vitrine.
///
/// Provisório: ícone + "OPENBAG" em texto, no espaço reservado ([width] × [height]).
/// Para usar a arte final, troque o conteúdo por `Image.asset('assets/brand/logo.png', height: height)`.
class OpenBagLogo extends StatelessWidget {
  final VoidCallback? onTap;
  final double height;
  final double width;

  /// Verde da marca OpenBag (fixo: não segue o tema do restaurante)
  static const brandGreen = Color(0xFF2FB54A);

  const OpenBagLogo({super.key, this.onTap, this.height = 32, this.width = 132});

  @override
  Widget build(BuildContext context) {
    final text = context.appColors.text;
    final style = TextStyle(
      fontSize: height * 0.62,
      fontWeight: FontWeight.w800,
      fontStyle: FontStyle.italic,
      letterSpacing: -0.3,
      height: 1,
    );

    return Semantics(
      label: 'OpenBag, início',
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: SizedBox(
          width: width,
          height: height,
          child: Row(
            children: [
              Icon(Icons.shopping_bag_rounded, color: brandGreen, size: height * 0.9),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: 'OPEN', style: style.copyWith(color: text)),
                    TextSpan(text: 'BAG', style: style.copyWith(color: brandGreen)),
                  ])),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
