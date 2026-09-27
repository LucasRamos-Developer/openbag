import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../core/ui/ui.dart';

/// Foto de item/combo do cardápio (imagem pública) com placeholder
class MenuImage extends StatelessWidget {
  final String? imageUrl;
  final double size;

  /// Altura diferente da largura ([size]); por padrão a imagem é quadrada
  final double? height;
  final double radius;

  const MenuImage({super.key, required this.imageUrl, this.size = 72, this.height, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final h = height ?? size;
    final placeholder = Container(
      width: size,
      height: h,
      color: colors.secondary,
      child: Icon(Icons.restaurant_menu, color: colors.onSecondary.withValues(alpha: 0.6), size: (h < size ? h : size) * 0.4),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: imageUrl == null
          ? placeholder
          : Image.network(
              AppConstants.fileUrl(imageUrl!),
              width: size,
              height: h,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
            ),
    );
  }
}
