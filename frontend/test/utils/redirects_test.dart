import 'package:flutter_test/flutter_test.dart';
import 'package:open_bag/utils/redirects.dart';

void main() {
  test('só aceita caminhos do próprio app no ?next=', () {
    expect(safeNextPath('/checkout'), '/checkout');
    expect(safeNextPath('/pedidos/12?x=1'), '/pedidos/12?x=1');
    expect(safeNextPath('//site-malicioso.com'), isNull);
    expect(safeNextPath('https://site-malicioso.com'), isNull);
    expect(safeNextPath(null), isNull);
  });

  test('leva o ?next= adiante entre login e cadastro', () {
    expect(withNext('/registrar/usuario', '/checkout'), '/registrar/usuario?next=%2Fcheckout');
    expect(withNext('/login', null), '/login');
    expect(withNext('/login', 'https://x.com'), '/login');
  });
}
