import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/ui/ui.dart';
import '../../../models/review/restaurant_review.dart';
import '../../../services/restaurant_panel_service.dart';
import '../../../services/review_service.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/review/review_card.dart';

/// Avaliações dos clientes: nota média, distribuição das notas e comentários, com resposta da loja.
/// Só a parte da loja aparece aqui; a nota do entregador fica com ele.
class ReviewsTab extends StatefulWidget {
  const ReviewsTab({super.key});

  @override
  State<ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<ReviewsTab> {
  late final int _restaurantId = context.read<RestaurantPanelService>().selectedId!;
  late final Future<ReviewSummary> _summary = context.read<ReviewService>().summary(_restaurantId);

  @override
  Widget build(BuildContext context) {
    return AppPagedList<RestaurantReview>(
      title: 'Avaliações',
      subtitle: 'O que os clientes acham dos seus pedidos',
      header: FutureBuilder<ReviewSummary>(
        future: _summary,
        builder: (context, snapshot) => _SummaryRow(summary: snapshot.data),
      ),
      fetch: (_, page) => context.read<ReviewService>().restaurantReviews(_restaurantId, page: page),
      itemBuilder: (context, review) => ReviewCard(restaurantId: _restaurantId, review: review),
      emptyIcon: Icons.rate_review_outlined,
      emptyMessage: 'As avaliações dos clientes vão aparecer aqui.\n'
          'Depois de cada entrega, o cliente pode dar uma nota e deixar um comentário.',
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final ReviewSummary? summary;

  const _SummaryRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final summary = this.summary;
    return LayoutBuilder(builder: (context, constraints) {
      final card = _SummaryCard(rating: summary?.average ?? 0, total: summary?.total ?? 0);
      final distribution = _DistributionCard(summary: summary);
      if (constraints.maxWidth < 720) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [card, const SizedBox(height: 16), distribution],
        );
      }
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 300, child: card),
            const SizedBox(width: 16),
            Expanded(child: distribution),
          ],
        ),
      );
    });
  }
}

class _SummaryCard extends StatelessWidget {
  final double rating;
  final int total;

  const _SummaryCard({required this.rating, required this.total});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final hasReviews = total > 0;

    return AppCard(
      padding: const EdgeInsets.all(24),
      borderColor: c.border,
      borderWidth: 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            hasReviews ? rating.toStringAsFixed(1).replaceAll('.', ',') : '–',
            style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: c.text, height: 1.1),
          ),
          const SizedBox(height: 8),
          AppRatingStars(rating: hasReviews ? rating : 0, size: 26),
          const SizedBox(height: 8),
          Text(
            hasReviews ? '${formatCount(total)} ${total == 1 ? 'avaliação' : 'avaliações'}' : 'Ainda sem avaliações',
            style: TextStyle(color: c.textMuted),
          ),
        ],
      ),
    );
  }
}

class _DistributionCard extends StatelessWidget {
  /// Nulo enquanto carrega
  final ReviewSummary? summary;

  const _DistributionCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final summary = this.summary;
    final total = summary?.total ?? 0;

    return AppCard(
      padding: const EdgeInsets.all(24),
      borderColor: c.border,
      borderWidth: 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final star in [5, 4, 3, 2, 1])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(width: 14, child: Text('$star', style: const TextStyle(fontWeight: FontWeight.w700))),
                  const SizedBox(width: 4),
                  Icon(Icons.star_rounded, size: 18, color: c.rating),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: summary == null || total == 0 ? 0 : summary.countOf(star) / total,
                        minHeight: 8,
                        backgroundColor: c.surfaceAlt,
                        color: c.rating,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 32,
                    child: Text(summary == null ? '–' : formatCount(summary.countOf(star)),
                        textAlign: TextAlign.end, style: TextStyle(color: c.textMuted)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
