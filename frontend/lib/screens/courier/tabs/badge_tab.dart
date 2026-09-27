import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../../core/ui/ui.dart';
import '../../../services/courier_service.dart';
import '../../../utils/file_download.dart';
import '../../../widgets/courier/badge_pdf.dart';
import '../../../widgets/courier/verification_badge_card.dart';

/// Placa de verificação: pré-visualização, download em PDF/PNG e link do perfil público
class BadgeTab extends StatefulWidget {
  const BadgeTab({super.key});

  @override
  State<BadgeTab> createState() => _BadgeTabState();
}

class _BadgeTabState extends State<BadgeTab> {
  bool _exporting = false;

  String _fileName(VerificationBadgeData data, String ext) => 'placa-openbag-${data.slug}.$ext';

  Future<void> _export(VerificationBadgeData data, {required bool png}) async {
    setState(() => _exporting = true);
    try {
      final pdf = await buildBadgePdf(data);
      if (png) {
        downloadBytes(await badgePdfToPng(pdf), fileName: _fileName(data, 'png'), mimeType: 'image/png');
      } else {
        await Printing.sharePdf(bytes: pdf, filename: _fileName(data, 'pdf'));
      }
    } catch (e) {
      if (mounted) AppToast.show(context, message: 'Não foi possível gerar a placa', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _copyLink(VerificationBadgeData data) async {
    await Clipboard.setData(ClipboardData(text: data.publicUrl));
    if (mounted) AppToast.show(context, message: 'Link copiado', type: ToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<CourierService>().profile!;
    final data = VerificationBadgeData.fromProfile(profile);
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppSectionHeader(
                  title: 'Placa de verificação',
                  subtitle: 'Imprima e deixe na bag ou no baú. Quem ler o QR code, de qualquer celular, '
                      'vê o seu perfil público e a associação que confirma quem você é.',
                ),
                if (!data.verified)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AppCard(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: AppColors.warningLighter.withValues(alpha: 0.4),
                      child: Text(
                        'A placa só mostra "Entregador verificado" quando o seu vínculo com a associação está ativo.',
                        style: textTheme.bodyMedium,
                      ),
                    ),
                  ),
                if (profile.photoUrl == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text('Dica: adicione uma foto no seu perfil para ela aparecer na placa.',
                        style: textTheme.bodySmall),
                  ),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: VerificationBadgeCard(data: data),
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    AppButton(
                      text: 'Baixar PDF',
                      icon: Icons.picture_as_pdf_outlined,
                      isLoading: _exporting,
                      onPressed: _exporting ? null : () => _export(data, png: false),
                    ),
                    if (canDownloadFiles)
                      AppButton(
                        text: 'Baixar imagem (PNG)',
                        icon: Icons.image_outlined,
                        variant: ButtonVariant.outlined,
                        onPressed: _exporting ? null : () => _export(data, png: true),
                      ),
                    AppButton(
                      text: 'Copiar link',
                      icon: Icons.link,
                      variant: ButtonVariant.outlined,
                      onPressed: () => _copyLink(data),
                    ),
                    AppButton(
                      text: 'Abrir perfil público',
                      icon: Icons.open_in_new,
                      variant: ButtonVariant.text,
                      onPressed: () => context.push('/e/${data.slug}'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
