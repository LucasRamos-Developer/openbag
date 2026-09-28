import 'package:flutter_test/flutter_test.dart';
import 'package:open_bag/utils/search.dart';

void main() {
  test('ignora maiúsculas e acentos', () {
    expect(matchesSearch('pizzaria', ['Pizzária do Zé']), isTrue);
    expect(matchesSearch('CAFÉ', ['cafe da esquina']), isTrue);
  });

  test('todas as palavras precisam aparecer em algum campo', () {
    expect(matchesSearch('burger centro', ['Burger da Vila', 'Centro']), isTrue);
    expect(matchesSearch('burger garcia', ['Burger da Vila', 'Centro']), isFalse);
  });

  test('busca vazia acha tudo e campos nulos são ignorados', () {
    expect(matchesSearch('  ', ['qualquer']), isTrue);
    expect(matchesSearch('velha', [null, 'Velha']), isTrue);
  });
}
