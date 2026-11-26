-- Agrega un enlace externo opcional para cada comercio.
-- Ejecutar una sola vez en Supabase SQL Editor.
ALTER TABLE public.comercios
ADD COLUMN IF NOT EXISTS web_url text;
