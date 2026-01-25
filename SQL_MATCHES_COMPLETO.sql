-- ===================================
-- TABLA MATCHES - Setup completo
-- Ejecuta esto en SQL Editor de Supabase
-- ===================================

-- 1. Crear la tabla matches
CREATE TABLE IF NOT EXISTS matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_a_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  user_b_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  compatibility_score DOUBLE PRECISION NOT NULL DEFAULT 50,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Evitar matches duplicados
  UNIQUE(user_a_id, user_b_id)
);

-- 2. Crear índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_matches_user_a ON matches(user_a_id);
CREATE INDEX IF NOT EXISTS idx_matches_user_b ON matches(user_b_id);
CREATE INDEX IF NOT EXISTS idx_matches_created_at ON matches(created_at);

-- 3. Habilitar RLS (Row Level Security)
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;

-- 4. Eliminar políticas existentes si las hay
DROP POLICY IF EXISTS "Users can view their matches" ON matches;
DROP POLICY IF EXISTS "Users can create matches" ON matches;
DROP POLICY IF EXISTS "Users can update their matches" ON matches;
DROP POLICY IF EXISTS "Users can delete their matches" ON matches;

-- 5. Crear políticas RLS

-- Política SELECT: Los usuarios pueden ver matches donde están involucrados
CREATE POLICY "Users can view their matches"
ON matches
FOR SELECT
TO authenticated
USING (
  auth.uid() = user_a_id 
  OR auth.uid() = user_b_id
);

-- Política INSERT: Los usuarios autenticados pueden crear matches
CREATE POLICY "Users can create matches"
ON matches
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = user_a_id 
  OR auth.uid() = user_b_id
);

-- Política UPDATE: Los usuarios pueden actualizar sus matches
CREATE POLICY "Users can update their matches"
ON matches
FOR UPDATE
TO authenticated
USING (
  auth.uid() = user_a_id 
  OR auth.uid() = user_b_id
)
WITH CHECK (
  auth.uid() = user_a_id 
  OR auth.uid() = user_b_id
);

-- Política DELETE: Los usuarios pueden eliminar sus matches
CREATE POLICY "Users can delete their matches"
ON matches
FOR DELETE
TO authenticated
USING (
  auth.uid() = user_a_id 
  OR auth.uid() = user_b_id
);

-- 6. Verificar swipes mutuos y crear match de prueba
-- Primero, ver los swipes que tienes
SELECT 
  s1.swiper_id as user_a,
  s1.target_user_id as user_b,
  s1.direction as user_a_direction,
  s2.direction as user_b_direction
FROM swipes s1
LEFT JOIN swipes s2 
  ON s1.swiper_id = s2.target_user_id 
  AND s1.target_user_id = s2.swiper_id
WHERE s1.direction = 'like'
  AND s2.direction = 'like';

-- 7. Verificar la tabla
SELECT 
  'Tabla matches creada correctamente' as status,
  COUNT(*) as total_matches
FROM matches;
