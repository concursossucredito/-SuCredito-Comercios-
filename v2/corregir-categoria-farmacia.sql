-- Corregir el nombre visible de la categoría en Supabase.
-- No elimina comercios ni modifica logos, localidades o cuotas.
update public.comercios_categorias
set nombre = 'Farmacia', activo = true
where slug = 'farmacia';

-- Verificación
select id, nombre, slug, activo
from public.comercios_categorias
where slug = 'farmacia';
