-- Agrega la columna chatId a la tabla messages y la define como clave foránea a chats.id
ALTER TABLE messages
ADD COLUMN chatId uuid REFERENCES chats(id) ON DELETE CASCADE;