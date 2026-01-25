-- Usa snake_case para máxima compatibilidad con Supabase/Postgres
ALTER TABLE messages
ADD COLUMN chat_id uuid REFERENCES chats(id) ON DELETE CASCADE;