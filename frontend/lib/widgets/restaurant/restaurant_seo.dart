import '../../constants/app_constants.dart';
import '../../models/menu/menu.dart';
import '../../models/restaurant.dart';
import '../../utils/page_meta_data.dart';

/// Título, descrição e dados estruturados (schema.org `Restaurant` com o cardápio) da página pública da loja.
///
/// [origin] é o endereço do site (ex: `https://openbag.app`), usado nas URLs absolutas do JSON-LD.
PageMetaData restaurantPageMeta(Restaurant restaurant, Menu menu, {required String origin}) {
  final address = restaurant.address;
  final city = address?.city;
  final path = '/r/${restaurant.slug}';
  final categories = restaurant.categories.take(2).join(' e ');

  final about = restaurant.description?.trim().isNotEmpty == true
      ? restaurant.description!.trim()
      : [categories.isEmpty ? 'Restaurante' : categories, if (city != null) 'em $city'].join(' ');
  final description = '${RegExp(r'[.!?]$').hasMatch(about) ? about : '$about.'} Veja o cardápio e peça pelo OpenBag.';

  return PageMetaData(
    title: city == null ? restaurant.name : '${restaurant.name} em $city',
    description: description,
    path: path,
    imageUrl: _absolute(restaurant.bannerUrl ?? restaurant.logoUrl),
    jsonLd: restaurantJsonLd(restaurant, menu, url: '$origin$path'),
  );
}

/// schema.org/Restaurant: o Google usa para mostrar endereço, horário, nota e cardápio no resultado da busca
Map<String, dynamic> restaurantJsonLd(Restaurant restaurant, Menu menu, {required String url}) {
  final address = restaurant.address;
  final image = _absolute(restaurant.bannerUrl ?? restaurant.logoUrl);
  return {
    '@context': 'https://schema.org',
    '@type': 'Restaurant',
    'name': restaurant.name,
    'url': url,
    if (restaurant.description?.trim().isNotEmpty == true) 'description': restaurant.description!.trim(),
    if (image != null) 'image': image,
    if (restaurant.phoneNumber != null) 'telephone': restaurant.phoneNumber,
    if (restaurant.categories.isNotEmpty) 'servesCuisine': restaurant.categories,
    if (restaurant.priceRange != null) 'priceRange': restaurant.priceRange,
    if (address != null)
      'address': {
        '@type': 'PostalAddress',
        'streetAddress': address.streetLine,
        'addressLocality': address.city,
        'addressRegion': address.state,
        if (address.zipCode.isNotEmpty) 'postalCode': address.zipCode,
        'addressCountry': 'BR',
      },
    if (address != null && address.hasLocation)
      'geo': {'@type': 'GeoCoordinates', 'latitude': address.latitude, 'longitude': address.longitude},
    // Só com avaliações de verdade: o Google recusa nota sem contagem
    if (restaurant.totalReviews > 0)
      'aggregateRating': {
        '@type': 'AggregateRating',
        'ratingValue': double.parse(restaurant.rating.toStringAsFixed(1)),
        'reviewCount': restaurant.totalReviews,
        'bestRating': 5,
        'worstRating': 1,
      },
    if (restaurant.openingHours.isNotEmpty)
      'openingHoursSpecification': [
        for (final hour in restaurant.openingHours)
          {
            '@type': 'OpeningHoursSpecification',
            'dayOfWeek': 'https://schema.org/${_weekdays[(hour.weekday - 1).clamp(0, 6)]}',
            'opens': _hhmm(hour.openTime),
            'closes': _hhmm(hour.closeTime),
          },
      ],
    'hasMenu': {
      '@type': 'Menu',
      'hasMenuSection': [
        for (final section in menu.sections.where((s) => s.active))
          {
            '@type': 'MenuSection',
            'name': section.name,
            if (section.description?.trim().isNotEmpty == true) 'description': section.description!.trim(),
            'hasMenuItem': [
              for (final item in section.items.where((i) => i.active))
                {
                  '@type': 'MenuItem',
                  'name': item.name,
                  if (item.description?.trim().isNotEmpty == true) 'description': item.description!.trim(),
                  'offers': {
                    '@type': 'Offer',
                    'price': item.currentPrice.toStringAsFixed(2),
                    'priceCurrency': 'BRL',
                    'availability': 'https://schema.org/${item.available ? 'InStock' : 'OutOfStock'}',
                  },
                },
              for (final combo in section.combos.where((c) => c.active))
                {
                  '@type': 'MenuItem',
                  'name': combo.name,
                  'description': combo.itemsSummary,
                  'offers': {'@type': 'Offer', 'price': combo.price.toStringAsFixed(2), 'priceCurrency': 'BRL'},
                },
            ],
          },
      ],
    },
  };
}

const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

/// "18:00:00" → "18:00"
String _hhmm(String time) => time.length >= 5 ? time.substring(0, 5) : time;

String? _absolute(String? path) {
  if (path == null || path.isEmpty) return null;
  return path.startsWith('http') ? path : AppConstants.fileUrl(path);
}
