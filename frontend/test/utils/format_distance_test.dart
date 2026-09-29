import 'package:flutter_test/flutter_test.dart';
import 'package:open_bag/utils/formatters.dart';

void main() {
  test('menos de 100 m, metros abaixo de 1 km e km com uma casa acima', () {
    expect(formatDistance(0.004), 'menos de 100 m');
    expect(formatDistance(0.123), '120 m');
    expect(formatDistance(0.456), '460 m');
    expect(formatDistance(1.0), '1,0 km');
    expect(formatDistance(8.43), '8,4 km');
  });
}
