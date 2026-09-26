import 'package:url_launcher/url_launcher.dart';

/// Abre a rota até o destino no app de mapas (Google Maps na web): pelas coordenadas ou pelo endereço
Future<void> openDirections({double? latitude, double? longitude, String? address}) {
  final destination = latitude != null && longitude != null ? '$latitude,$longitude' : (address ?? '');
  final uri = Uri.https('www.google.com', '/maps/dir/', {'api': '1', 'destination': destination});
  return launchUrl(uri, mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
}

/// Liga para o número (tel:)
Future<void> callPhone(String phone) => launchUrl(Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^\d+]'), '')));
