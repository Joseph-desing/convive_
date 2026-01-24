-- ============================================================================
-- POLÍTICAS DE STORAGE PARA BUCKETS
-- ============================================================================
-- Ejecuta este SQL en la consola SQL de Supabase para habilitar las políticas de storage

-- Habilitar RLS en storage.objects si no está habilitado
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si las hay
DROP POLICY IF EXISTS "Profile images are publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own profile image" ON storage.objects;
DROP POLICY IF EXISTS "Property images are publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload property images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own property images" ON storage.objects;

-- POLÍTICAS PARA BUCKET 'profiles'
-- Lectura pública de imágenes de perfil
CREATE POLICY "Profile images are publicly accessible"
  ON storage.objects FOR SELECT
  USING ( bucket_id = 'profiles' );

-- Los usuarios autenticados pueden subir su propia imagen de perfil
CREATE POLICY "Users can upload their own profile image"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'profiles'
    AND auth.role() = 'authenticated'
  );

-- Los usuarios pueden actualizar su propia imagen de perfil
CREATE POLICY "Users can update their own profile image"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'profiles'
    AND auth.role() = 'authenticated'
  );

-- Los usuarios pueden eliminar su propia imagen de perfil
CREATE POLICY "Users can delete their own profile image"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'profiles'
    AND auth.role() = 'authenticated'
  );

-- POLÍTICAS PARA BUCKET 'properties'
-- Lectura pública de imágenes de propiedades
CREATE POLICY "Property images are publicly accessible"
  ON storage.objects FOR SELECT
  USING ( bucket_id = 'properties' );

-- Usuarios autenticados pueden subir imágenes de propiedades
CREATE POLICY "Users can upload property images"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'properties'
    AND auth.role() = 'authenticated'
  );

-- Usuarios autenticados pueden actualizar imágenes de propiedades
CREATE POLICY "Users can update property images"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'properties'
    AND auth.role() = 'authenticated'
  );

-- Usuarios autenticados pueden eliminar imágenes de propiedades
CREATE POLICY "Users can delete property images"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'properties'
    AND auth.role() = 'authenticated'
  );
