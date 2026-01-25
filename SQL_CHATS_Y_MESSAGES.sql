-- ===================================
-- TABLAS CHATS Y MESSAGES - Setup completo
-- Ejecuta esto en SQL Editor de Supabase
-- ===================================

-- 1. Crear tabla CHATS
CREATE TABLE IF NOT EXISTS chats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Un chat por match
  UNIQUE(match_id)
);

-- 2. Crear tabla MESSAGES
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Índices para CHATS
CREATE INDEX IF NOT EXISTS idx_chats_match_id ON chats(match_id);

-- 4. Índices para MESSAGES
CREATE INDEX IF NOT EXISTS idx_messages_chat_id ON messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at);

-- 5. Habilitar RLS en CHATS
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;

-- 6. Habilitar RLS en MESSAGES
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- 7. Eliminar políticas existentes de CHATS
DROP POLICY IF EXISTS "Users can view chats from their matches" ON chats;
DROP POLICY IF EXISTS "Users can create chats for their matches" ON chats;

-- 8. Eliminar políticas existentes de MESSAGES
DROP POLICY IF EXISTS "Users can view messages from their chats" ON messages;
DROP POLICY IF EXISTS "Users can send messages to their chats" ON messages;
DROP POLICY IF EXISTS "Users can update their own messages" ON messages;
DROP POLICY IF EXISTS "Users can delete their own messages" ON messages;

-- 9. Políticas RLS para CHATS

-- Los usuarios pueden ver chats de sus matches
CREATE POLICY "Users can view chats from their matches"
ON chats
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM matches m
    WHERE m.id = chats.match_id
      AND (m.user_a_id = auth.uid() OR m.user_b_id = auth.uid())
  )
);

-- Los usuarios pueden crear chats para sus matches
CREATE POLICY "Users can create chats for their matches"
ON chats
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM matches m
    WHERE m.id = chats.match_id
      AND (m.user_a_id = auth.uid() OR m.user_b_id = auth.uid())
  )
);

-- 10. Políticas RLS para MESSAGES

-- Los usuarios pueden ver mensajes de sus chats
CREATE POLICY "Users can view messages from their chats"
ON messages
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM chats c
    INNER JOIN matches m ON m.id = c.match_id
    WHERE c.id = messages.chat_id
      AND (m.user_a_id = auth.uid() OR m.user_b_id = auth.uid())
  )
);

-- Los usuarios pueden enviar mensajes a sus chats
CREATE POLICY "Users can send messages to their chats"
ON messages
FOR INSERT
TO authenticated
WITH CHECK (
  sender_id = auth.uid()
  AND EXISTS (
    SELECT 1 FROM chats c
    INNER JOIN matches m ON m.id = c.match_id
    WHERE c.id = messages.chat_id
      AND (m.user_a_id = auth.uid() OR m.user_b_id = auth.uid())
  )
);

-- Los usuarios pueden actualizar sus propios mensajes
CREATE POLICY "Users can update their own messages"
ON messages
FOR UPDATE
TO authenticated
USING (sender_id = auth.uid())
WITH CHECK (sender_id = auth.uid());

-- Los usuarios pueden eliminar sus propios mensajes
CREATE POLICY "Users can delete their own messages"
ON messages
FOR DELETE
TO authenticated
USING (sender_id = auth.uid());

-- 11. Verificar las tablas
SELECT 'Tablas creadas correctamente' as status;

SELECT 'Chats existentes:' as info, COUNT(*) as total FROM chats;
SELECT 'Messages existentes:' as info, COUNT(*) as total FROM messages;
