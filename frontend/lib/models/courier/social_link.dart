import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

enum SocialPlatform {
  INSTAGRAM('Instagram', 'instagram.com/seu.perfil'),
  FACEBOOK('Facebook', 'facebook.com/seu.perfil'),
  TIKTOK('TikTok', 'tiktok.com/@seu.perfil'),
  WHATSAPP('WhatsApp', '(11) 98765-4321'),
  YOUTUBE('YouTube', 'youtube.com/@seu.canal'),
  WEBSITE('Site', 'seusite.com.br'),
  OTHER('Outro', 'link');

  final String label;
  final String hint;
  const SocialPlatform(this.label, this.hint);

  IconData get icon => switch (this) {
        INSTAGRAM => MdiIcons.instagram,
        FACEBOOK => MdiIcons.facebook,
        TIKTOK => MdiIcons.musicNote,
        WHATSAPP => MdiIcons.whatsapp,
        YOUTUBE => MdiIcons.youtube,
        WEBSITE => Icons.language,
        OTHER => Icons.link,
      };

  static SocialPlatform fromName(String? name) => values.firstWhere((e) => e.name == name, orElse: () => OTHER);
}

class SocialLink {
  final SocialPlatform platform;
  final String url;

  const SocialLink({required this.platform, required this.url});

  factory SocialLink.fromJson(Map<String, dynamic> json) =>
      SocialLink(platform: SocialPlatform.fromName(json['platform']), url: json['url'] ?? '');

  Map<String, dynamic> toJson() => {'platform': platform.name, 'url': url};

  /// Link sem o protocolo, para exibição
  String get displayUrl => url.replaceFirst(RegExp(r'^https?://(www\.)?'), '');
}
