-- Ver TODOS los swipes que existen
SELECT 
  swiper_id,
  target_user_id,
  direction,
  created_at
FROM swipes
ORDER BY created_at DESC;

-- Ver si hay swipes mutuos (ambos se dieron like)
SELECT 
  s1.swiper_id as user_a,
  s1.target_user_id as user_b,
  'Ambos se dieron like' as status
FROM swipes s1
INNER JOIN swipes s2 
  ON s1.swiper_id = s2.target_user_id 
  AND s1.target_user_id = s2.swiper_id
WHERE s1.direction = 'like'
  AND s2.direction = 'like';

-- Si hay swipes mutuos, crear los matches automáticamente
INSERT INTO matches (user_a_id, user_b_id, compatibility_score)
SELECT DISTINCT
  s1.swiper_id,
  s1.target_user_id,
  75.0 -- Compatibilidad de prueba
FROM swipes s1
INNER JOIN swipes s2 
  ON s1.swiper_id = s2.target_user_id 
  AND s1.target_user_id = s2.swiper_id
WHERE s1.direction = 'like'
  AND s2.direction = 'like'
  AND NOT EXISTS (
    -- Evitar duplicados
    SELECT 1 FROM matches m
    WHERE (m.user_a_id = s1.swiper_id AND m.user_b_id = s1.target_user_id)
       OR (m.user_a_id = s1.target_user_id AND m.user_b_id = s1.swiper_id)
  );

-- Verificar cuántos matches se crearon
SELECT 
  'Matches creados' as status,
  COUNT(*) as total
FROM matches;
