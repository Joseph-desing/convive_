# Setup Admin en Supabase

## Ejecuta esto en Supabase SQL Editor

### 1️⃣ Crear tabla de usuarios (si no existe)
```sql
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT,
  role TEXT NOT NULL DEFAULT 'student' CHECK (role IN ('student', 'non_student', 'admin')),
  is_suspended BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
```

### 2️⃣ Crear tabla feedback
```sql
CREATE TABLE IF NOT EXISTS public.feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('complaint', 'suggestion', 'bug_report')),
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_review', 'resolved', 'closed')),
  subject TEXT NOT NULL,
  message TEXT NOT NULL,
  category TEXT,
  attachment_url TEXT,
  admin_response TEXT,
  admin_response_at TIMESTAMP WITH TIME ZONE,
  resolved_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_feedback_user_id ON feedback(user_id);
CREATE INDEX idx_feedback_status ON feedback(status);
CREATE INDEX idx_feedback_type ON feedback(type);
CREATE INDEX idx_feedback_created_at ON feedback(created_at DESC);

ALTER TABLE public.feedback ENABLE ROW LEVEL SECURITY;
```

### 3️⃣ Row Level Security Policies
```sql
-- Feedback: Users ver su propio feedback y admins ven todo
DROP POLICY IF EXISTS "Usuarios ven su propio feedback" ON public.feedback;
DROP POLICY IF EXISTS "Admin ve todo feedback" ON public.feedback;

CREATE POLICY "Usuarios ven su propio feedback"
  ON public.feedback FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Admin ve todo feedback"
  ON public.feedback FOR SELECT
  USING ((SELECT role FROM public.users WHERE id = auth.uid()) = 'admin');

-- Usuarios pueden crear feedback
DROP POLICY IF EXISTS "Usuarios crean feedback" ON public.feedback;
CREATE POLICY "Usuarios crean feedback"
  ON public.feedback FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Admin puede actualizar feedback
DROP POLICY IF EXISTS "Admin actualiza feedback" ON public.feedback;
CREATE POLICY "Admin actualiza feedback"
  ON public.feedback FOR UPDATE
  USING ((SELECT role FROM public.users WHERE id = auth.uid()) = 'admin');
```

### 4️⃣ **ASIGNAR ADMIN A changoluizajoseph@gmail.com**
```sql
-- Primero inserta el usuario si no existe
INSERT INTO public.users (id, email, role)
SELECT id, email, 'admin'
FROM auth.users
WHERE email = 'changoluizajoseph@gmail.com'
ON CONFLICT (id) DO UPDATE
SET role = 'admin';

-- Verificar
SELECT id, email, role FROM public.users WHERE email = 'changoluizajoseph@gmail.com';
```

---

## Pasos en Supabase Dashboard:

1. Ve a **Database** → **SQL Editor**
2. Copia y ejecuta CADA bloque de código en orden (1️⃣ 2️⃣ 3️⃣ 4️⃣)
3. Espera a que cada uno termine sin errores
4. Luego inicia sesión con `changoluizajoseph@gmail.com` en la app
5. Navega a **http://localhost:PORT/admin** (o tu URL)

✅ ¡Listo! Deberías ver el panel admin.
