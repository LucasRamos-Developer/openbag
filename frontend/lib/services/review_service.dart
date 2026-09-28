import '../core/ui/ui.dart';
import '../models/order/order_review.dart';
import '../models/review/restaurant_review.dart';
import 'api_client.dart';

/// Avaliações: o cliente avalia o pedido entregue; a loja acompanha e responde
class ReviewService {
  final ApiClient _api;

  ReviewService(this._api);

  Future<OrderReview> reviewOrder(
    int orderId, {
    required int restaurantRating,
    String? restaurantComment,
    int? courierRating,
    String? courierComment,
  }) async =>
      OrderReview.fromJson(await _api.post('/orders/$orderId/review', data: {
        'restaurantRating': restaurantRating,
        'restaurantComment': restaurantComment,
        'courierRating': courierRating,
        'courierComment': courierComment,
      }));

  Future<AppPage<RestaurantReview>> restaurantReviews(int restaurantId, {int page = 0}) async => AppPage.fromJson(
        await _api.get('/restaurants/$restaurantId/reviews', query: {'page': page, 'size': 20}),
        RestaurantReview.fromJson,
      );

  Future<ReviewSummary> summary(int restaurantId) async =>
      ReviewSummary.fromJson(await _api.get('/restaurants/$restaurantId/reviews/summary'));

  Future<RestaurantReview> reply(int restaurantId, int reviewId, String reply) async => RestaurantReview.fromJson(
      await _api.post('/restaurants/$restaurantId/reviews/$reviewId/reply', data: {'reply': reply}));
}
