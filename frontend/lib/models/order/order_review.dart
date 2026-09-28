DateTime? _date(dynamic value) => value is String ? DateTime.tryParse(value) : null;

/// Avaliação do pedido feita pelo cliente (loja e, se houve entregador do app, entregador)
class OrderReview {
  final int restaurantRating;
  final String? restaurantComment;
  final int? courierRating;
  final String? courierComment;
  final String? restaurantReply;
  final DateTime? createdAt;

  const OrderReview({
    required this.restaurantRating,
    this.restaurantComment,
    this.courierRating,
    this.courierComment,
    this.restaurantReply,
    this.createdAt,
  });

  factory OrderReview.fromJson(Map<String, dynamic> json) => OrderReview(
        restaurantRating: json['restaurantRating'] ?? 0,
        restaurantComment: json['restaurantComment'],
        courierRating: json['courierRating'],
        courierComment: json['courierComment'],
        restaurantReply: json['restaurantReply'],
        createdAt: _date(json['createdAt']),
      );
}
