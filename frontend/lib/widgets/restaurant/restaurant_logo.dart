import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../core/ui/ui.dart';

/// Logo do restaurante (imagem pública) ou as iniciais do nome
class RestaurantLogo extends StatelessWidget {
  final String? logoUrl;
  final String name;
  final double size;

  const RestaurantLogo({super.key, required this.logoUrl, required this.name, this.size = 56});

  @override
  Widget build(BuildContext context) =>
      AppImageAvatar(url: logoUrl != null ? AppConstants.fileUrl(logoUrl!) : null, name: name, size: size);
}
