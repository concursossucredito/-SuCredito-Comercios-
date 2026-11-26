-- Permite guardar un logo propio por categoría de comercio.
ALTER TABLE public.comercios_categorias
ADD COLUMN IF NOT EXISTS logo_url text;
