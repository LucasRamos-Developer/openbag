import 'package:flutter/foundation.dart';
import '../models/order/order.dart';
import 'alert_sound.dart';
import 'api_client.dart';
import 'idempotency_key.dart';
import 'realtime_service.dart';

/// Pedidos ativos de um restaurante em tempo real (gestor de pedidos e cozinha).
/// Carrega o quadro pelo REST, aplica os eventos do WebSocket e ressincroniza ao reconectar.
class RestaurantOrdersService extends ChangeNotifier {
  final ApiClient _api;
  final _storeOrderKey = IdempotencyKey();
  final RealtimeService _realtime;
  final AlertSound alertSound = AlertSound();

  RestaurantOrdersService(this._api, this._realtime) {
    _realtime.addListener(notifyListeners);
  }

  int? _restaurantId;
  int _attachments = 0;
  VoidCallback? _stopListening;
  final Map<int, Order> _orders = {};
  bool _isLoading = false;
  String? _error;

  /// Chamado quando um pedido é aceito (para imprimir a comanda automaticamente)
  void Function(Order order)? onAccepted;

  int? get restaurantId => _restaurantId;
  bool get connected => _realtime.connected;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Order> _byStatus(Set<OrderStatus> statuses) =>
      _orders.values.where((o) => statuses.contains(o.status)).toList()
        ..sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));

  /// Versão mais recente de um pedido do quadro (atualizada em tempo real)
  Order? byId(int id) => _orders[id];

  List<Order> get pending => _byStatus({OrderStatus.PENDING});
  List<Order> get confirmed => _byStatus({OrderStatus.CONFIRMED});
  List<Order> get preparing => _byStatus({OrderStatus.PREPARING});
  List<Order> get inKitchen => _byStatus({OrderStatus.CONFIRMED, OrderStatus.PREPARING});
  List<Order> get ready => _byStatus({OrderStatus.READY_FOR_PICKUP});
  List<Order> get outForDelivery => _byStatus({OrderStatus.OUT_FOR_DELIVERY});

  /// Começa a acompanhar o restaurante (contagem de referências: gestor e cozinha podem estar abertos)
  Future<void> attach(int restaurantId) async {
    if (_restaurantId != restaurantId) {
      _detachNow();
      _restaurantId = restaurantId;
      _attachments = 0;
    }
    _attachments++;
    if (_stopListening == null) {
      _stopListening = _realtime.listen(
        '/topic/restaurants/$restaurantId/orders',
        _onMessage,
        onReconnect: refresh,
      );
      await refresh();
    }
  }

  void detach() {
    if (--_attachments <= 0) _detachNow();
  }

  void _detachNow() {
    _stopListening?.call();
    _stopListening = null;
    _orders.clear();
    _attachments = 0;
    alertSound.stopRinging();
  }

  Future<void> refresh() async {
    final id = _restaurantId;
    if (id == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('/restaurants/$id/orders/board') as List;
      _orders
        ..clear()
        ..addEntries(data.map((e) => Order.fromJson(e)).map((o) => MapEntry(o.id, o)));
      _updateAlert();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _onMessage(Map<String, dynamic> message) {
    final order = Order.fromJson(message['order']);
    final previous = _orders[order.id];
    _upsert(order);
    // Pedido que acabou de ir para a cozinha (aceite automático ou aceito em outra tela) toca uma vez.
    // Quando a própria tela aceita, o pedido já está CONFIRMED localmente e não toca de novo.
    if (order.status == OrderStatus.CONFIRMED && previous?.status != OrderStatus.CONFIRMED) {
      alertSound.chime();
    }
  }

  void _upsert(Order order) {
    if (order.status.isFinal) {
      _orders.remove(order.id);
    } else {
      _orders[order.id] = order;
    }
    _updateAlert();
    notifyListeners();
  }

  /// Toca em repetição enquanto houver pedido aguardando aceite
  void _updateAlert() {
    if (pending.isNotEmpty) {
      alertSound.startRinging();
    } else {
      alertSound.stopRinging();
    }
  }

  Future<void> enableSound() async {
    await alertSound.unlock();
    _updateAlert();
    notifyListeners();
  }

  // ============= Ações =============

  Future<Order> perform(Order order, OrderAction action, {String? reason}) async {
    final data = await _api.post(
      '/restaurants/$_restaurantId/orders/${order.id}/${action.path}',
      data: action == OrderAction.reject ? {'reason': reason} : null,
    );
    final updated = Order.fromJson(data);
    _upsert(updated);
    if (action == OrderAction.accept) onAccepted?.call(updated);
    return updated;
  }

  /// Registra um pedido do balcão, telefone ou WhatsApp (entra já aceito)
  Future<Order> createStoreOrder(int restaurantId, Map<String, dynamic> body) async {
    final order = await _storeOrderKey.run(
        {'restaurantId': restaurantId, ...body},
        (key) async =>
            Order.fromJson(await _api.post('/restaurants/$restaurantId/orders', data: body, idempotencyKey: key)));
    if (restaurantId == _restaurantId) _upsert(order);
    return order;
  }

  /// Histórico do dia (padrão: hoje)
  Future<List<Order>> fetchHistory({DateTime? date, OrderStatus? status}) async {
    String two(int v) => v.toString().padLeft(2, '0');
    final day = date ?? DateTime.now();
    final data = await _api.get('/restaurants/$_restaurantId/orders', query: {
      'date': '${day.year}-${two(day.month)}-${two(day.day)}',
      'status': status?.name,
      'size': 100,
    });
    return (data['content'] as List).map((e) => Order.fromJson(e)).toList();
  }

  @override
  void dispose() {
    _realtime.removeListener(notifyListeners);
    _detachNow();
    alertSound.dispose();
    super.dispose();
  }
}
