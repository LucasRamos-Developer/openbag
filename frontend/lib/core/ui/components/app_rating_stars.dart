import 'package:flutter/material.dart';
import '../theme/app_theme_colors.dart';

/// Nota de 0 a 5 em estrelas (com meia estrela), na cor semântica de avaliação
class AppRatingStars extends StatelessWidget {
  final double rating;
  final double size;

  const AppRatingStars({super.key, required this.rating, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final color = context.appColors.rating;
    return Semantics(
      label: 'Nota ${rating.toStringAsFixed(1)} de 5',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 1; i <= 5; i++)
              Icon(
                rating >= i - 0.25
                    ? Icons.star_rounded
                    : (rating >= i - 0.75 ? Icons.star_half_rounded : Icons.star_outline_rounded),
                color: color,
                size: size,
              ),
          ],
        ),
      ),
    );
  }
}

/// Escolha de nota de 1 a 5 com estrelas grandes, fáceis de tocar
class AppRatingInput extends StatelessWidget {
  final int? value;
  final ValueChanged<int> onChanged;
  final double size;

  const AppRatingInput({super.key, required this.value, required this.onChanged, this.size = 40});

  static const labels = ['Muito ruim', 'Ruim', 'Regular', 'Bom', 'Excelente'];

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final value = this.value;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 1; i <= 5; i++)
              Semantics(
                button: true,
                selected: value == i,
                label: '$i ${i == 1 ? 'estrela' : 'estrelas'}: ${labels[i - 1]}',
                child: IconButton(
                  onPressed: () => onChanged(i),
                  iconSize: size,
                  padding: const EdgeInsets.all(2),
                  constraints: BoxConstraints.tight(Size.square(size + 8)),
                  icon: Icon(
                    value != null && i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: value != null && i <= value ? c.rating : c.textMuted,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(
          height: 20,
          child: Text(value != null ? labels[value - 1] : 'Toque nas estrelas',
              style: TextStyle(color: c.textMuted, fontSize: 13)),
        ),
      ],
    );
  }
}
