-- Actualizar el constraint de work_mode para que acepte los valores correctos
-- Ejecuta esto en el SQL Editor de Supabase si el constraint está mal configurado

-- Primero, eliminar el constraint antiguo
ALTER TABLE habits DROP CONSTRAINT IF EXISTS habits_work_mode_check;

-- Crear el nuevo constraint con los valores correctos
ALTER TABLE habits ADD CONSTRAINT habits_work_mode_check 
CHECK (work_mode IN ('remote', 'presencial', 'hibrido'));

-- Verificar que no haya valores inválidos actuales
SELECT id, user_id, work_mode 
FROM habits 
WHERE work_mode NOT IN ('remote', 'presencial', 'hibrido');

-- Si encuentras registros con valores incorrectos, actualízalos:
-- UPDATE habits SET work_mode = 'hibrido' WHERE work_mode = 'hybrid';
-- UPDATE habits SET work_mode = 'presencial' WHERE work_mode = 'office';
