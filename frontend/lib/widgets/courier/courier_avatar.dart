import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../core/ui/ui.dart';

/// Foto do entregador (arquivo público) ou as iniciais do nome
class CourierAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double size;

  const CourierAvatar({super.key, required this.photoUrl, required this.name, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return AppImageAvatar(
      url: photoUrl != null ? AppConstants.fileUrl(photoUrl!) : null,
      name: name,
      size: size,
    );
  }
}
