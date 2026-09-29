import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'api_client.dart';

/// Chave de idempotência de uma ação do usuário (finalizar o pedido, acertar o caixa, aceitar uma oferta...).
///
/// Enquanto a ação não tiver resposta do servidor (timeout, rede caiu), a nova tentativa com os mesmos dados usa a
/// mesma chave: se a primeira chegou a ser gravada, o servidor devolve o mesmo resultado em vez de repetir a ação.
/// Quando o servidor responde (deu certo ou recusou), a próxima tentativa é uma ação nova, com chave nova.
class IdempotencyKey {
  static const _uuid = Uuid();

  String? _key;
  String? _payload;

  /// Roda [action] com a chave desta tentativa
  Future<T> run<T>(Object? payload, Future<T> Function(String key) action) async {
    final encoded = jsonEncode(payload);
    if (_key == null || encoded != _payload) {
      _key = _uuid.v4();
      _payload = encoded;
    }
    try {
      final result = await action(_key!);
      _reset();
      return result;
    } on ApiException catch (e) {
      // Sem resposta (null) ou ainda em andamento (409): a próxima tentativa precisa da mesma chave
      if (e.statusCode != null && e.statusCode != 409) _reset();
      rethrow;
    }
  }

  void _reset() {
    _key = null;
    _payload = null;
  }
}
