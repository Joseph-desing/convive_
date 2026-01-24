-- ==================== TABLA CHATS ====================
CREATE TABLE IF NOT EXISTS chats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT fk_chats_match FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE
);

-- Índices para mejor performance
CREATE INDEX IF NOT EXISTS idx_chats_match_id ON chats(match_id);
CREATE INDEX IF NOT EXISTS idx_chats_created_at ON chats(created_at DESC);

-- ==================== TABLA MESSAGES ====================
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id UUID NOT NULL,
  sender_id UUID NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT fk_messages_chat FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE,
  CONSTRAINT fk_messages_sender FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Índices para mejor performance
CREATE INDEX IF NOT EXISTS idx_messages_chat_id ON messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);

-- ==================== HABILITAR REALTIME ====================
ALTER PUBLICATION supabase_realtime ADD TABLE chats;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;

-- ==================== POLÍTICAS RLS ====================
-- Habilitar RLS
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Política para chats: los usuarios pueden ver chats de sus matches
CREATE POLICY "Usuarios pueden ver sus chats"
  ON chats FOR SELECT
  USING (
    match_id IN (
      SELECT id FROM matches
      WHERE user_a = auth.uid() OR user_b = auth.uid()
    )
  );

-- Política para crear chats (si es necesario manualmente)
CREATE POLICY "Usuarios pueden crear chats de sus matches"
  ON chats FOR INSERT
  WITH CHECK (
    match_id IN (
      SELECT id FROM matches
      WHERE user_a = auth.uid() OR user_b = auth.uid()
    )
  );

-- Política para mensajes: los usuarios pueden ver mensajes de sus chats
CREATE POLICY "Usuarios pueden ver mensajes de sus chats"
  ON messages FOR SELECT
  USING (
    chat_id IN (
      SELECT id FROM chats
      WHERE match_id IN (
        SELECT id FROM matches
        WHERE user_a = auth.uid() OR user_b = auth.uid()
      )
    )
  );

-- Política para enviar mensajes
CREATE POLICY "Usuarios pueden enviar mensajes a sus chats"
  ON messages FOR INSERT
  WITH CHECK (
    sender_id = auth.uid() AND
    chat_id IN (
      SELECT id FROM chats
      WHERE match_id IN (
        SELECT id FROM matches
        WHERE user_a = auth.uid() OR user_b = auth.uid()
      )
    )
  );

-- Política para actualizar mensajes propios
CREATE POLICY "Usuarios pueden actualizar sus mensajes"
  ON messages FOR UPDATE
  USING (sender_id = auth.uid())
  WITH CHECK (sender_id = auth.uid());

-- Política para eliminar mensajes propios
CREATE POLICY "Usuarios pueden eliminar sus mensajes"
  ON messages FOR DELETE
  USING (sender_id = auth.uid());
