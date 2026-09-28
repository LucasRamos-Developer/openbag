import 'package:flutter/material.dart';
import '../theme/app_theme_colors.dart';
import 'app_brand_backdrop.dart';

/// Banner de destaque: foto à direita com degradê da cor da marca vindo da esquerda,
/// título, subtítulo e um sublinhado na cor accent. Sem [image], mostra só o degradê com textura sutil.
///
/// O texto fica sempre sobre a área do degradê, então qualquer foto continua legível.
class AppHeroBanner extends StatelessWidget {
  final String title;
  final String? subtitle;
  final ImageProvider? image;
  final VoidCallback? onBack;
  final double height;

  /// Espaço extra embaixo para um card sobreposto (ex: card de informações)
  final double bottomInset;

  /// Espaço extra em cima para uma barra de navegação transparente sobreposta
  final double topInset;

  const AppHeroBanner({
    super.key,
    required this.title,
    this.subtitle,
    this.image,
    this.onBack,
    this.height = 220,
    this.bottomInset = 0,
    this.topInset = 0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) => _build(context, constraints.maxWidth));
  }

  Widget _build(BuildContext context, double width) {
    final colors = context.appColors;
    final gradient = colors.heroGradient;
    final compact = width < 600;
    final titleStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: compact ? 26 : 38,
          height: 1.1,
        );

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.xl)),
      child: SizedBox(
        height: topInset + height + bottomInset,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: gradient.first),
            if (image != null)
              // Celular: foto no banner inteiro. Desktop: foto à direita com a borda esquerda
              // esmaecida, para não cortar demais o prato em telas largas.
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                left: compact ? 0 : width * 0.30,
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) => LinearGradient(
                    colors: const [Colors.transparent, Colors.black],
                    stops: compact ? const [0.0, 0.0] : const [0.0, 0.35],
                  ).createShader(rect),
                  child: Image(
                    image: image!,
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              )
            else
              const AppBrandBackdrop(dotsFrom: 0.35),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: gradient,
                  stops: compact ? const [0.0, 0.55, 1.0] : const [0.0, 0.30, 0.55],
                ),
              ),
            ),
            // Escurece um pouco a base no celular, onde a foto fica atrás do texto
            if (compact && image != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withValues(alpha: 0.0), Colors.black.withValues(alpha: 0.35)],
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(compact ? 20 : 48, 16 + topInset, compact ? 20 : 48, 24 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (onBack != null)
                    _CircleButton(icon: Icons.arrow_back, tooltip: 'Voltar', onPressed: onBack!)
                  else
                    const SizedBox(height: 44),
                  const Spacer(),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: titleStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontWeight: FontWeight.w500,
                                  fontSize: compact ? 15 : 18,
                                ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Container(width: 56, height: 4, decoration: _bar(colors.accent)),
                            const SizedBox(width: 4),
                            Container(width: 28, height: 4, decoration: _bar(Colors.white.withValues(alpha: 0.35))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static BoxDecoration _bar(Color color) =>
      BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadius.pill));
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _CircleButton({required this.icon, required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white.withValues(alpha: 0.18),
        shape: const CircleBorder(),
        child: IconButton(
          icon: Icon(icon, color: Colors.white),
          tooltip: tooltip,
          onPressed: onPressed,
        ),
      );
}
