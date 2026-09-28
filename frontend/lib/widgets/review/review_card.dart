import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../models/review/restaurant_review.dart';
import '../../services/review_service.dart';
import '../../utils/feedback.dart';
import '../../utils/formatters.dart';

/// Avaliação de um cliente no painel da loja, com a resposta (ou o botão para responder)
class ReviewCard extends StatefulWidget {
  final int restaurantId;
  final RestaurantReview review;

  const ReviewCard({super.key, required this.restaurantId, required this.review});

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  late RestaurantReview _review = widget.review;

  Future<void> _reply() async {
    final text = await AppDialog.reason(
      context,
      title: _review.reply == null ? 'Responder avaliação' : 'Editar resposta',
      message: 'O cliente vê a resposta no pedido dele.',
      confirmLabel: 'Enviar resposta',
      required: true,
    );
    if (text == null || text.trim().isEmpty || !mounted) return;
    await runWithFeedback(context, () async {
      final updated = await context.read<ReviewService>().reply(widget.restaurantId, _review.id, text.trim());
      if (mounted) setState(() => _review = updated);
    }, success: 'Resposta enviada');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final review = _review;

    return AppCard(
      padding: const EdgeInsets.all(16),
      borderColor: c.border,
      borderWidth: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppRatingStars(rating: review.rating.toDouble(), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  [review.customerName, if (review.orderCode != null) review.orderCode!, formatDateTime(review.createdAt)]
                      .join(' · '),
                  style: TextStyle(color: c.textMuted, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (review.comment != null) ...[
            const SizedBox(height: 8),
            Text(review.comment!, style: TextStyle(color: c.text)),
          ],
          const SizedBox(height: 12),
          if (review.reply != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Sua resposta',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: c.text)),
                      ),
                      AppButton(text: 'Editar', size: ButtonSize.small, variant: ButtonVariant.text, onPressed: _reply),
                    ],
                  ),
                  Text(review.reply!, style: TextStyle(color: c.text)),
                ],
              ),
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                text: 'Responder',
                icon: Icons.reply_outlined,
                size: ButtonSize.small,
                variant: ButtonVariant.outlined,
                onPressed: _reply,
              ),
            ),
        ],
      ),
    );
  }
}
