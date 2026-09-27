import 'package:url_launcher/url_launcher.dart';

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
