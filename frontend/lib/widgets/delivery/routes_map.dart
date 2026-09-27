import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
    final store = LatLng(storeLatitude, storeLongitude);
    final points = <LatLng>[
      store,
      for (final card in cards)
        for (final s in card.stops)
          if (s.hasLocation) LatLng(s.latitude!, s.longitude!),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: store,
          initialZoom: 14,
          initialCameraFit: points.length > 1
              ? CameraFit.bounds(bounds: LatLngBounds.fromPoints(points), padding: const EdgeInsets.all(48), maxZoom: 16)
              : null,
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.openbag.app',
            maxZoom: 19,
          ),
          PolylineLayer(
            polylines: [
              for (final card in cards)
                if (card.stops.any((s) => s.hasLocation))
                  Polyline(
                    points: [store, for (final s in card.stops) if (s.hasLocation) LatLng(s.latitude!, s.longitude!)],
                    color: RouteColors.of(card.routeId).withValues(alpha: card.isRoute ? 0.9 : 0.5),
                    strokeWidth: card.isRoute ? 3 : 2,
                  ),
            ],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: store,
                width: 40,
                height: 40,
                child: Tooltip(
                  message: 'Sua loja',
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A19),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(Icons.storefront, color: Colors.white, size: 20),
                  ),
                ),
              ),
              for (final card in cards)
                for (var i = 0; i < card.stops.length; i++)
                  if (card.stops[i].hasLocation)
                    Marker(
                      point: LatLng(card.stops[i].latitude!, card.stops[i].longitude!),
                      width: 32,
                      height: 32,
                      child: _StopMarker(
                        color: RouteColors.of(card.routeId),
                        label: card.isRoute ? '${i + 1}' : '•',
                        tooltip: [card.stops[i].displayCode, card.stops[i].neighborhood].whereType<String>().join(' · '),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StopMarker extends StatelessWidget {
  final Color color;
  final String label;
  final String tooltip;

  const _StopMarker({required this.color, required this.label, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          // Anel branco: separa a cor do fundo do mapa
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Text(label, style: TextStyle(color: RouteColors.onColor(color), fontWeight: FontWeight.w800, fontSize: 13)),
      ),
    );
  }
}
