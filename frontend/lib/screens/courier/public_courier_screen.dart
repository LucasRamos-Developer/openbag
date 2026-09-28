import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../models/courier/courier_public.dart';
import '../../services/api_client.dart';
import '../../services/courier_service.dart';
import '../../widgets/courier/social_links_row.dart';
import '../../widgets/courier/work_history_list.dart';
import '../../widgets/courier/verification_badge_card.dart';
import '../../widgets/navigation/storefront_footer.dart';
import '../../widgets/navigation/storefront_scaffold.dart';

/// Perfil público do entregador (/e/:slug), aberto pelo QR code da placa de verificação. Não exige login.
class PublicCourierScreen extends StatefulWidget {
  final String slug;

  const PublicCourierScreen({super.key, required this.slug});

  @override
  State<PublicCourierScreen> createState() => _PublicCourierScreenState();
}

class _PublicCourierScreenState extends State<PublicCourierScreen> {
  late Future<CourierPublic> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<CourierService>().fetchPublicProfile(widget.slug);
  }

  @override
  Widget build(BuildContext context) {
    return StorefrontScaffold(
      title: 'Perfil do entregador',
      maxWidth: 480,
      body: FutureBuilder<CourierPublic>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            final notFound = error is ApiException && error.statusCode == 404;
            return AppEmptyState(
              icon: notFound ? Icons.person_off_outlined : Icons.cloud_off_outlined,
              message: notFound
                  ? 'Não encontramos este entregador. Confira se o QR code é de uma placa OpenBag.'
                  : 'Não foi possível carregar o perfil.',
              actionLabel: notFound ? null : 'Tentar novamente',
              onAction: notFound ? null : () => setState(_load),
            );
          }
          return _PublicProfileBody(courier: snapshot.data!);
        },
      ),
    );
  }
}

class _PublicProfileBody extends StatelessWidget {
  final CourierPublic courier;

  const _PublicProfileBody({required this.courier});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppPageListView(
      maxWidth: 480,
      top: 16,
      footer: const StorefrontFooter(),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VerificationBadgeCard(data: VerificationBadgeData.fromPublic(courier), showQrCode: false),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _Stat(value: '${courier.totalDeliveries}', label: 'entregas')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Stat(
                        value: courier.totalReviews > 0 ? courier.rating.toStringAsFixed(1).replaceAll('.', ',') : '–',
                        label: courier.totalReviews > 0
                            ? '${courier.totalReviews} ${courier.totalReviews == 1 ? 'avaliação' : 'avaliações'}'
                            : 'sem avaliações',
                        icon: Icons.star_rounded,
                      ),
                    ),
                  ],
                ),
                if (courier.bio != null) ...[
                  const SizedBox(height: 24),
                  Text('Sobre', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(courier.bio!, style: textTheme.bodyLarge),
                ],
                if (courier.socialLinks.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  SocialLinksRow(links: courier.socialLinks),
                ],
                if (courier.workHistory.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Onde já trabalhou', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  WorkHistoryList(restaurants: courier.workHistory),
                ],
                const SizedBox(height: 24),
                Text(
                  courier.association?.verified == true
                      ? 'A identidade deste entregador é confirmada pela associação ${courier.association!.name}.'
                      : 'Este entregador ainda não tem vínculo ativo com uma associação.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;

  const _Stat({required this.value, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) Icon(icon, color: AppColors.warningDark, size: 22),
              Text(value, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          Text(label, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}
