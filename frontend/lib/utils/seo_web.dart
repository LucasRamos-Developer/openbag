import 'dart:convert';
import 'package:web/web.dart' as web;
import 'page_meta_data.dart';

const _jsonLdId = 'page-jsonld';

/// Atualiza título, descrição, canônico, Open Graph e JSON-LD no `<head>`.
/// O Google executa o JavaScript da página e lê essas tags; robôs de prévia (WhatsApp, Facebook) veem as do
/// `index.html`.
void applyPageMeta(PageMetaData meta) {
  final origin = web.window.location.origin;
  final url = '$origin${meta.path}';

  web.document.title = meta.fullTitle;
  _meta('name', 'description', meta.description);
  _link('canonical', url);
  _meta('property', 'og:title', meta.fullTitle);
  _meta('property', 'og:description', meta.description);
  _meta('property', 'og:url', url);
  _meta('property', 'og:image', meta.imageUrl ?? '$origin/og-image.jpg');

  web.document.getElementById(_jsonLdId)?.remove();
  if (meta.jsonLd != null) {
    final script = web.HTMLScriptElement()
      ..id = _jsonLdId
      ..type = 'application/ld+json'
      ..text = jsonEncode(meta.jsonLd);
    web.document.head!.append(script);
  }
}

void _meta(String attribute, String key, String content) {
  var element = web.document.head!.querySelector('meta[$attribute="$key"]');
  if (element == null) {
    element = web.document.createElement('meta')..setAttribute(attribute, key);
    web.document.head!.append(element);
  }
  element.setAttribute('content', content);
}

void _link(String rel, String href) {
  var element = web.document.head!.querySelector('link[rel="$rel"]');
  if (element == null) {
    element = web.document.createElement('link')..setAttribute('rel', rel);
    web.document.head!.append(element);
  }
  element.setAttribute('href', href);
}
