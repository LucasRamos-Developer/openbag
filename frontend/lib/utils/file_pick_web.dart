import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

const bool canPickFiles = true;

/// Arquivo escolhido: nome e conteúdo
typedef PickedFile = ({String name, Uint8List bytes});

/// Abre o seletor do navegador ([accept] ex: "application/pdf"); null se a pessoa cancelar
Future<PickedFile?> pickFile({required String accept}) {
  final completer = Completer<PickedFile?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = accept;

  input.addEventListener('change', (web.Event _) {
    final file = input.files?.item(0);
    if (file == null) {
      completer.complete(null);
      return;
    }
    final reader = web.FileReader();
    reader.addEventListener('load', (web.Event _) {
      final buffer = (reader.result as JSArrayBuffer).toDart;
      completer.complete((name: file.name, bytes: buffer.asUint8List()));
    }.toJS);
    reader.addEventListener('error', (web.Event _) {
      if (!completer.isCompleted) completer.complete(null);
    }.toJS);
    reader.readAsArrayBuffer(file);
  }.toJS);
  input.addEventListener('cancel', (web.Event _) {
    if (!completer.isCompleted) completer.complete(null);
  }.toJS);
  input.click();
  return completer.future;
}
