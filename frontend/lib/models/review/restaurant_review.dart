DateTime? _date(dynamic value) => value is String ? DateTime.tryParse(value) : null;

/// Avaliação vista pela loja (só a parte da loja; a nota do entregador não aparece)
class RestaurantReview {
  final int id;
  final String customerName;
  final String? orderCode;
  final int rating;
  final String? comment;
  final String? reply;
  final DateTime? repliedAt;
  final DateTime? createdAt;

  const RestaurantReview({
    required this.id,
    required this.customerName,
    this.orderCode,
    required this.rating,
    this.comment,
    this.reply,
    this.repliedAt,
    this.createdAt,
  });

  factory RestaurantReview.fromJson(Map<String, dynamic> json) => RestaurantReview(
        id: json['id'],
        customerName: json['customerName'] ?? 'Cliente',
        orderCode: json['orderCode'],
        rating: json['rating'] ?? 0,
        comment: json['comment'],
        reply: json['reply'],
        repliedAt: _date(json['repliedAt']),
        createdAt: _date(json['createdAt']),
      );
}

/// Resumo das avaliações: média, total e quantidade por nota
class ReviewSummary {
  final double average;
  final int total;

  /// Quantidade de notas 1, 2, 3, 4 e 5 (índice 0 = nota 1)
  final List<int> distribution;

  const ReviewSummary({required this.average, required this.total, required this.distribution});

  int countOf(int stars) => distribution[stars - 1];

  factory ReviewSummary.fromJson(Map<String, dynamic> json) => ReviewSummary(
        average: (json['average'] as num?)?.toDouble() ?? 0,
        total: json['total'] ?? 0,
        distribution: [for (final v in (json['distribution'] as List? ?? List.filled(5, 0))) (v as num).toInt()],
      );
}
