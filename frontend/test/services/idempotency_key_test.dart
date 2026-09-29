import 'package:flutter_test/flutter_test.dart';
import 'package:open_bag/services/api_client.dart';
import 'package:open_bag/services/idempotency_key.dart';

void main() {
  late IdempotencyKey key;
  late List<String> sent;

  setUp(() {
    key = IdempotencyKey();
    sent = [];
  });

  Future<void> attempt(Object payload, {ApiException? error}) async {
    try {
      await key.run(payload, (k) async {
        sent.add(k);
        if (error != null) throw error;
        return 'ok';
      });
    } on ApiException {
      // a tela mostraria o erro
    }
  }

  test('a nova tentativa depois de uma falha de rede usa a mesma chave', () async {
    await attempt({'total': 10}, error: ApiException('Erro de conexão'));
    await attempt({'total': 10});

    expect(sent, hasLength(2));
    expect(sent[1], sent[0]);
  });

  test('uma ação que deu certo faz a próxima ter chave nova', () async {
    await attempt({'total': 10});
    await attempt({'total': 10});

    expect(sent[1], isNot(sent[0]));
  });

  test('uma recusa do servidor faz a próxima tentativa ser uma ação nova', () async {
    await attempt({'total': 10}, error: ApiException('Loja fechada', statusCode: 400));
    await attempt({'total': 10});

    expect(sent[1], isNot(sent[0]));
  });

  test('ainda em andamento no servidor (409): mantém a chave', () async {
    await attempt({'total': 10}, error: ApiException('Em andamento', statusCode: 409));
    await attempt({'total': 10});

    expect(sent[1], sent[0]);
  });

  test('dados diferentes são outra ação', () async {
    await attempt({'total': 10}, error: ApiException('Erro de conexão'));
    await attempt({'total': 12});

    expect(sent[1], isNot(sent[0]));
  });
}
