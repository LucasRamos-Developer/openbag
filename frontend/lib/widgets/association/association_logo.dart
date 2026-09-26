import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../core/ui/ui.dart';
import '../../services/auth_service.dart';

/// Logo da associação (o endpoint de arquivos de associação exige o token) ou as iniciais do nome
class AssociationLogo extends StatelessWidget {
  final String? logoUrl;
  final String name;
  final double size;

  const AssociationLogo({super.key, required this.logoUrl, required this.name, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final token = context.read<AuthService>().token;
    return AppImageAvatar(
      url: logoUrl != null ? AppConstants.fileUrl(logoUrl!) : null,
      name: name,
      size: size,
      headers: token != null ? {'Authorization': 'Bearer $token'} : null,
    );
  }
}
