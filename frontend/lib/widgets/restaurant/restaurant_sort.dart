import '../../models/restaurant.dart';

/// Ordenações da vitrine. Em todas, as lojas abertas vêm antes das fechadas.
enum RestaurantSort {
  recommended('Recomendados'),
  rating('Melhor avaliados'),
  fastest('Entrega mais rápida'),
  cheapestFee('Menor taxa de entrega'),
  lowestMinimum('Menor pedido mínimo');

  final String label;
  const RestaurantSort(this.label);

  /// Nova lista ordenada; "Recomendados" mantém a ordem do servidor (só sobe as abertas)
  List<Restaurant> apply(List<Restaurant> restaurants) {
    final sorted = [...restaurants];
    // sort do Dart não é estável: o índice original desempata
    final position = {for (var i = 0; i < restaurants.length; i++) restaurants[i]: i};
    sorted.sort((a, b) {
      if (a.openNow != b.openNow) return a.openNow ? -1 : 1;
      final byCriteria = _compare(a, b);
      return byCriteria != 0 ? byCriteria : position[a]!.compareTo(position[b]!);
    });
    return sorted;
  }

  int _compare(Restaurant a, Restaurant b) => switch (this) {
        recommended => 0,
        // Loja sem avaliação ("Novo") fica depois das avaliadas
        rating => _ratingOf(b).compareTo(_ratingOf(a)),
        fastest => (a.deliveryTimeMin + a.deliveryTimeMax).compareTo(b.deliveryTimeMin + b.deliveryTimeMax),
        cheapestFee => a.deliveryFee.compareTo(b.deliveryFee),
        lowestMinimum => a.minimumOrder.compareTo(b.minimumOrder),
      };

  static double _ratingOf(Restaurant r) => r.totalReviews > 0 ? r.rating : -1;
}
