import 'package:flutter_test/flutter_test.dart';
import 'package:open_bag/models/association/association_report.dart';
import 'package:open_bag/models/courier/courier_work.dart';
import 'package:open_bag/models/order/order.dart';

void main() {
  Order order(List<Map<String, dynamic>>? incidents) => Order.fromJson({
        'id': 1,
        'orderNumber': 'OB-1',
        'status': 'OUT_FOR_DELIVERY',
        'restaurant': {'name': 'Loja'},
        'items': [],
        'timeline': [],
        'incidents': incidents,
      });

  test('o pedido da loja traz as ocorrências; o do cliente vem sem elas', () {
    final forStore = order([
      {'id': 7, 'type': 'CUSTOMER_NOT_FOUND', 'reportedBy': 'Ana', 'at': '2026-09-30T19:32:00'},
      {'id': 8, 'type': 'OTHER', 'note': 'Portão trancado'},
    ]);

    expect(forStore.incidents.map((i) => i.type), [IncidentType.CUSTOMER_NOT_FOUND, IncidentType.OTHER]);
    expect(forStore.incidents.first.title, 'Cliente não localizado');
    expect(forStore.incidents.last.title, 'Portão trancado', reason: 'em "outro", o título é a observação');
    expect(order(null).incidents, isEmpty);
  });

  test('tipo desconhecido vira "outro" em vez de quebrar a tela', () {
    expect(IncidentType.fromName('TIPO_NOVO'), IncidentType.OTHER);
  });

  test('a entrega do entregador lista o que ele já avisou', () {
    final delivery = CourierOrder.fromJson({
      'orderId': 1,
      'status': 'OUT_FOR_DELIVERY',
      'restaurant': {'id': 1, 'name': 'Loja'},
      'paymentMethod': 'CASH',
      'totalAmount': 32,
      'reportedIncidents': ['ORDER_NOT_READY'],
    });

    expect(delivery.reportedIncidents, {IncidentType.ORDER_NOT_READY});
  });

  test('o relatório da cooperativa lê as ocorrências por tipo e por loja', () {
    final incidents = AssociationIncidents.fromJson({
      'total': 3,
      'byType': [
        {'type': 'ORDER_NOT_READY', 'count': 2},
        {'type': 'WRONG_ADDRESS', 'count': 1},
      ],
      'byRestaurant': [
        {
          'restaurantId': 5,
          'name': 'Burger',
          'total': 3,
          'byType': [
            {'type': 'ORDER_NOT_READY', 'count': 2},
            {'type': 'WRONG_ADDRESS', 'count': 1},
          ],
        },
      ],
    });

    expect(incidents.total, 3);
    expect(incidents.byType.first, (type: IncidentType.ORDER_NOT_READY, count: 2));
    expect(incidents.byRestaurant.single.byType.last.type, IncidentType.WRONG_ADDRESS);
    expect(AssociationIncidents.fromJson(const {}).total, 0, reason: 'relatório de uma versão antiga do servidor');
  });
}
