import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/courier/courier_work.dart';
import 'alert_sound.dart';
import 'api_client.dart';
import 'realtime_service.dart';

/// Localização indisponível (sem permissão ou GPS desligado)
class LocationUnavailable implements Exception {
  final String message;
  LocationUnavailable(this.message);

  @override
  String toString() => message;
}

/// Trabalho do entregador em tempo real: online/offline, check-in, ofertas (com alerta sonoro) e a entrega
/// em andamento. Enquanto ele trabalha, envia a localização a cada ~20 s e mantém a tela acesa.
class CourierWorkService extends ChangeNotifier {
  static const _base = '/me/courier/work';
  static const _locationInterval = Duration(seconds: 20);

  final ApiClient _api;
  final RealtimeService _realtime;
  final AlertSound alertSound = AlertSound();

  CourierWorkService(this._api, this._realtime) {
    _realtime.addListener(notifyListeners);
  }

  CourierWorkState? _state;
  bool _isLoading = false;
  String? _error;
  String? _notice;
  int _attachments = 0;
  VoidCallback? _stopListening;
  int? _listeningTo;
  StreamSubscription<Position>? _positionSub;
  Timer? _heartbeat;
  Timer? _offerExpiry;
  Position? _lastPosition;

  CourierWorkState? get state => _state;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get connected => _realtime.connected;

  /// Aviso para mostrar uma vez (ex: "o tempo para aceitar acabou"); lido com [takeNotice]
  String? takeNotice() {
    final notice = _notice;
    _notice = null;
    return notice;
  }

  // ============= Ciclo de vida =============

  Future<void> attach() async {
    _attachments++;
    if (_attachments == 1) await refresh();
  }

  void detach() {
    if (--_attachments > 0) return;
    _attachments = 0;
    _stopListening?.call();
    _stopListening = null;
    _listeningTo = null;
    _stopTracking();
    alertSound.stopRinging();
    _offerExpiry?.cancel();
    _state = null;
  }

  Future<void> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _apply(CourierWorkState.fromJson(await _api.get(_base)));
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Aplica o estado vindo do servidor e ajusta tempo real, localização, tela acesa e alerta
  void _apply(CourierWorkState state) {
    _state = state;
    if (_listeningTo != state.deliveryPersonId) {
      _stopListening?.call();
      _listeningTo = state.deliveryPersonId;
      _stopListening = _realtime.listen('/topic/couriers/${state.deliveryPersonId}', _onMessage, onReconnect: refresh);
    }
    if (state.isWorking) {
      _startTracking();
    } else {
      _stopTracking();
    }
    _syncOfferAlert();
    notifyListeners();
  }

  void _onMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;
    final current = _state;
    if (current == null) return;

    switch (type) {
      case 'OFFER_CREATED':
        _state = _copyWith(current, pendingOffer: CourierOffer.fromJson(message['offer']));
        _syncOfferAlert();
        notifyListeners();
      case 'OFFER_CLOSED':
        final offerId = (message['offer'] as Map?)?['offerId'];
        if (current.pendingOffer?.offerId == offerId) {
          _notice = message['reason'] as String?;
          _state = _copyWith(current, clearOffer: true);
          _syncOfferAlert();
          notifyListeners();
        }
      default:
        // Mudanças na entrega ou no turno: recarrega o estado completo (ganhos, entrega, situação)
        if (type == 'ORDER_CANCELLED' || type == 'STATE_CHANGED') _notice = message['reason'] as String?;
        refresh();
    }
  }

  CourierWorkState _copyWith(CourierWorkState s, {CourierOffer? pendingOffer, bool clearOffer = false}) => CourierWorkState(
        deliveryPersonId: s.deliveryPersonId,
        workStatus: s.workStatus,
        shift: s.shift,
        pendingOffer: clearOffer ? null : (pendingOffer ?? s.pendingOffer),
        activeOrder: s.activeOrder,
        earnedToday: s.earnedToday,
        deliveriesToday: s.deliveriesToday,
        blockers: s.blockers,
      );

  /// Toca enquanto houver oferta pendente e para quando ela expira
  void _syncOfferAlert() {
    _offerExpiry?.cancel();
    final offer = _state?.pendingOffer;
    if (offer == null) {
      alertSound.stopRinging();
      return;
    }
    alertSound.startRinging();
    final left = offer.expiresAt.difference(DateTime.now());
    _offerExpiry = Timer(left.isNegative ? Duration.zero : left, () {
      alertSound.stopRinging();
      notifyListeners();
    });
  }

  // ============= Localização =============

  /// Posição atual, pedindo permissão se preciso
  Future<Position> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationUnavailable('Ative a localização do aparelho para trabalhar');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw LocationUnavailable('Permita o acesso à localização para receber entregas por perto');
    }
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 20),
    );
    _lastPosition = position;
    return position;
  }

  void _startTracking() {
    WakelockPlus.enable().catchError((_) {});
    _positionSub ??= Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 30),
    ).listen((position) => _lastPosition = position, onError: (_) {});
    // Envia periodicamente mesmo parado: sem sinal por muito tempo o servidor deixa de oferecer entregas
    _heartbeat ??= Timer.periodic(_locationInterval, (_) => _sendLocation());
  }

  void _stopTracking() {
    _positionSub?.cancel();
    _positionSub = null;
    _heartbeat?.cancel();
    _heartbeat = null;
    WakelockPlus.disable().catchError((_) {});
  }

  Future<void> _sendLocation() async {
    final position = _lastPosition;
    if (position == null) return;
    try {
      await _api.put('$_base/location', data: _coords(position));
    } on ApiException {
      // Tenta de novo no próximo ciclo
    }
  }

  static Map<String, dynamic> _coords(Position p) => {'latitude': p.latitude, 'longitude': p.longitude};

  // ============= Ações =============

  Future<void> _action(Future<dynamic> Function() request) async {
    _apply(CourierWorkState.fromJson(await request()));
  }

  Future<void> goOnline() async {
    await alertSound.unlock();
    final position = await currentPosition();
    await _action(() => _api.post('$_base/online', data: _coords(position)));
  }

  Future<void> goOffline() => _action(() => _api.post('$_base/offline'));

  Future<void> checkIn(int restaurantId) async {
    await alertSound.unlock();
    final position = await currentPosition();
    await _action(() => _api.post('$_base/checkin/$restaurantId', data: _coords(position)));
  }

  Future<void> checkOut() => _action(() => _api.post('$_base/checkout'));

  Future<void> acceptOffer(CourierOffer offer) => _action(() => _api.post('$_base/offers/${offer.offerId}/accept'));

  Future<void> declineOffer(CourierOffer offer) => _action(() => _api.post('$_base/offers/${offer.offerId}/decline'));

  Future<void> pickUp(CourierOrder order) => _action(() => _api.post('$_base/orders/${order.orderId}/pickup'));

  Future<void> deliver(CourierOrder order) => _action(() => _api.post('$_base/orders/${order.orderId}/deliver'));

  @override
  void dispose() {
    _realtime.removeListener(notifyListeners);
    detach();
    alertSound.dispose();
    super.dispose();
  }
}
