-- ============================================================================
-- SUPABASE SQL SETUP - ConVive
-- Copia y pega esto en el SQL Editor de Supabase (https://supabase.com)
-- ============================================================================

-- ============================================================================
-- 1. TABLA: users (Usuarios del sistema)
-- ============================================================================
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('student', 'non_student', 'admin')) DEFAULT 'student',
  subscription_type TEXT DEFAULT 'free',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

-- ============================================================================
-- 2. TABLA: profiles (Perfil del usuario)
-- ============================================================================
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  birth_date DATE,
  gender TEXT CHECK (gender IN ('male', 'female', 'other')),
  bio TEXT,
  profile_image_url TEXT,
  verified BOOLEAN DEFAULT FALSE,
  verified_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

-- ============================================================================
-- 3. TABLA: habits (Hábitos y preferencias del usuario)
-- ============================================================================
CREATE TABLE IF NOT EXISTS habits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  sleep_start TEXT DEFAULT '22:00',
  sleep_end TEXT DEFAULT '07:00',
  cleanliness_level INTEGER CHECK (cleanliness_level >= 1 AND cleanliness_level <= 10) DEFAULT 5,
  noise_tolerance INTEGER CHECK (noise_tolerance >= 1 AND noise_tolerance <= 10) DEFAULT 5,
  party_frequency INTEGER CHECK (party_frequency >= 0 AND party_frequency <= 7) DEFAULT 0,
  guests_tolerance INTEGER CHECK (guests_tolerance >= 0 AND guests_tolerance <= 10) DEFAULT 5,
  pets BOOLEAN DEFAULT FALSE,
  pet_tolerance BOOLEAN DEFAULT FALSE,
  alcohol_frequency INTEGER CHECK (alcohol_frequency >= 0 AND alcohol_frequency <= 7) DEFAULT 0,
  work_mode TEXT CHECK (work_mode IN ('remote', 'presencial', 'hibrido')) DEFAULT 'presencial',
  time_at_home INTEGER CHECK (time_at_home >= 0 AND time_at_home <= 10) DEFAULT 5,
  communication_style TEXT,
  conflict_management TEXT,
  responsibility_level INTEGER CHECK (responsibility_level >= 1 AND responsibility_level <= 10) DEFAULT 5,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

-- ============================================================================
-- 4. TABLA: properties (Propiedades/Departamentos)
-- ============================================================================
CREATE TABLE IF NOT EXISTS properties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10, 2) NOT NULL,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  address TEXT NOT NULL,
  available_from DATE DEFAULT CURRENT_DATE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

-- ============================================================================
-- 5. TABLA: property_images (Imágenes de propiedades)
-- ============================================================================
CREATE TABLE IF NOT EXISTS property_images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  validated BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

-- ============================================================================
-- 6. TABLA: swipes (Registro de swipes)
-- ============================================================================
CREATE TABLE IF NOT EXISTS swipes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  swiper_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  target_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  direction TEXT NOT NULL CHECK (direction IN ('like', 'dislike')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

-- ============================================================================
-- 7. TABLA: matches (Matches entre usuarios)
-- ============================================================================
CREATE TABLE IF NOT EXISTS matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_a_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user_b_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  compatibility_score DECIMAL(5, 2) CHECK (compatibility_score >= 0 AND compatibility_score <= 100),
  matched_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  UNIQUE(user_a_id, user_b_id),
  CHECK (user_a_id != user_b_id)
);

