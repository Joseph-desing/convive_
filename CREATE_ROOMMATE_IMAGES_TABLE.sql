-- Crear tabla roommate_search_images similar a property_images
CREATE TABLE IF NOT EXISTS public.roommate_search_images (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    search_id uuid NOT NULL REFERENCES public.roommate_searches(id) ON DELETE CASCADE,
    image_url text NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(search_id, image_url)
);

-- Crear índice para búsquedas rápidas
CREATE INDEX IF NOT EXISTS idx_roommate_search_images_search_id 
ON public.roommate_search_images(search_id);

-- Habilitar RLS
ALTER TABLE public.roommate_search_images ENABLE ROW LEVEL SECURITY;

-- Política para que usuarios autenticados puedan leer todas las imágenes
CREATE POLICY "Allow public read access" 
ON public.roommate_search_images FOR SELECT 
USING (true);

-- Política para que usuarios autenticados puedan crear imágenes
CREATE POLICY "Allow authenticated insert" 
ON public.roommate_search_images FOR INSERT 
WITH CHECK (auth.role() = 'authenticated');

-- Política para que usuarios solo puedan eliminar sus propias imágenes
CREATE POLICY "Allow users delete own images" 
ON public.roommate_search_images FOR DELETE 
USING (
    search_id IN (
        SELECT id FROM public.roommate_searches 
        WHERE user_id = auth.uid()
    )
);
