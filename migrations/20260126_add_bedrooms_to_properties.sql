-- Add bedrooms column to properties
ALTER TABLE public.properties ADD COLUMN bedrooms integer;
-- Optional: set default to 1 for existing rows
UPDATE public.properties SET bedrooms = 1 WHERE bedrooms IS NULL;
-- Consider adding NOT NULL with default if desired:
-- ALTER TABLE public.properties ALTER COLUMN bedrooms SET DEFAULT 1;
-- ALTER TABLE public.properties ALTER COLUMN bedrooms SET NOT NULL;