import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/routes/routes_board.dart';

/// Cores das rotas: paleta categórica validada (ordem fixa, daltonismo ok); pedido sozinho em cinza.
/// A cor segue a rota (pelo id), e os números e cartões também identificam, então ela nunca é o único sinal.
abstract final class RouteColors {
  static const palette = [
    Color(0xFF2A78D6),
    Color(0xFFEB6834),
    Color(0xFF1BAF7A),
    Color(0xFFEDA100),
    Color(0xFFE87BA4),
    Color(0xFF008300),
    Color(0xFF4A3AA7),
    Color(0xFFE34948),
  ];

  static const single = Color(0xFF8A8A85);

  static Color of(int? routeId) => routeId == null ? single : palette[routeId % palette.length];

  /// Texto legível sobre a cor (preto nas claras, branco nas escuras)
  static Color onColor(Color color) => color.computeLuminance() > 0.3 ? const Color(0xFF1A1A19) : Colors.white;
}

/// Mapa das entregas: a loja, as paradas numeradas na ordem e a linha de cada rota
class RoutesMap extends StatelessWidget {
  final double storeLatitude;
  final double storeLongitude;
  final List<RouteCard> cards;

  const RoutesMap({super.key, required this.storeLatitude, required this.storeLongitude, required this.cards});

  @override
  Widget build(BuildContext context) {
    final store = AppMapPoint(storeLatitude, storeLongitude);
    AppMapPoint pointOf(RouteStop s) => AppMapPoint(s.latitude!, s.longitude!);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AppMap(
        center: store,
        zoom: 14,
        fitPoints: [
          store,
          for (final card in cards)
            for (final s in card.stops)
              if (s.hasLocation) pointOf(s),
        ],
        lines: [
          for (final card in cards)
            if (card.stops.any((s) => s.hasLocation))
              AppMapLine(
                points: [store, for (final s in card.stops) if (s.hasLocation) pointOf(s)],
                color: RouteColors.of(card.routeId),
                opacity: card.isRoute ? 0.9 : 0.5,
                width: card.isRoute ? 3 : 2,
              ),
        ],
        markers: [
          AppMapMarker(point: store, color: const Color(0xFF1A1A19), radius: 11, caption: 'Sua loja'),
          for (final card in cards)
            for (var i = 0; i < card.stops.length; i++)
              if (card.stops[i].hasLocation)
                AppMapMarker(
                  point: pointOf(card.stops[i]),
                  color: RouteColors.of(card.routeId),
                  label: card.isRoute ? '${i + 1}' : null,
                  // O código do pedido ao lado do ponto (no lugar da dica ao passar o mouse)
                  caption: card.stops[i].displayCode,
                ),
        ],
      ),
    );
  }
}