-- ============================================================================
-- 8. TABLA: chats (Conversaciones)
-- ============================================================================
CREATE TABLE IF NOT EXISTS chats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL UNIQUE REFERENCES matches(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

-- ============================================================================
-- 9. TABLA: messages (Mensajes en chats)
-- ============================================================================
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

-- ============================================================================
-- 10. TABLA: subscriptions (Suscripciones de usuarios)
-- ============================================================================
CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  price DECIMAL(10, 2) NOT NULL,
  is_student BOOLEAN DEFAULT FALSE,
  start_date TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  end_date TIMESTAMP WITH TIME ZONE,
  status TEXT NOT NULL CHECK (status IN ('active', 'expired', 'cancelled')) DEFAULT 'active',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

-- ============================================================================
-- ÍNDICES PARA OPTIMIZACIÓN DE CONSULTAS
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_habits_user_id ON habits(user_id);
CREATE INDEX IF NOT EXISTS idx_properties_owner_id ON properties(owner_id);
CREATE INDEX IF NOT EXISTS idx_properties_is_active ON properties(is_active);
CREATE INDEX IF NOT EXISTS idx_properties_available_from ON properties(available_from);
CREATE INDEX IF NOT EXISTS idx_property_images_property_id ON property_images(property_id);
CREATE INDEX IF NOT EXISTS idx_swipes_swiper_id ON swipes(swiper_id);
CREATE INDEX IF NOT EXISTS idx_swipes_target_user_id ON swipes(target_user_id);
CREATE INDEX IF NOT EXISTS idx_swipes_created_at ON swipes(created_at);
CREATE INDEX IF NOT EXISTS idx_matches_user_a_id ON matches(user_a_id);
CREATE INDEX IF NOT EXISTS idx_matches_user_b_id ON matches(user_b_id);
CREATE INDEX IF NOT EXISTS idx_matches_created_at ON matches(created_at);
CREATE INDEX IF NOT EXISTS idx_chats_match_id ON chats(match_id);
CREATE INDEX IF NOT EXISTS idx_messages_chat_id ON messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at);
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) - HABILITACIÓN
-- ============================================================================

-- Habilitar RLS en todas las tablas
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE property_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE swipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) - POLÍTICAS
-- ============================================================================

-- ============ USERS ============
-- Los usuarios solo pueden ver su propio usuario (excepto admin)
CREATE POLICY "Users can read own user" ON users
  FOR SELECT USING (auth.uid() = id OR auth.jwt() ->> 'role' = 'admin');

-- Los usuarios pueden actualizar su propio usuario
CREATE POLICY "Users can update own user" ON users
  FOR UPDATE USING (auth.uid() = id);

-- ============ PROFILES ============
-- Los perfiles son públicos para lectura (para el matching)
CREATE POLICY "Profiles are public" ON profiles
  FOR SELECT USING (true);

-- Los usuarios pueden actualizar su propio perfil
CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = user_id);

-- Los usuarios pueden insertar su propio perfil
CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ============ HABITS ============
-- Los hábitos son públicos para lectura (para el matching)
CREATE POLICY "Habits are public" ON habits
  FOR SELECT USING (true);

-- Los usuarios pueden actualizar sus hábitos
CREATE POLICY "Users can update own habits" ON habits
  FOR UPDATE USING (auth.uid() = user_id);

-- Los usuarios pueden insertar sus hábitos
CREATE POLICY "Users can insert own habits" ON habits
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ============ PROPERTIES ============
-- Las propiedades activas son públicas para lectura
CREATE POLICY "Active properties are public" ON properties
  FOR SELECT USING (is_active = true);

-- El dueño puede ver sus propias propiedades (activas o no)
CREATE POLICY "Owners can see own properties" ON properties
  FOR SELECT USING (auth.uid() = owner_id);

-- El dueño puede actualizar sus propiedades
CREATE POLICY "Owners can update own properties" ON properties
  FOR UPDATE USING (auth.uid() = owner_id);

-- El dueño puede insertar propiedades
CREATE POLICY "Users can insert properties" ON properties
  FOR INSERT WITH CHECK (auth.uid() = owner_id);

-- El dueño puede eliminar sus propiedades
CREATE POLICY "Owners can delete own properties" ON properties
  FOR DELETE USING (auth.uid() = owner_id);

-- ============ PROPERTY_IMAGES ============
-- Las imágenes de propiedades activas son públicas
CREATE POLICY "Images of active properties are public" ON property_images
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM properties 
      WHERE properties.id = property_images.property_id 
      AND properties.is_active = true
    )
  );

-- El dueño de la propiedad puede ver todas sus imágenes
CREATE POLICY "Owners can see own property images" ON property_images
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM properties 
      WHERE properties.id = property_images.property_id 
      AND properties.owner_id = auth.uid()
    )
  );

-- El dueño puede insertar imágenes
CREATE POLICY "Owners can insert property images" ON property_images
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM properties 
      WHERE properties.id = property_images.property_id 
      AND properties.owner_id = auth.uid()
    )
  );

-- El dueño puede eliminar imágenes
CREATE POLICY "Owners can delete property images" ON property_images
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM properties 
      WHERE properties.id = property_images.property_id 
      AND properties.owner_id = auth.uid()
    )
  );

