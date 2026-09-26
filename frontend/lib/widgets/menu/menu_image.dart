import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

/// Foto de item/combo do cardápio (imagem pública) com placeholder
class MenuImage extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const MenuImage({super.key, required this.imageUrl, this.size = 72});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final placeholder = Container(
      width: size,
      height: size,
      color: colorScheme.primary.withValues(alpha: 0.08),
      child: Icon(Icons.restaurant_menu, color: colorScheme.primary.withValues(alpha: 0.5), size: size * 0.4),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: imageUrl == null
          ? placeholder
          : Image.network(
              AppConstants.fileUrl(imageUrl!),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
            ),
    );
  }
}
