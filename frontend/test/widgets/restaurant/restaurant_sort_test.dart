import 'package:flutter_test/flutter_test.dart';
import 'package:open_bag/models/restaurant.dart';
import 'package:open_bag/widgets/restaurant/restaurant_sort.dart';

Restaurant _r(String name,
        {bool open = true, double rating = 0, int reviews = 0, double fee = 5, double minimum = 0, int time = 30}) =>
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
}
