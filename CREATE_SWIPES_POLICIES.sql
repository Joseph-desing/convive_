-- Políticas RLS para la tabla swipes
-- Ejecuta esto en el SQL Editor de Supabase

-- Habilitar RLS en la tabla swipes
ALTER TABLE swipes ENABLE ROW LEVEL SECURITY;

-- Política: Los usuarios autenticados pueden insertar sus propios swipes
CREATE POLICY "Users can insert their own swipes"
ON swipes
FOR INSERT
TO authenticated
WITH CHECK (auth.uid()::text = swiper_id);

-- Política: Los usuarios pueden ver swipes donde ellos son el swiper o el target
CREATE POLICY "Users can view swipes related to them"
ON swipes
FOR SELECT
TO authenticated
USING (
  auth.uid()::text = swiper_id 
  OR auth.uid()::text = target_user_id
);

-- Política: Los usuarios solo pueden actualizar sus propios swipes
CREATE POLICY "Users can update their own swipes"
ON swipes
FOR UPDATE
TO authenticated
USING (auth.uid()::text = swiper_id)
WITH CHECK (auth.uid()::text = swiper_id);

-- Política: Los usuarios solo pueden eliminar sus propios swipes
CREATE POLICY "Users can delete their own swipes"
ON swipes
FOR DELETE
TO authenticated
USING (auth.uid()::text = swiper_id);