-- ============ SWIPES ============
-- Los usuarios solo pueden ver sus propios swipes
CREATE POLICY "Users can read own swipes" ON swipes
  FOR SELECT USING (auth.uid() = swiper_id);

-- Los usuarios pueden crear swipes
CREATE POLICY "Users can insert swipes" ON swipes
  FOR INSERT WITH CHECK (auth.uid() = swiper_id);

-- ============ MATCHES ============
-- Los usuarios solo pueden ver sus matches
CREATE POLICY "Users can read own matches" ON matches
  FOR SELECT USING (auth.uid() = user_a_id OR auth.uid() = user_b_id);

-- Los usuarios no pueden insertar directamente (lo hace el backend)
-- pero si pueden actualizar sus matches si lo necesitan
CREATE POLICY "Users can update matches they're in" ON matches
  FOR UPDATE USING (auth.uid() = user_a_id OR auth.uid() = user_b_id);

-- ============ CHATS ============
-- Los usuarios solo pueden ver sus chats (a través de su match)
CREATE POLICY "Users can read own chats" ON chats
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM matches
      WHERE matches.id = chats.match_id
      AND (matches.user_a_id = auth.uid() OR matches.user_b_id = auth.uid())
    )
  );

-- ============ MESSAGES ============
-- Los usuarios solo pueden ver mensajes de sus chats
CREATE POLICY "Users can read messages from own chats" ON messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM chats
      JOIN matches ON matches.id = chats.match_id
      WHERE chats.id = messages.chat_id
      AND (matches.user_a_id = auth.uid() OR matches.user_b_id = auth.uid())
    )
  );

-- Los usuarios pueden enviar mensajes a sus chats
CREATE POLICY "Users can insert messages to own chats" ON messages
  FOR INSERT WITH CHECK (
    auth.uid() = sender_id AND
    EXISTS (
      SELECT 1 FROM chats
      JOIN matches ON matches.id = chats.match_id
      WHERE chats.id = chat_id
      AND (matches.user_a_id = auth.uid() OR matches.user_b_id = auth.uid())
    )
  );

-- ============ SUBSCRIPTIONS ============
-- Los usuarios solo pueden ver sus suscripciones
CREATE POLICY "Users can read own subscriptions" ON subscriptions
  FOR SELECT USING (auth.uid() = user_id);

-- Los usuarios pueden crear suscripciones
CREATE POLICY "Users can insert own subscriptions" ON subscriptions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- STORAGE BUCKETS (Necesario crear en UI o descomenta si usas SQL)
-- ============================================================================

-- OPCIÓN 1: Si tu versión de Supabase lo soporta, descomenta:
/*
INSERT INTO storage.buckets (id, name, public)
VALUES ('profiles', 'profiles', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('properties', 'properties', true)
ON CONFLICT (id) DO NOTHING;
*/

-- OPCIÓN 2: Crear desde el dashboard de Supabase:
-- 1. Ve a Storage → Create bucket
-- 2. Nombre: "profiles" → Public
-- 3. Nombre: "properties" → Public

-- ============================================================================
-- STORAGE POLICIES (Si ya creaste los buckets)
-- ============================================================================

/*
-- Perfil: public read, authenticated write own
CREATE POLICY "Profile images are publicly accessible"
  ON storage.objects FOR SELECT
  USING ( bucket_id = 'profiles' );

CREATE POLICY "Users can upload their own profile image"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'profiles'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Properties: public read, authenticated write own
CREATE POLICY "Property images are publicly accessible"
  ON storage.objects FOR SELECT
  USING ( bucket_id = 'properties' );

CREATE POLICY "Users can upload property images"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'properties'
    AND auth.role() = 'authenticated'
  );
*/

-- ============================================================================
-- VERIFICACIÓN: Ejecuta estas queries para confirmar que todo está bien
-- ============================================================================

-- Contar tablas creadas (debería ser 10)
-- SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';

-- Ver todas las tablas
-- SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;

-- Ver índices
-- SELECT * FROM pg_indexes WHERE schemaname = 'public';

-- Ver políticas RLS
-- SELECT schemaname, tablename, policyname FROM pg_policies WHERE schemaname = 'public';

-- ============================================================================
-- FIN DEL SCRIPT
-- ============================================================================
