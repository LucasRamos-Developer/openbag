import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/ui/ui.dart';
import '../../../services/restaurant_panel_service.dart';
import '../../../utils/formatters.dart';

/// Avaliações dos clientes: nota média, distribuição das notas e comentários.
/// A coleta de avaliações ainda não existe (Fase 5); por enquanto mostra o resumo e o estado vazio.
class ReviewsTab extends StatelessWidget {
  const ReviewsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RestaurantPanelService>().store!;

    return AppPageListView(
      children: [
        const AppSectionHeader(title: 'Avaliações', subtitle: 'O que os clientes acham dos seus pedidos'),
        LayoutBuilder(builder: (context, constraints) {
          final summary = _SummaryCard(rating: store.rating, total: store.totalReviews);
          // A distribuição por nota depende das avaliações individuais, que ainda não são coletadas
          const distribution = _DistributionCard(counts: null);
          if (constraints.maxWidth < 720) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [summary, const SizedBox(height: 16), distribution],
            );
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 300, child: summary),
                const SizedBox(width: 16),
                const Expanded(child: distribution),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        const AppPanelCard(
          title: 'Comentários',
          child: AppEmptyState(
            icon: Icons.rate_review_outlined,
            message: 'As avaliações dos clientes vão aparecer aqui.\n'
                'Depois de cada entrega, o cliente poderá dar uma nota e deixar um comentário.',
          ),
        ),
      ],
    );
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 1; i <= 5; i++)
                Icon(
                  hasReviews && rating >= i - 0.25
                      ? Icons.star_rounded
                      : (hasReviews && rating >= i - 0.75 ? Icons.star_half_rounded : Icons.star_outline_rounded),
                  color: c.rating,
                  size: 26,
                ),
            ],
          ),
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
  /// Quantidade de avaliações por nota (5 a 1); nula enquanto não há avaliações individuais
  final Map<int, int>? counts;

  const _DistributionCard({required this.counts});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final counts = this.counts;
    final total = counts?.values.fold(0, (sum, v) => sum + v) ?? 0;

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
                        value: counts == null || total == 0 ? 0 : counts[star]! / total,
                        minHeight: 8,
                        backgroundColor: c.surfaceAlt,
                        color: c.rating,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 32,
                    child: Text(counts == null ? '–' : formatCount(counts[star]!),
                        textAlign: TextAlign.end, style: TextStyle(color: c.textMuted)),
                  ),
                ],
              ),
            ),
          if (counts == null) ...[
            const SizedBox(height: 8),
            Text(
              'A distribuição por nota aparece quando os clientes começarem a avaliar pelo app.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textMuted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
