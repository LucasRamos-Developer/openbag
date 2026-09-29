import 'package:flutter_test/flutter_test.dart';
import 'package:open_bag/models/restaurant.dart';
import 'package:open_bag/utils/geo.dart';
import 'package:open_bag/widgets/restaurant/restaurant_sort.dart';

Restaurant _r(String name,
        {bool open = true,
        double rating = 0,
        int reviews = 0,
        double fee = 5,
        double minimum = 0,
        int time = 30,
        GeoPoint? at}) =>
    Restaurant(
      id: name.hashCode,
      name: name,
      slug: name,
      rating: rating,
      totalReviews: reviews,
      deliveryFee: fee,
      minimumOrder: minimum,
      deliveryTimeMin: time,
      deliveryTimeMax: time + 15,
      openNow: open,
      address: at == null
          ? null
          : Address(street: 'Rua', number: '1', neighborhood: 'Centro', city: 'Blumenau', state: 'SC', zipCode: '',
              latitude: at.latitude, longitude: at.longitude),
    );

List<String> _names(List<Restaurant> list) => list.map((r) => r.name).toList();

void main() {
  final closedCheap = _r('Fechada barata', open: false, fee: 0);
  final pricey = _r('Cara', fee: 9, rating: 4.9, reviews: 10, time: 50);
  final cheap = _r('Barata', fee: 2, minimum: 30, time: 20);
  final rated = _r('Avaliada', fee: 5, rating: 4.2, reviews: 3, minimum: 10);

  test('recomendados mantém a ordem do servidor, com as abertas primeiro', () {
    expect(_names(RestaurantSort.recommended.apply([closedCheap, pricey, cheap])), ['Cara', 'Barata', 'Fechada barata']);
  });

  test('menor taxa, com as fechadas no fim', () {
    expect(_names(RestaurantSort.cheapestFee.apply([pricey, closedCheap, rated, cheap])),
        ['Barata', 'Avaliada', 'Cara', 'Fechada barata']);
  });

  test('melhor avaliados deixa as lojas sem avaliação por último', () {
    expect(_names(RestaurantSort.rating.apply([cheap, rated, pricey])), ['Cara', 'Avaliada', 'Barata']);
  });

  test('entrega mais rápida e menor pedido mínimo', () {
    expect(_names(RestaurantSort.fastest.apply([pricey, rated, cheap])), ['Barata', 'Avaliada', 'Cara']);
    expect(_names(RestaurantSort.lowestMinimum.apply([cheap, rated, pricey])), ['Cara', 'Avaliada', 'Barata']);
  });

  test('mais perto usa a posição do cliente; loja sem localização e fechadas por último', () {
    const client = GeoPoint(-26.9194, -49.0661);
    final near = _r('Perto', at: const GeoPoint(-26.9200, -49.0670));
    final far = _r('Longe', at: const GeoPoint(-26.8500, -49.1000));
    final closedNear = _r('Fechada perto', open: false, at: const GeoPoint(-26.9195, -49.0662));
    final unknown = _r('Sem endereço');

    expect(_names(RestaurantSort.nearest.apply([unknown, far, closedNear, near], origin: client)),
        ['Perto', 'Longe', 'Sem endereço', 'Fechada perto']);
    // Sem a posição do cliente, fica na ordem do servidor
    expect(_names(RestaurantSort.nearest.apply([far, near])), ['Longe', 'Perto']);
    expect(RestaurantSort.distanceKm(far, client), closeTo(8.4, 0.3));
    expect(RestaurantSort.distanceKm(unknown, client), isNull);
  });
}
