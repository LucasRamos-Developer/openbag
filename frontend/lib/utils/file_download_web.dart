import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

const bool canDownloadFiles = true;

void downloadBytes(Uint8List bytes, {required String fileName, required String mimeType}) {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
