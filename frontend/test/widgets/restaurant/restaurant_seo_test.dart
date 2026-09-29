import 'package:flutter_test/flutter_test.dart';
import 'package:open_bag/models/menu/menu.dart';
import 'package:open_bag/models/store/store.dart';
import 'package:open_bag/models/restaurant.dart';
import 'package:open_bag/widgets/restaurant/restaurant_seo.dart';

Restaurant _restaurant({int reviews = 12}) => Restaurant(
      id: 1,
      name: 'Cantina Demo',
      slug: 'cantina-demo',
      rating: 4.83,
      totalReviews: reviews,
      deliveryFee: 6,
      minimumOrder: 25,
      deliveryTimeMin: 30,
      deliveryTimeMax: 45,
      openNow: true,
      phoneNumber: '4733330000',
      categories: const ['Comida caseira'],
      address: Address(
          street: 'Rua XV de Novembro', number: '1200', neighborhood: 'Centro', city: 'Blumenau', state: 'SC',
          zipCode: '89010-001', latitude: -26.9194, longitude: -49.0661),
      openingHours: [OpeningHour(weekday: 1, openTime: '11:00:00', closeTime: '15:00:00')],
    );

final _menu = Menu.fromJson({
  'restaurantId': 1,
  'unsectionedItems': [],
  'sections': [
    {
      'id': 1, 'name': 'Pratos do dia', 'description': 'Com arroz e feijão', 'position': 0, 'active': true,
      'combos': [],
      'items': [
        {'id': 1, 'sectionId': 1, 'name': 'Frango grelhado', 'price': 32.0, 'currentPrice': 32.0, 'available': true,
          'active': true, 'badges': [], 'customizationGroups': []},
        {'id': 2, 'sectionId': 1, 'name': 'Item oculto', 'price': 10.0, 'currentPrice': 10.0, 'available': true,
          'active': false, 'badges': [], 'customizationGroups': []},
      ],
    },
    {'id': 2, 'name': 'Seção oculta', 'position': 1, 'active': false, 'combos': [], 'items': []},
  ],
});

void main() {
  test('título, descrição e caminho da página da loja', () {
    final meta = restaurantPageMeta(_restaurant(), _menu, origin: 'https://openbag.app');

    expect(meta.fullTitle, 'Cantina Demo em Blumenau · OpenBag');
    expect(meta.description, 'Comida caseira em Blumenau. Veja o cardápio e peça pelo OpenBag.');
    expect(meta.path, '/r/cantina-demo');
    expect(meta.jsonLd!['url'], 'https://openbag.app/r/cantina-demo');
  });

  test('JSON-LD de restaurante com endereço, horário, nota e só o cardápio visível', () {
    final ld = restaurantJsonLd(_restaurant(), _menu, url: 'https://openbag.app/r/cantina-demo');

    expect(ld['@type'], 'Restaurant');
    expect(ld['address']['addressLocality'], 'Blumenau');
    expect(ld['geo']['latitude'], -26.9194);
    expect(ld['aggregateRating']['ratingValue'], 4.8);
    expect(ld['aggregateRating']['reviewCount'], 12);
    expect(ld['openingHoursSpecification'][0],
        containsPair('dayOfWeek', 'https://schema.org/Monday'));
    expect(ld['openingHoursSpecification'][0]['opens'], '11:00');

    final sections = ld['hasMenu']['hasMenuSection'] as List;
    expect(sections, hasLength(1));
    final items = sections.first['hasMenuItem'] as List;
    expect(items.map((i) => i['name']), ['Frango grelhado']);
    expect(items.first['offers']['price'], '32.00');
  });

  test('sem avaliações, não publica nota', () {
    expect(restaurantJsonLd(_restaurant(reviews: 0), _menu, url: 'x').containsKey('aggregateRating'), isFalse);
  });
}
