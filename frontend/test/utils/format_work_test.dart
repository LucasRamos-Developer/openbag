import 'package:flutter_test/flutter_test.dart';
import 'package:open_bag/utils/formatters.dart';

void main() {
  test('km somados ficam sempre em km, com uma casa', () {
    expect(formatKm(0), '0,0 km');
    expect(formatKm(0.4), '0,4 km');
    expect(formatKm(12.35), '12,3 km');
  });

  test('duração em minutos e horas', () {
    expect(formatMinutes(0), '0 min');
    expect(formatMinutes(45), '45 min');
    expect(formatMinutes(180), '3 h');
    expect(formatMinutes(185), '3 h 05');
  });
}
