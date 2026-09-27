import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Mostra um lugar no app de mapas do próprio aparelho: no Android, o app padrão (ou a escolha do
/// usuário) via `geo:`; no iPhone, o Mapas da Apple; na web, o Google Maps numa nova aba
/// (no celular, ele abre o app se estiver instalado). Sem coordenadas, busca pelo endereço.
Future<void> openPlaceInMaps({double? latitude, double? longitude, String? label, String? address}) {
  final hasPoint = latitude != null && longitude != null;
  final query = hasPoint ? '$latitude,$longitude' : (address ?? label ?? '');
  if (query.isEmpty) return Future.value();

  final Uri uri;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    final name = label != null && hasPoint ? '$query($label)' : query;
    uri = Uri.parse('geo:${hasPoint ? query : '0,0'}?q=${Uri.encodeComponent(name)}');
  } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    uri = Uri.https('maps.apple.com', '/', {'q': label ?? query, if (hasPoint) 'll': query, if (!hasPoint) 'address': query});
  } else {
    uri = Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': query});
  }
  return launchUrl(uri, mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
}

/// Abre a rota até o destino no app de mapas (Google Maps na web): pelas coordenadas ou pelo endereço
Future<void> openDirections({double? latitude, double? longitude, String? address}) {
  final destination = latitude != null && longitude != null ? '$latitude,$longitude' : (address ?? '');
  final uri = Uri.https('www.google.com', '/maps/dir/', {'api': '1', 'destination': destination});
  return launchUrl(uri, mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
}

/// Liga para o número (tel:)
Future<void> callPhone(String phone) => launchUrl(Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^\d+]'), '')));

/// Abre a rota com várias paradas no app de mapas: as primeiras viram pontos de passagem e a última é o destino
Future<void> openRouteDirections(List<({double? latitude, double? longitude, String? address})> stops) {
  String point(({double? latitude, double? longitude, String? address}) s) =>
      s.latitude != null && s.longitude != null ? '${s.latitude},${s.longitude}' : (s.address ?? '');
  final points = stops.map(point).where((p) => p.isNotEmpty).toList();
  if (points.isEmpty) return Future.value();
  final query = {'api': '1', 'destination': points.last, 'travelmode': 'driving'};
  if (points.length > 1) query['waypoints'] = points.sublist(0, points.length - 1).join('|');
  final uri = Uri.https('www.google.com', '/maps/dir/', query);
  return launchUrl(uri, mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
}
