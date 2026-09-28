import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Ponto no mapa (latitude, longitude)
class AppMapPoint {
  final double latitude;
  final double longitude;

  const AppMapPoint(this.latitude, this.longitude);

  LatLng get _latLng => LatLng(latitude, longitude);

  @override
  bool operator ==(Object other) => other is AppMapPoint && other.latitude == latitude && other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

/// Marcador redondo com borda branca, com um texto curto dentro ([label], ex: "1") e uma legenda ao lado ([caption])
class AppMapMarker {
  final AppMapPoint point;
  final Color color;
  final String? label;
  final String? caption;
  final double radius;

  const AppMapMarker({required this.point, required this.color, this.label, this.caption, this.radius = 12});
}

/// Linha entre pontos (ex: o caminho de uma rota)
class AppMapLine {
  final List<AppMapPoint> points;
  final Color color;
  final double width;
  final double opacity;

  const AppMapLine({required this.points, required this.color, this.width = 3, this.opacity = 0.9});
}

/// Mapa do app com o estilo próprio do OpenBag ([AppMapStyle]): claro, próximo das cores do Google Maps,
/// sem relevo e com a vegetação discreta. Desenhado pelo MapLibre (web, Android e iOS) com os dados do
/// OpenFreeMap, sem chave e sem limite de uso.
///
/// Marcadores e linhas são declarativos: mudou a lista, o mapa redesenha. Com [fitPoints], a câmera
/// enquadra os pontos; senão, centraliza em [center] com [zoom].
///
/// ```dart
/// AppMap(
///   center: AppMapPoint(-26.91, -49.06),
///   markers: [AppMapMarker(point: AppMapPoint(-26.91, -49.06), color: Colors.black, caption: 'Loja')],
/// )
/// ```
class AppMap extends StatefulWidget {
  final AppMapPoint center;
  final double zoom;
  final List<AppMapMarker> markers;
  final List<AppMapLine> lines;
  final List<AppMapPoint> fitPoints;

  /// Zoom máximo ao enquadrar [fitPoints] (evita aproximar demais com pontos muito próximos)
  final double fitMaxZoom;

  /// Arrastar e dar zoom; sem rotação nem inclinação
  final bool interactive;

  const AppMap({
    super.key,
    required this.center,
    this.zoom = 15,
    this.markers = const [],
    this.lines = const [],
    this.fitPoints = const [],
    this.fitMaxZoom = 16,
    this.interactive = true,
  });

  @override
  State<AppMap> createState() => _AppMapState();
}

class _AppMapState extends State<AppMap> {
  MapLibreMapController? _controller;
  bool _styleLoaded = false;

  // Evita desenhar duas vezes ao mesmo tempo quando a lista muda durante um redesenho
  Future<void> _drawing = Future.value();

  @override
  void didUpdateWidget(covariant AppMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_styleLoaded) return;
    _redraw();
    if (!_samePoints(oldWidget.fitPoints, widget.fitPoints)) _fit();
  }

  static bool _samePoints(List<AppMapPoint> a, List<AppMapPoint> b) =>
      a.length == b.length && Iterable.generate(a.length).every((i) => a[i] == b[i]);

  void _onStyleLoaded() {
    _styleLoaded = true;
    _redraw();
    _fit();
  }

  void _redraw() {
    final controller = _controller;
    if (controller == null) return;
    _drawing = _drawing.then((_) async {
      await controller.clearLines();
      await controller.clearCircles();
      await controller.clearSymbols();
      for (final line in widget.lines) {
        if (line.points.length < 2) continue;
        await controller.addLine(LineOptions(
          geometry: [for (final p in line.points) p._latLng],
          lineColor: _hex(line.color),
          lineWidth: line.width,
          lineOpacity: line.opacity,
          lineJoin: 'round',
        ));
      }
      for (final marker in widget.markers) {
        await controller.addCircle(CircleOptions(
          geometry: marker.point._latLng,
          circleRadius: marker.radius,
          circleColor: _hex(marker.color),
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 3,
        ));
        if (marker.label != null) {
          await controller.addSymbol(SymbolOptions(
            geometry: marker.point._latLng,
            textField: marker.label,
            textSize: 12,
            textColor: _hex(marker.color.computeLuminance() > 0.3 ? const Color(0xFF1A1A19) : Colors.white),
            fontNames: const ['Noto Sans Bold'],
          ));
        }
        if (marker.caption != null) {
          await controller.addSymbol(SymbolOptions(
            geometry: marker.point._latLng,
            textField: marker.caption,
            textSize: 12,
            textColor: '#3C3C3C',
            textHaloColor: '#FFFFFF',
            textHaloWidth: 1.5,
            textAnchor: 'left',
            textOffset: Offset(marker.radius / 10 + 0.6, 0),
            fontNames: const ['Noto Sans Bold'],
          ));
        }
      }
    });
  }

