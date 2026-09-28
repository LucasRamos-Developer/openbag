/// Escolha de um arquivo do aparelho (ex: a ata em PDF). Na web abre o seletor do navegador;
/// nas outras plataformas [canPickFiles] é false.
export 'file_pick_stub.dart' if (dart.library.js_interop) 'file_pick_web.dart';
