import 'package:file_picker/file_picker.dart';

Future<PlatformFile?> pickPdfFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['pdf'],
  );

  if (result == null || result.files.isEmpty) return null;
  return result.files.single;
}
