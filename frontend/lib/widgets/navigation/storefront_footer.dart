import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_constants.dart';
import '../../core/ui/ui.dart';
import '../brand/openbag_logo.dart';
import 'storefront_scaffold.dart';

/// Rodapé das telas do cliente: marca e proposta, links para o cliente e para parceiros e contato.
///
/// Vai no fim da rolagem, ocupando a largura toda (o conteúdo interno segue a largura padrão).
/// Termina com [StorefrontScaffold.bottomInset], então o carrinho flutuante nunca cobre nada.
class StorefrontFooter extends StatelessWidget {
  static const contactEmail = 'lucasramos.developer@gmail.com';
  static const projectUrl = 'https://github.com/LucasRamos-Developer/openbag';

  const StorefrontFooter({super.key});

  /// Rodapé como último sliver de um `CustomScrollView`: em páginas curtas ele desce até o fim da tela.
  /// Em `AppPageListView`, passe `footer: const StorefrontFooter()`.
  static Widget sliver() => const SliverFillRemaining(
        hasScrollBody: false,
        fillOverscroll: false,
        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [StorefrontFooter()]),
      );

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      // Largura da tela (e não LayoutBuilder): o SliverFillRemaining mede a altura intrínseca do rodapé,
      // que o LayoutBuilder não informa. O rodapé sempre ocupa a largura toda.
      child: Builder(builder: (context) {
        final width = MediaQuery.sizeOf(context).width;
        final wide = width >= 800;
        final padding = AppLayout.contentPadding(
          width,
          top: 40,
          bottom: 24 + StorefrontScaffold.bottomInset(context),
        );

        final brand = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OpenBagLogo(),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Text(
                'Visibilidade para os pequenos negócios da sua cidade e apoio aos entregadores '
                'e cooperativas locais.',
                style: TextStyle(color: c.textMuted, fontSize: 13.5, height: 1.5),
              ),
            ),
          ],
        );
        final columns = [
          _FooterColumn(title: 'Para você', links: [
            _FooterLink('Restaurantes', () => context.go('/home')),
            _FooterLink('Meus pedidos', () => context.go('/pedidos')),
            _FooterLink('Minha conta', () => context.go('/profile')),
          ]),
          _FooterColumn(title: 'Para parceiros', links: [
            _FooterLink('Cadastre seu restaurante', () => context.push('/registrar/restaurante')),
            _FooterLink('Seja entregador', () => context.push('/registrar/entregador')),
            _FooterLink('Cadastre sua associação', () => context.push('/registrar/associacao')),
          ]),
          _FooterColumn(title: 'Contato', links: [
            _FooterLink(contactEmail, () => launchUrl(Uri(scheme: 'mailto', path: contactEmail))),
            _FooterLink('Projeto aberto no GitHub',
                () => launchUrl(Uri.parse(projectUrl), mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank')),
          ]),
        ];

        return Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: brand),
                    for (final column in columns) Expanded(child: column),
                  ],
                )
              else ...[
                brand,
                const SizedBox(height: 28),
                Wrap(spacing: 40, runSpacing: 24, children: columns),
              ],
              const SizedBox(height: 32),
              Divider(height: 1, color: c.border),
              const SizedBox(height: 16),
              Text(
                '© ${DateTime.now().year} OpenBag · versão ${AppConstants.appVersion}',
                style: TextStyle(color: c.textMuted, fontSize: 12.5),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _FooterLink {
  final String label;
  final VoidCallback onTap;

  const _FooterLink(this.label, this.onTap);
}

class _FooterColumn extends StatelessWidget {
  final String title;
  final List<_FooterLink> links;

  const _FooterColumn({required this.title, required this.links});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: TextStyle(color: c.text, fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        for (final link in links)
          InkWell(
            onTap: link.onTap,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(link.label, style: TextStyle(color: c.textMuted, fontSize: 13.5)),
            ),
          ),
      ],
    );
  }
}
