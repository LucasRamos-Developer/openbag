import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_bag/widgets/menu/price_text.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: child))));

  testWidgets('em promoção, o preço antigo riscado vem à esquerda e menor', (tester) async {
    await pump(tester, const PriceText(price: 32.9, promotionalPrice: 27.9, style: TextStyle(fontSize: 20)));

    final old = find.textContaining('32,90');
    final current = find.textContaining('27,90');
    expect(tester.getTopLeft(old).dx, lessThan(tester.getTopLeft(current).dx));

    final oldStyle = tester.widget<Text>(old).style!;
    expect(oldStyle.decoration, TextDecoration.lineThrough);
    expect(oldStyle.fontSize, lessThan(20));
  });

  testWidgets('sem promoção mostra só o preço', (tester) async {
    await pump(tester, const PriceText(price: 36, promotionalPrice: 40));

    expect(find.textContaining('36,00'), findsOneWidget);
    expect(find.textContaining('40,00'), findsNothing);
  });
}
