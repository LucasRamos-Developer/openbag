import 'dart:typed_data';

const bool canDownloadFiles = false;

void downloadBytes(Uint8List bytes, {required String fileName, required String mimeType}) {
  throw UnsupportedError('Download de arquivos só está disponível na web');
}
