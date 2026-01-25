-- ===================================
-- TABLA CHAT_READS para mensajes no leídos tipo Messenger
-- Ejecuta esto en el SQL Editor de Supabase
-- ===================================

CREATE TABLE IF NOT EXISTS chat_reads (
  chat_id UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  last_read_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (chat_id, user_id)
);

-- Permitir que cada usuario vea y actualice solo su propio registro
ALTER TABLE chat_reads ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their chat_reads" ON chat_reads;
CREATE POLICY "Users can view their chat_reads"
  ON chat_reads FOR SELECT TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update their chat_reads" ON chat_reads;
CREATE POLICY "Users can update their chat_reads"
  ON chat_reads FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert their chat_reads" ON chat_reads;
CREATE POLICY "Users can insert their chat_reads"
  ON chat_reads FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

-- Verificar
SELECT * FROM chat_reads LIMIT 10;