  void _fit() {
    final controller = _controller;
    final points = widget.fitPoints;
    if (controller == null || points.length < 2) return;
    final lats = points.map((p) => p.latitude);
    final lngs = points.map((p) => p.longitude);
    final bounds = LatLngBounds(
      southwest: LatLng(lats.reduce((a, b) => a < b ? a : b), lngs.reduce((a, b) => a < b ? a : b)),
      northeast: LatLng(lats.reduce((a, b) => a > b ? a : b), lngs.reduce((a, b) => a > b ? a : b)),
    );
    controller.moveCamera(CameraUpdate.newLatLngBounds(bounds, left: 48, top: 48, right: 48, bottom: 64)).then((_) {
      final zoom = controller.cameraPosition?.zoom;
      if (zoom != null && zoom > widget.fitMaxZoom) {
        controller.moveCamera(CameraUpdate.zoomTo(widget.fitMaxZoom));
      }
    });
  }

  static String _hex(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: AppMapStyle.load(),
      builder: (context, snapshot) {
        final style = snapshot.data;
        if (style == null) return const ColoredBox(color: AppMapStyle.background, child: SizedBox.expand());
        return MapLibreMap(
          styleString: style,
          initialCameraPosition: CameraPosition(target: widget.center._latLng, zoom: widget.zoom),
          onMapCreated: (controller) => _controller = controller,
          onStyleLoadedCallback: _onStyleLoaded,
          trackCameraPosition: true,
          compassEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          scrollGesturesEnabled: widget.interactive,
          zoomGesturesEnabled: widget.interactive,
          dragEnabled: widget.interactive,
          doubleClickZoomEnabled: widget.interactive,
          attributionButtonPosition: AttributionButtonPosition.bottomRight,
        );
      },
    );
  }
}

/// Estilo do mapa: `assets/map/openbag_style.json` (formato de estilo do MapLibre). Para mudar cores
/// ou o que aparece, edite o JSON. O crédito dos dados (OpenFreeMap, OpenMapTiles, OpenStreetMap)
/// aparece no botão de atribuição do próprio mapa.
///
/// Para usar uma base raster pronta (ex: MapTiler com chave), passe a URL no build:
/// `flutter build web --dart-define=MAP_TILE_URL=https://.../{z}/{x}/{y}.png?key=...`
abstract final class AppMapStyle {
  static const asset = 'assets/map/openbag_style.json';
  static const _rasterUrl = String.fromEnvironment('MAP_TILE_URL');
  static const _rasterAttribution = String.fromEnvironment('MAP_TILE_ATTRIBUTION', defaultValue: '© OpenStreetMap');

  /// Cor de fundo enquanto o mapa carrega (a mesma do "background" do estilo)
  static const background = Color(0xFFF5F4F1);

  static Future<String>? _style;

  /// JSON do estilo, carregado uma vez e compartilhado por todos os mapas
  static Future<String> load() => _style ??= _rasterUrl.isNotEmpty
      ? Future.value(json.encode({
          'version': 8,
          'glyphs': 'https://tiles.openfreemap.org/fonts/{fontstack}/{range}.pbf',
          'sources': {
            'raster': {'type': 'raster', 'tiles': [_rasterUrl], 'tileSize': 256, 'attribution': _rasterAttribution},
          },
          'layers': [
            {'id': 'raster', 'type': 'raster', 'source': 'raster'},
          ],
        }))
      : rootBundle.loadString(asset);
}
