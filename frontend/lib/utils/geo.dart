import 'dart:math' as math;

/// Ponto no mapa
class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint(this.latitude, this.longitude);

  Map<String, dynamic> toJson() => {'latitude': latitude, 'longitude': longitude};

  static GeoPoint? fromJson(Map<String, dynamic>? json) {
    final lat = (json?['latitude'] as num?)?.toDouble();
    final lng = (json?['longitude'] as num?)?.toDouble();
    return lat == null || lng == null ? null : GeoPoint(lat, lng);
  }
}

/// Distância em linha reta entre dois pontos, em km (a mesma conta do backend, `GeoUtils.haversineKm`)
double haversineKm(GeoPoint a, GeoPoint b) {
  const earthRadiusKm = 6371.0;
  double rad(double degrees) => degrees * math.pi / 180;
  final dLat = rad(b.latitude - a.latitude);
  final dLng = rad(b.longitude - a.longitude);
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(a.latitude)) * math.cos(rad(b.latitude)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * earthRadiusKm * math.asin(math.sqrt(h));
}
