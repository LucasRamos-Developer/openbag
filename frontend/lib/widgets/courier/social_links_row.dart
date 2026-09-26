import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/courier/social_link.dart';

/// Redes sociais do entregador como chips clicáveis (abrem em nova aba)
class SocialLinksRow extends StatelessWidget {
  final List<SocialLink> links;

  const SocialLinksRow({super.key, required this.links});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final link in links)
          ActionChip(
            avatar: Icon(link.platform.icon, size: 18),
            label: Text(link.platform == SocialPlatform.OTHER ? link.displayUrl : link.platform.label),
            tooltip: link.displayUrl,
            onPressed: () => launchUrl(Uri.parse(link.url), webOnlyWindowName: '_blank'),
          ),
      ],
    );
  }
}
