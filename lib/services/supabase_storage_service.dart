import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

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
        .upload(fileName, File(filePath));
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

  /// Obtener URL pública de imagen
  String getPublicUrl({
    required String bucket,
    required String path,
  }) {
    return _supabase.storage.from(bucket).getPublicUrl(path);
  }
}
