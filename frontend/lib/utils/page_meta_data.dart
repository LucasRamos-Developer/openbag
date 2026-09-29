/// Título, descrição, endereço canônico, imagem de prévia e dados estruturados (JSON-LD) de uma página pública
class PageMetaData {
  /// Título da aba e do resultado de busca (sem o " · OpenBag", que é acrescentado)
  final String? title;
  final String description;

  /// Caminho da página no app (ex: `/r/cantina-demo`); vira o link canônico com a origem do site
  final String path;

  /// Imagem da prévia ao compartilhar (URL absoluta); sem ela, fica a imagem padrão do site
  final String? imageUrl;

  /// Dados estruturados (schema.org) inseridos como `application/ld+json`
  final Map<String, dynamic>? jsonLd;

  const PageMetaData({this.title, required this.description, required this.path, this.imageUrl, this.jsonLd});

  static const siteName = 'OpenBag';

  /// Página sem dados próprios (painéis, checkout...): o que está no `web/index.html`
  static const defaults = PageMetaData(
    description: 'Peça direto dos restaurantes e pequenos negócios da sua cidade, com entregadores locais e '
        'cooperativas. Cardápio, pedido e acompanhamento da entrega em um só lugar.',
    path: '/',
  );

  // O JSON-LD é montado uma vez por página: compara pela referência
  @override
  bool operator ==(Object other) =>
      other is PageMetaData &&
      other.title == title &&
      other.description == description &&
      other.path == path &&
      other.imageUrl == imageUrl &&
      identical(other.jsonLd, jsonLd);

  @override
  int get hashCode => Object.hash(title, description, path, imageUrl, jsonLd == null ? 0 : identityHashCode(jsonLd));

  String get fullTitle => title == null ? '$siteName · Restaurantes e pequenos negócios da sua cidade' : '$title · $siteName';
}
