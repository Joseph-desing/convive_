-- COPIA Y PEGA ESTO EN SUPABASE SQL EDITOR

-- Borrar políticas viejas
DROP POLICY IF EXISTS "Users can read own user" ON users;
DROP POLICY IF EXISTS "Users can update own user" ON users;

-- Nueva política: leer propio usuario
CREATE POLICY "Users can read own user" ON users
  FOR SELECT 
  USING (auth.uid() = id);

-- Nueva política: crear usuario en signup
CREATE POLICY "Users can insert own user during signup" ON users
  FOR INSERT 
  WITH CHECK (auth.uid() = id);

-- Nueva política: actualizar propio usuario
CREATE POLICY "Users can update own user" ON users
  FOR UPDATE 
  USING (auth.uid() = id);
