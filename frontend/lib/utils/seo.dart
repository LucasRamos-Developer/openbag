/// Meta tags da página atual para buscadores e prévias de link.
/// Na web altera o `<head>` do documento; nas outras plataformas não faz nada.
export 'page_meta_data.dart';
export 'seo_stub.dart' if (dart.library.js_interop) 'seo_web.dart';
