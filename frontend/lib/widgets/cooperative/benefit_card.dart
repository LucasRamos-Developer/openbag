import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_constants.dart';
import '../../core/ui/ui.dart';
import '../../models/cooperative/community.dart';
import '../../utils/formatters.dart';

/// Convênio: parceiro, benefício em destaque e os atalhos de ligar, mapa e site.
/// No celular os atalhos viram botões grandes lado a lado.
class BenefitCard extends StatelessWidget {
  final Benefit benefit;
  final VoidCallback? onTap;

  /// Mostra a situação (ativo, vencido, desativado): painel do gestor
  final bool showStatus;

  const BenefitCard({super.key, required this.benefit, this.onTap, this.showStatus = false});

  Future<void> _open(Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final b = benefit;
    final logo = b.logoUrl;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      borderColor: colors.border,
      borderWidth: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 48,
                  height: 48,
                  color: colors.primary.withValues(alpha: 0.10),
                  child: logo != null
                      ? Image.network(AppConstants.fileUrl(logo), fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(b.category.icon, color: colors.primaryText))
                      : Icon(b.category.icon, color: colors.primaryText),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.partnerName, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    Text(b.category.label, style: TextStyle(color: colors.textMuted, fontSize: 13)),
                  ],
                ),
              ),
              if (showStatus)
                AppStatusChip(
                  label: !b.active ? 'Desativado' : (b.available ? 'Ativo' : 'Vencido'),
                  color: b.available ? AppColors.successDark : AppColors.grey600,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(b.headline, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: colors.primaryText)),
          if (b.description != null) ...[
            const SizedBox(height: 4),
            Text(b.description!, style: TextStyle(color: colors.textMuted)),
          ],
          if (b.validUntil != null) ...[
            const SizedBox(height: 6),
            Text('Válido até ${formatDate(b.validUntil)}', style: TextStyle(color: colors.textMuted, fontSize: 13)),
          ],
          if (b.address != null || b.phone != null || b.link != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (b.phone != null)
                  AppButton(
                    text: 'Ligar',
                    icon: Icons.call_outlined,
                    variant: ButtonVariant.outlined,
                    onPressed: () => _open(Uri(scheme: 'tel', path: b.phone!.replaceAll(RegExp(r'\D'), ''))),
                  ),
                if (b.address != null)
                  AppButton(
                    text: 'Mapa',
                    icon: Icons.map_outlined,
                    variant: ButtonVariant.outlined,
                    onPressed: () => _open(Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': b.address!})),
                  ),
                if (b.link != null)
                  AppButton(
                    text: 'Site',
                    icon: Icons.open_in_new,
                    variant: ButtonVariant.outlined,
                    onPressed: () => _open(Uri.parse(b.link!)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
