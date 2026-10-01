import 'package:flutter_test/flutter_test.dart';
import 'package:open_bag/models/courier/courier_work.dart';
import 'package:open_bag/models/delivery/restaurant_delivery_settings.dart';
import 'package:open_bag/models/order/order.dart';

void main() {
  test('o cliente recebe o código só quando a loja exige', () {
    Order order(String? pin) => Order.fromJson({
          'id': 1,
          'orderNumber': 'OB-1',
          'status': 'OUT_FOR_DELIVERY',
          'restaurant': {'name': 'Loja'},
          'items': [],
          'timeline': [],
          'deliveryPin': pin,
        });

    expect(order('4821').deliveryPin, '4821');
    expect(order(null).deliveryPin, isNull);
  });

  test('a entrega diz ao entregador se precisa do código', () {
    CourierOrder delivery(bool? required) => CourierOrder.fromJson({
          'orderId': 1,
          'status': 'OUT_FOR_DELIVERY',
          'restaurant': {'id': 1, 'name': 'Loja'},
          'paymentMethod': 'CASH',
          'totalAmount': 38,
          'pinRequired': required,
        });

    expect(delivery(true).pinRequired, isTrue);
    expect(delivery(null).pinRequired, isFalse, reason: 'servidor antigo: confirmação simples');
  });

  test('a regra da loja vem desligada por padrão', () {
    expect(RestaurantDeliverySettings.fromJson({'courierPolicy': 'OPEN'}).requireDeliveryPin, isFalse);
    expect(RestaurantDeliverySettings.fromJson({'courierPolicy': 'OPEN', 'requireDeliveryPin': true}).requireDeliveryPin,
        isTrue);
  });
}
