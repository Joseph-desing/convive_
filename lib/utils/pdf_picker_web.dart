import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

Future<PlatformFile?> pickPdfFile() async {
  final completer = Completer<PlatformFile?>();

  final input = web.document.createElement('input') as web.HTMLInputElement
    ..type = 'file'
    ..accept = 'application/pdf,.pdf'
    ..multiple = false;

  input.addEventListener(
    'change',
    (web.Event _) {
      final files = input.files;
      if (files == null || files.length == 0) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }

      final file = files.item(0)!;
      final reader = web.FileReader();

      reader.addEventListener(
        'loadend',
        (web.Event _) {
          final result = reader.result;
          // result es un ArrayBuffer en JSAny — convertir a Uint8List
          final buffer = result as JSArrayBuffer;
          final bytes = buffer.toDart.asUint8List();
          if (!completer.isCompleted) {
            completer.complete(
              PlatformFile(
                name: file.name,
                size: file.size,
                bytes: bytes,
              ),
            );
          }
        }.toJS,
      );

      reader.addEventListener(
        'error',
        (web.Event _) {
          if (!completer.isCompleted) completer.complete(null);
        }.toJS,
      );

      reader.readAsArrayBuffer(file);
    }.toJS,
  );

  // Adjuntar al DOM brevemente para que Chrome permita el click
  web.document.body!.append(input);
  input.click();
  // Eliminar del DOM después de un tick
  Future.microtask(() => input.remove());

  return completer.future;
}
