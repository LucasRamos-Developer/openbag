import 'dart:typed_data';

const bool canPickFiles = false;

/// Arquivo escolhido: nome e conteúdo
typedef PickedFile = ({String name, Uint8List bytes});

Future<PickedFile?> pickFile({required String accept}) async => null;
