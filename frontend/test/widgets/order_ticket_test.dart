import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_bag/models/order/order.dart';
import 'package:open_bag/widgets/order/order_ticket.dart';

void main() {
  test('comanda de 80mm gera um PDF válido com os dados do pedido', () async {
    final order = Order.fromJson({
      'id': 25,
      'orderNumber': 'OB-20260925-10-25',
      'displayCode': '#0025',
      'status': 'CONFIRMED',
      'restaurant': {'id': 10, 'name': 'Burger da Vila'},
      'customerName': 'Cliente Um',
      'customerPhone': '11900000201',
      'items': [
        {
          'name': 'X-Burger',
          'quantity': 2,
          'unitPrice': 33.9,
          'totalPrice': 67.8,
          'notes': 'sem cebola 🙏 por favor',
          'customizations': [
            {'groupName': 'Ponto da carne', 'optionName': 'Ao ponto', 'price': 0},
            {'groupName': 'Adicionais', 'optionName': 'Bacon', 'price': 6},
          ],
        },
        {'name': 'Combo X-Bacon + Suco', 'quantity': 1, 'unitPrice': 42, 'totalPrice': 42, 'customizations': []},
      ],
      'subtotal': 109.8,
      'deliveryFee': 5,
      'totalAmount': 114.8,
      'paymentMethod': 'CASH',
      'changeFor': 150,
      'deliveryAddress': 'Rua Augusta, 500 - Apto 12 - Consolação, São Paulo/SP (Ref.: Portão azul)',
      'notes': 'Interfone quebrado, ligar',
      'createdAt': '2026-09-25T16:35:00',
      'timeline': [],
    });

    final bytes = await buildOrderTicket(order, restaurantName: 'Burger da Vila');

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    final out = Platform.environment['TICKET_OUT'];
    if (out != null) File(out).writeAsBytesSync(bytes);
  });

  test('caracteres fora do Latin-1 viram "?" e acentos são preservados', () {
    expect(ticketSafe('sem cebola 🙏🙏 – ação'), 'sem cebola ? – ação');
  });
}
