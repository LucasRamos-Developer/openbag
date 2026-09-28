import 'package:flutter/material.dart';
import '../theme/app_theme_colors.dart';

/// Fundo da marca quando não há foto: a cor do tema (escurecida, como no banner) com bolinhas sutis.
/// É o mesmo fundo do [AppHeroBanner] sem imagem; use dentro do tema da loja para sair com a cor dela.
class AppBrandBackdrop extends StatelessWidget {
  /// Onde as bolinhas começam, em fração da largura (0 = desde a borda esquerda)
  final double dotsFrom;

  /// Distância entre as bolinhas
  final double gap;

  const AppBrandBackdrop({super.key, this.dotsFrom = 0, this.gap = 22});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: context.appColors.heroGradient.first),
        CustomPaint(painter: _DotsPainter(color: Colors.white.withValues(alpha: 0.08), from: dotsFrom, gap: gap)),
      ],
    );
  }
}

class _DotsPainter extends CustomPainter {
  final Color color;
  final double from;
  final double gap;

  _DotsPainter({required this.color, required this.from, required this.gap});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var y = gap / 2; y < size.height; y += gap) {
      for (var x = size.width * from + gap / 2; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotsPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.from != from || oldDelegate.gap != gap;
}
