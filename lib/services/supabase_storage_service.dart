import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
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

}
