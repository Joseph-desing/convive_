-- ============================================================================
-- SUPABASE SQL - RESET COMPLETO (PELIGROSO - BORRA TODO)
-- Usa SOLO si quieres empezar de cero
-- ============================================================================

-- Deshabilitar RLS temporalmente
ALTER TABLE IF EXISTS messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS chats DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS subscriptions DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS matches DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS swipes DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS property_images DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS properties DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS habits DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS users DISABLE ROW LEVEL SECURITY;

-- Borrar todas las políticas
DROP POLICY IF EXISTS "Users can read own user" ON users;
DROP POLICY IF EXISTS "Users can update own user" ON users;
DROP POLICY IF EXISTS "Profiles are public" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Habits are public" ON habits;
DROP POLICY IF EXISTS "Users can update own habits" ON habits;
DROP POLICY IF EXISTS "Users can insert own habits" ON habits;
DROP POLICY IF EXISTS "Active properties are public" ON properties;
DROP POLICY IF EXISTS "Owners can see own properties" ON properties;
DROP POLICY IF EXISTS "Owners can update own properties" ON properties;
DROP POLICY IF EXISTS "Users can insert properties" ON properties;
DROP POLICY IF EXISTS "Owners can delete own properties" ON properties;
DROP POLICY IF EXISTS "Images of active properties are public" ON property_images;
DROP POLICY IF EXISTS "Owners can see own property images" ON property_images;
DROP POLICY IF EXISTS "Owners can insert property images" ON property_images;
DROP POLICY IF EXISTS "Owners can delete property images" ON property_images;
DROP POLICY IF EXISTS "Users can read own swipes" ON swipes;
DROP POLICY IF EXISTS "Users can insert swipes" ON swipes;
DROP POLICY IF EXISTS "Users can read own matches" ON matches;
DROP POLICY IF EXISTS "Users can update matches they're in" ON matches;
DROP POLICY IF EXISTS "Users can read own chats" ON chats;
DROP POLICY IF EXISTS "Users can read messages from own chats" ON messages;
DROP POLICY IF EXISTS "Users can insert messages to own chats" ON messages;
DROP POLICY IF EXISTS "Users can read own subscriptions" ON subscriptions;
DROP POLICY IF EXISTS "Users can insert own subscriptions" ON subscriptions;

-- Borrar tablas
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS chats CASCADE;
DROP TABLE IF EXISTS subscriptions CASCADE;
DROP TABLE IF EXISTS matches CASCADE;
DROP TABLE IF EXISTS swipes CASCADE;
DROP TABLE IF EXISTS property_images CASCADE;
DROP TABLE IF EXISTS properties CASCADE;
DROP TABLE IF EXISTS habits CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Borrar índices
DROP INDEX IF EXISTS idx_profiles_user_id;
DROP INDEX IF EXISTS idx_habits_user_id;
DROP INDEX IF EXISTS idx_properties_owner_id;
DROP INDEX IF EXISTS idx_properties_is_active;
DROP INDEX IF EXISTS idx_properties_available_from;
DROP INDEX IF EXISTS idx_property_images_property_id;
DROP INDEX IF EXISTS idx_swipes_swiper_id;
DROP INDEX IF EXISTS idx_swipes_target_user_id;
DROP INDEX IF EXISTS idx_swipes_created_at;
DROP INDEX IF EXISTS idx_matches_user_a_id;
DROP INDEX IF EXISTS idx_matches_user_b_id;
DROP INDEX IF EXISTS idx_matches_created_at;
DROP INDEX IF EXISTS idx_chats_match_id;
DROP INDEX IF EXISTS idx_messages_chat_id;
DROP INDEX IF EXISTS idx_messages_sender_id;
DROP INDEX IF EXISTS idx_messages_created_at;
DROP INDEX IF EXISTS idx_subscriptions_user_id;
DROP INDEX IF EXISTS idx_subscriptions_status;

-- ============================================================================
-- AHORA EJECUTA: SQL_COMPLETO_SUPABASE.sql
-- ============================================================================
