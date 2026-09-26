/// Download de um arquivo gerado no app (ex: PNG da placa de verificação).
/// Na web baixa pelo navegador; nas outras plataformas [canDownloadFiles] é false.
export 'file_download_stub.dart' if (dart.library.js_interop) 'file_download_web.dart';
