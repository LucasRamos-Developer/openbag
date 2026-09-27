import 'package:flutter/material.dart';
import '../theme/app_theme_colors.dart';

/// Imagem quadrada arredondada (logo, avatar) com as iniciais do nome como fallback
class AppImageAvatar extends StatelessWidget {
  /// URL absoluta da imagem; null mostra as iniciais
  final String? url;
  final String name;
  final double size;

  /// Cabeçalhos da requisição da imagem (ex: token para arquivos protegidos)
  final Map<String, String>? headers;

  const AppImageAvatar({super.key, required this.url, required this.name, this.size = 48, this.headers});

  static String initialsOf(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .take(2)
      .map((word) => word[0])
      .join()
      .toUpperCase();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: colors.secondary,
      child: Text(
        initialsOf(name),
        style: TextStyle(color: colors.onSecondary, fontWeight: FontWeight.w800, fontSize: size * 0.36),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.25),
      child: url == null
          ? fallback
          : Image.network(
              url!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              headers: headers,
              errorBuilder: (_, __, ___) => fallback,
            ),
    );
  }
}
