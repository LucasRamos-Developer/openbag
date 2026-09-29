import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/geo.dart';
import 'api_client.dart';
import 'auth_service.dart';

/// De onde veio a localização usada na vitrine
enum CustomerLocationSource {
  gps('sua localização'),
  lastAddress('seu último endereço de entrega');

  final String label;
  const CustomerLocationSource(this.label);
}

/// Onde o cliente está, para ordenar a vitrine por proximidade.
///
/// Tenta o GPS do navegador; se ele for negado, usa o ponto do último endereço de entrega (guardado no
/// aparelho ao fazer um pedido ou, com login, o do último pedido). A posição fica só no aparelho.
class CustomerLocationService extends ChangeNotifier {
  static const _lastPointKey = 'last_delivery_point';

  final ApiClient _api;
  final AuthService _auth;

  CustomerLocationService(this._api, this._auth);

  GeoPoint? _origin;
  CustomerLocationSource? _source;
  bool _locating = false;

  GeoPoint? get origin => _origin;
  CustomerLocationSource? get source => _source;
  bool get locating => _locating;

  /// Guarda o ponto do endereço de um pedido feito (reserva para quando o GPS não estiver disponível)
  static Future<void> rememberDeliveryPoint(double? latitude, double? longitude) async {
    if (latitude == null || longitude == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPointKey, json.encode(GeoPoint(latitude, longitude).toJson()));
  }

  /// Dá para ordenar por proximidade? Não, só quando o GPS foi bloqueado de vez e não há endereço salvo
  Future<bool> isAvailable() async {
    if (_origin != null || await _savedPoint() != null || _auth.isAuthenticated) return true;
    try {
      return await Geolocator.checkPermission() != LocationPermission.deniedForever;
    } catch (_) {
      return false;
    }
  }

  /// Descobre a posição (GPS e, sem ele, o último endereço). Devolve false se nenhum dos dois funcionou.
  Future<bool> locate() async {
    if (_origin != null) return true;
    _locating = true;
    notifyListeners();
    try {
      final gps = await _gps();
      if (gps != null) {
        _set(gps, CustomerLocationSource.gps);
        return true;
      }
      final last = await _savedPoint() ?? await _lastOrderPoint();
      if (last != null) {
        _set(last, CustomerLocationSource.lastAddress);
        return true;
      }
      return false;
    } finally {
      _locating = false;
      notifyListeners();
    }
  }

  void _set(GeoPoint point, CustomerLocationSource source) {
    _origin = point;
    _source = source;
  }

  /// GPS sem avisos: a vitrine trata a falha voltando para o endereço salvo
  Future<GeoPoint?> _gps() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return null;
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      return GeoPoint(position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<GeoPoint?> _savedPoint() async {
    final raw = (await SharedPreferences.getInstance()).getString(_lastPointKey);
    if (raw == null) return null;
    try {
      return GeoPoint.fromJson(Map<String, dynamic>.from(json.decode(raw)));
    } catch (_) {
      return null;
    }
  }

  /// Com login, o ponto de entrega do pedido mais recente (ex: primeiro acesso em outro aparelho)
  Future<GeoPoint?> _lastOrderPoint() async {
    if (!_auth.isAuthenticated) return null;
    try {
      final data = await _api.get('/orders/mine', query: {'page': 0, 'size': 5});
      for (final order in (data['content'] as List? ?? [])) {
        final point = GeoPoint.fromJson({'latitude': order['deliveryLatitude'], 'longitude': order['deliveryLongitude']});
        if (point != null) return point;
      }
    } on ApiException catch (_) {
      // Sem pedidos acessíveis: fica sem reserva
    }
    return null;
  }
}
