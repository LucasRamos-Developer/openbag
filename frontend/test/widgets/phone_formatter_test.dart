import 'package:flutter_test/flutter_test.dart';
import 'package:open_bag/utils/formatters.dart';

void main() {
  test('telefone fixo e celular', () {
    expect(PhoneFormatter.format('4733331234'), '(47) 3333-1234');
    expect(PhoneFormatter.format('(47) 3333-1234'), '(47) 3333-1234');
    expect(PhoneFormatter.format('47999998888'), '(47) 99999-8888');
    expect(PhoneFormatter.format('4799'), '(47) 99');
    expect(PhoneFormatter.format(''), '');
    expect(PhoneFormatter.format('479999988881234'), '(47) 99999-8888');
  });
}
