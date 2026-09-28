import 'package:flutter_test/flutter_test.dart';
import 'package:open_bag/utils/formatters.dart';

void main() {
  test('percent without trailing zeros', () {
    expect(formatPercent(5), '5%');
    expect(formatPercent(10), '10%');
    expect(formatPercent(100), '100%');
    expect(formatPercent(2.5), '2,5%');
    expect(formatPercent(0.25), '0,25%');
  });

  test('delivery fee labels', () {
    expect(formatDeliveryFee(0), 'Grátis');
    expect(formatDeliveryFee(10, byDistance: true), startsWith('a partir de R\$'));
  });
}
