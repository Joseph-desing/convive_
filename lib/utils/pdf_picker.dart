import 'package:file_picker/file_picker.dart';

import 'pdf_picker_io.dart'
    if (dart.library.html) 'pdf_picker_web.dart' as implementation;

Future<PlatformFile?> pickPdfFile() {
  return implementation.pickPdfFile();
}
