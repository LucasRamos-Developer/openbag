import 'package:flutter_test/flutter_test.dart';
import 'package:open_bag/models/order/order.dart';

Order _order({required String status, String? channel, String? fulfillment}) => Order.fromJson({
      'id': 1,
      'orderNumber': 'OB-1',
      'status': status,
      'channel': channel,
      'fulfillment': fulfillment,
      'restaurant': {'name': 'Loja'},
      'items': [],
      'timeline': [],
    });

void main() {
  test('pedido antigo, sem origem, é do app e de entrega', () {
    final order = _order(status: 'READY_FOR_PICKUP');

    expect(order.channel, OrderChannel.APP);
    expect(order.fromStore, isFalse);
    expect(order.isPickup, isFalse);
    expect(OrderAction.nextFor(order), OrderAction.dispatch);
  });

  test('retirada pronta vai direto para "cliente retirou", sem entregador', () {
    final order = _order(status: 'READY_FOR_PICKUP', channel: 'COUNTER', fulfillment: 'PICKUP');

    expect(order.fromStore, isTrue);
    expect(OrderAction.nextFor(order), OrderAction.collect);
    expect(OrderAction.collect.path, 'deliver');
    expect(order.awaitingCourier, isFalse);
    expect(order.beforePickup, isFalse);
  });

  test('pedido de telefone para entrega procura entregador como os do app', () {
    final order = _order(status: 'PREPARING', channel: 'PHONE', fulfillment: 'DELIVERY');

    expect(order.awaitingCourier, isTrue);
    expect(OrderAction.nextFor(order), OrderAction.ready);
  });
}
