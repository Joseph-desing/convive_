-- ===================================
-- TABLA SWIPES - Setup completo
-- Ejecuta esto en SQL Editor de Supabase
-- ===================================

-- 1. Crear la tabla swipes
CREATE TABLE IF NOT EXISTS swipes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  swiper_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  target_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  direction TEXT NOT NULL CHECK (direction IN ('like', 'dislike')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Evitar swipes duplicados
  UNIQUE(swiper_id, target_user_id)
);

-- 2. Crear índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_swipes_swiper ON swipes(swiper_id);
CREATE INDEX IF NOT EXISTS idx_swipes_target ON swipes(target_user_id);
CREATE INDEX IF NOT EXISTS idx_swipes_direction ON swipes(direction);
CREATE INDEX IF NOT EXISTS idx_swipes_swiper_target ON swipes(swiper_id, target_user_id);

-- 3. Habilitar RLS (Row Level Security)
ALTER TABLE swipes ENABLE ROW LEVEL SECURITY;

-- 4. Eliminar políticas existentes si las hay
DROP POLICY IF EXISTS "Users can insert their own swipes" ON swipes;
DROP POLICY IF EXISTS "Users can view swipes related to them" ON swipes;
DROP POLICY IF EXISTS "Users can update their own swipes" ON swipes;
DROP POLICY IF EXISTS "Users can delete their own swipes" ON swipes;

-- 5. Crear políticas RLS

-- Política INSERT: Los usuarios autenticados pueden crear sus propios swipes
CREATE POLICY "Users can insert their own swipes"
ON swipes
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = swiper_id);

-- Política SELECT: Los usuarios pueden ver swipes donde están involucrados
CREATE POLICY "Users can view swipes related to them"
ON swipes
FOR SELECT
TO authenticated
USING (
  auth.uid() = swiper_id 
  OR auth.uid() = target_user_id
);

-- Política UPDATE: Los usuarios pueden actualizar sus propios swipes
CREATE POLICY "Users can update their own swipes"
ON swipes
FOR UPDATE
TO authenticated
USING (auth.uid() = swiper_id)
WITH CHECK (auth.uid() = swiper_id);

-- Política DELETE: Los usuarios pueden eliminar sus propios swipes
CREATE POLICY "Users can delete their own swipes"
ON swipes
FOR DELETE
TO authenticated
USING (auth.uid() = swiper_id);

-- 6. Verificar la creación
SELECT 
  'Tabla swipes creada correctamente' as status,
  COUNT(*) as total_swipes
FROM swipes;
