import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../constants/app_constants.dart';
import 'auth_service.dart';

/// Ouvinte de um tópico: recebe as mensagens e é avisado quando a conexão volta
/// (para ressincronizar pelo REST o que pode ter sido perdido offline)
class _TopicListener {
  final void Function(Map<String, dynamic> message) onMessage;
  final VoidCallback? onReconnect;

  _TopicListener(this.onMessage, this.onReconnect);
}

/// Conexão WebSocket (STOMP) única do app, autenticada com o token do usuário.
/// Conecta sob demanda quando alguém escuta um tópico, reconecta sozinha e
/// desconecta quando ninguém mais escuta ou o usuário sai.
class RealtimeService extends ChangeNotifier {
  final AuthService _auth;

  RealtimeService(this._auth) {
    _lastToken = _auth.token;
    _auth.addListener(_onAuthChanged);
  }

  StompClient? _client;
  String? _lastToken;
  bool _connected = false;
  bool _everConnected = false;
  final Map<String, List<_TopicListener>> _listeners = {};
  final Map<String, StompUnsubscribe> _subscriptions = {};

  bool get connected => _connected;

  static String get _url => '${AppConstants.baseUrl.replaceFirst(RegExp(r'^http'), 'ws')}/ws';

  /// Escuta um tópico. Retorna a função para parar de escutar.
  VoidCallback listen(String topic, void Function(Map<String, dynamic>) onMessage, {VoidCallback? onReconnect}) {
    final listener = _TopicListener(onMessage, onReconnect);
    _listeners.putIfAbsent(topic, () => []).add(listener);
    _ensureClient();
    if (_connected) _subscribe(topic);

    return () {
      final list = _listeners[topic];
      list?.remove(listener);
      if (list != null && list.isEmpty) {
        _listeners.remove(topic);
        _subscriptions.remove(topic)?.call();
      }
      if (_listeners.isEmpty) _disconnect();
    };
  }

  void _ensureClient() {
    if (_client != null || _auth.token == null) return;
    _client = StompClient(
      config: StompConfig(
        url: _url,
        stompConnectHeaders: {'Authorization': 'Bearer ${_auth.token}'},
        reconnectDelay: const Duration(seconds: 3),
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
        onConnect: _onConnect,
        onDisconnect: (_) => _setConnected(false),
        onWebSocketDone: () => _setConnected(false),
        onWebSocketError: (_) => _setConnected(false),
        onStompError: (frame) => debugPrint('STOMP: ${frame.headers['message']}'),
      ),
    )..activate();
  }

  void _onConnect(StompFrame _) {
    _subscriptions.clear();
    _setConnected(true);
    for (final topic in _listeners.keys) {
      _subscribe(topic);
    }
    // Na reconexão, quem escuta recarrega o estado (eventos perdidos enquanto offline)
    if (_everConnected) {
      for (final listener in _listeners.values.expand((l) => l).toList()) {
        listener.onReconnect?.call();
      }
    }
    _everConnected = true;
  }

  void _subscribe(String topic) {
    if (_subscriptions.containsKey(topic) || _client == null) return;
    _subscriptions[topic] = _client!.subscribe(
      destination: topic,
      callback: (frame) {
        if (frame.body == null) return;
        final message = json.decode(frame.body!) as Map<String, dynamic>;
        for (final listener in List.of(_listeners[topic] ?? const <_TopicListener>[])) {
          listener.onMessage(message);
        }
      },
    );
  }

  void _setConnected(bool value) {
    if (_connected == value) return;
    _connected = value;
    notifyListeners();
  }

  void _disconnect() {
    _client?.deactivate();
    _client = null;
    _subscriptions.clear();
    _everConnected = false;
    _setConnected(false);
  }

  /// Token mudou (login/logout): reconecta com a nova identidade
  void _onAuthChanged() {
    if (_auth.token == _lastToken) return;
    _lastToken = _auth.token;
    _disconnect();
    if (_auth.token == null) {
      _listeners.clear();
    } else if (_listeners.isNotEmpty) {
      _ensureClient();
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _disconnect();
    super.dispose();
  }
}
