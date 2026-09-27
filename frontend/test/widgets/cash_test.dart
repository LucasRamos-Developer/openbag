import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_bag/core/ui/ui.dart';
import 'package:open_bag/models/cash/cash_report.dart';

void main() {
  test('saldo do acerto diz quem deve a quem', () {
    expect(settlementBalanceLabel(36), contains('Devolve'));
    expect(settlementBalanceLabel(36), contains('36,00'));
    expect(settlementBalanceLabel(-7), startsWith('Loja paga'));
    expect(settlementBalanceLabel(-7), contains('7,00'));
    expect(settlementBalanceLabel(0.001), 'Sem saldo');
  });

  testWidgets('AppStatTile mostra rótulo, valor e apoio', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 220,
          child: AppStatTile(label: 'Vendido', value: r'R$ 1.234,00', caption: 'Produtos e entrega', icon: Icons.payments),
        ),
      ),
    ));

    expect(find.text('Vendido'), findsOneWidget);
    expect(find.text(r'R$ 1.234,00'), findsOneWidget);
    expect(find.text('Produtos e entrega'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
