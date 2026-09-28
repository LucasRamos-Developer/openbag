import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/order/order.dart';
import '../../utils/formatters.dart';

/// No pedido entregue: convite para avaliar (enquanto dá) ou a avaliação já feita, com a resposta da loja
class OrderReviewCard extends StatelessWidget {
  final Order order;
  final VoidCallback onReview;

  const OrderReviewCard({super.key, required this.order, required this.onReview});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final review = order.review;

    if (review == null) {
      return AppCard(
        padding: const EdgeInsets.all(16),
        borderColor: c.border,
        borderWidth: 1,
        child: Row(
          children: [
            Icon(Icons.star_rounded, color: c.rating, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Avalie seu pedido', style: TextStyle(fontWeight: FontWeight.w700, color: c.text)),
                  Text('Até ${formatDate(order.reviewableUntil)}', style: TextStyle(color: c.textMuted, fontSize: 13)),
                ],
              ),
            ),
            AppButton(text: 'Avaliar', size: ButtonSize.small, onPressed: onReview),
          ],
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(16),
      borderColor: c.border,
      borderWidth: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sua avaliação', style: TextStyle(fontWeight: FontWeight.w700, color: c.text)),
          const SizedBox(height: 8),
          _Line(label: order.restaurant.name, rating: review.restaurantRating, comment: review.restaurantComment),
          if (review.courierRating != null && order.courier != null) ...[
            const SizedBox(height: 8),
            _Line(label: order.courier!.fullName, rating: review.courierRating!, comment: review.courierComment),
          ],
          if (review.restaurantReply != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Resposta da loja', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: c.text)),
                  const SizedBox(height: 4),
                  Text(review.restaurantReply!, style: TextStyle(color: c.text)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final int rating;
  final String? comment;

  const _Line({required this.label, required this.rating, this.comment});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(color: c.text), overflow: TextOverflow.ellipsis)),
            AppRatingStars(rating: rating.toDouble(), size: 18),
          ],
        ),
        if (comment != null) Text('“$comment”', style: TextStyle(color: c.textMuted, fontSize: 13)),
      ],
    );
  }
}
