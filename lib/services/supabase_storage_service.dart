import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:typed_data';

class SupabaseStorageService {
  final SupabaseClient _supabase;

  SupabaseStorageService({required SupabaseClient supabase})
      : _supabase = supabase;

  /// Subir imagen de perfil
  Future<String> uploadProfileImage({
    required String userId,
    required String filePath,
  }) async {
    final fileName = 'profile_$userId.jpg';
    await _supabase.storage
        .from('profiles')
        .upload(fileName, File(filePath), fileOptions: const FileOptions(upsert: true));
    return _supabase.storage.from('profiles').getPublicUrl(fileName);
  }

  /// Subir imagen de perfil (compat web) usando ImagePicker
  Future<String> uploadProfileImageXFile({
    required String userId,
    required XFile file,
  }) async {
    final fileName = 'profile_$userId.jpg';
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      await _supabase.storage.from('profiles').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
    } else {
      await _supabase.storage.from('profiles').upload(
            fileName,
            File(file.path),
            fileOptions: const FileOptions(upsert: true),
          );
    }
    return _supabase.storage.from('profiles').getPublicUrl(fileName);
  }

  /// Subir imagen de propiedad
  Future<String> uploadPropertyImage({
    required String propertyId,
    required String filePath,
  }) async {
    final fileName = 'property_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _supabase.storage
        .from('properties')
        .upload('$propertyId/$fileName', File(filePath));
    return _supabase.storage
        .from('properties')
        .getPublicUrl('$propertyId/$fileName');
  }

  /// Subir imagen de propiedad (compat web) usando XFile
  Future<String> uploadPropertyImageXFile({
    required String propertyId,
    required XFile file,
  }) async {
    final fileName = 'property_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '$propertyId/$fileName';
    
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      await _supabase.storage.from('properties').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
    } else {
      await _supabase.storage.from('properties').upload(
            path,
            File(file.path),
            fileOptions: const FileOptions(upsert: true),
          );
    }
    return _supabase.storage.from('properties').getPublicUrl(path);
  }

  /// Eliminar imagen de propiedad
  Future<void> deletePropertyImage({
    required String propertyId,
    required String imageName,
  }) async {
    await _supabase.storage
        .from('properties')
        .remove(['$propertyId/$imageName']);
  }

  /// Eliminar imagen de perfil
  Future<void> deleteProfileImage(String userId) async {
    await _supabase.storage
        .from('profiles')
        .remove(['profile_$userId.jpg']);
  }

  /// Subir imagen de búsqueda de roommate
  Future<String> uploadRoommateSearchImageXFile(
    String fileName,
    dynamic file, // Puede ser File o XFile
  ) async {
    try {
      if (kIsWeb) {
        // En web, siempre leer como bytes
        late Uint8List bytes;
        if (file is XFile) {
          bytes = await file.readAsBytes();
        } else if (file is File) {
          bytes = await file.readAsBytes();
        } else {
          throw Exception('Tipo de archivo no soportado');
        }
        
        await _supabase.storage.from('properties').uploadBinary(
              'roommate/$fileName',
              bytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );
      } else {
        // En nativo, convertir a File si es necesario
        final uploadFile = file is File ? file : File((file as XFile).path);
        await _supabase.storage.from('properties').upload(
              'roommate/$fileName',
              uploadFile,
              fileOptions: const FileOptions(upsert: true),
            );
      }
      return _supabase.storage.from('properties').getPublicUrl('roommate/$fileName');
    } catch (e) {
      print('❌ Error subiendo imagen de roommate: $e');
      rethrow;
    }
  }

  /// Subir PDF de verificación para publicaciones.
  ///
  /// Retorna una URL firmada de larga duración (5 años) en lugar de una URL
  /// pública para proteger documentos sensibles (cédula, planillas, etc.).
  ///
  /// ⚠️ Para máxima seguridad: configura el bucket 'properties' como PRIVADO
  /// en el dashboard de Supabase → Storage → Buckets → properties → Settings.
  /// Con bucket privado, sólo las signed URLs permiten acceso.
  Future<String> uploadVerificationPdf({
    required String ownerId,
    required String publicationType,
    required String publicationId,
    required PlatformFile file,
  }) async {
    final safeName = file.name
        .replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final fileName =
        '${ownerId}_${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final path = 'verification/$publicationType/$publicationId/$fileName';

    if (kIsWeb) {
      final bytes = file.bytes;
      if (bytes == null) {
        throw Exception('No se pudo leer el PDF seleccionado');
      }
      await _supabase.storage.from('properties').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              upsert: true,
            ),
          );
    } else {
      final filePath = file.path;
      if (filePath == null) {
        throw Exception('No se pudo leer la ruta del PDF seleccionado');
      }
      await _supabase.storage.from('properties').upload(
            path,
            File(filePath),
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              upsert: true,
            ),
          );
    }

    // Intentar URL firmada (5 años). Si el bucket es público, cae al fallback.
    try {
      return await _supabase.storage
          .from('properties')
          .createSignedUrl(path, 60 * 60 * 24 * 365 * 5);
    } catch (_) {
      // Fallback para buckets públicos — la firma falla si no está configurado.
      return _supabase.storage.from('properties').getPublicUrl(path);
    }
  }

  /// Eliminar el PDF de verificación anterior del storage.
  /// Recibe la URL o el path relativo almacenado en la BD.
  /// No lanza excepción si falla (operación no crítica).
  Future<void> deleteVerificationPdf(String urlOrPath) async {
    try {
      final storagePath = _extractStoragePath(urlOrPath, 'properties');
      if (storagePath == null || storagePath.isEmpty) return;
      await _supabase.storage.from('properties').remove([storagePath]);
      print('🗑️ PDF de verificación anterior eliminado: $storagePath');
    } catch (e) {
      print('⚠️ No se pudo eliminar PDF anterior (no crítico): $e');
    }
  }

  /// Extrae el path relativo del storage a partir de una URL completa de Supabase.
  /// Soporta URLs públicas y firmadas.
  String? _extractStoragePath(String url, String bucket) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      // URLs públicas:  .../storage/v1/object/public/{bucket}/{path...}
      // URLs firmadas:  .../storage/v1/object/sign/{bucket}/{path...}
      final bucketIndex = segments.indexOf(bucket);
      if (bucketIndex == -1 || bucketIndex + 1 >= segments.length) return null;
      return segments.sublist(bucketIndex + 1).join('/');
    } catch (_) {
      // Si ya viene como path relativo (sin dominio), devolverlo tal cual.
      if (!url.startsWith('http') && url.contains('/')) return url;
      return null;
    }
  }

}
