-- Complemento de migración: comercios de la categoría Farmacia.
-- Ejecutar una sola vez o repetir con seguridad: usa ON CONFLICT para actualizar.
-- No elimina ni modifica comercios de otras categorías.

update public.comercios_categorias
set nombre = 'Farmacia', activo = true
where slug = 'farmacia';

with datos(nombre, slug, logo, localidades) as (
  values
    ('Farmacia Alvarado','farmacia-alvarado','alvarado.png',array['Orán']::text[]),
    ('Plazoleta','plazoleta','plazoleta.png',array['Tucumán']::text[]),
    ('Farmacia Del Pueblo','farmacia-del-pueblo','del_pueblo.png',array['Tucumán']::text[]),
    ('Sudamericana','sudamericana','sudamericana.png',array['Salta']::text[]),
    ('San Francisco','san-francisco','san_francisco.png',array['Jujuy']::text[]),
    ('Farmacity','farmacity','farmacity.png',array['Córdoba','Salta','Jujuy','Santiago']::text[]),
    ('Farmar','farmar','farmar.png',array['Córdoba','Tucumán','Salta','San Pedro','Jujuy','Santiago']::text[]),
    ('La Plaza','la-plaza','la_plaza.png',array['Santiago']::text[]),
    ('La Esquina','la-esquina','la_esquina.png',array['Santiago']::text[])
)
insert into public.comercios(nombre, slug, categoria_id, logo_url, localidades, activo, orden)
select d.nombre, d.slug, c.id,
       'https://concursossucredito.github.io/-SuCredito-Comercios-/' || d.logo,
       d.localidades, true, 0
from datos d
cross join public.comercios_categorias c
where c.slug = 'farmacia'
on conflict (slug) do update set
  nombre = excluded.nombre,
  categoria_id = excluded.categoria_id,
  logo_url = excluded.logo_url,
  localidades = excluded.localidades,
  activo = true;

-- Cuotas por localidad, respetando las opciones definidas en el HTML original.
with datos(slug, localidad, cantidad) as (
  values
    ('farmacity','Córdoba',3),
    ('farmar','Córdoba',3),
    ('farmar','Tucumán',3),
    ('plazoleta','Tucumán',3),
    ('plazoleta','Tucumán',5),
    ('farmacia-del-pueblo','Tucumán',3),
    ('farmacia-del-pueblo','Tucumán',6),
    ('farmacia-del-pueblo','Tucumán',9),
    ('farmacia-alvarado','Orán',3),
    ('farmacia-alvarado','Orán',6),
    ('farmacity','Salta',3),
    ('farmar','Salta',3),
    ('sudamericana','Salta',3),
    ('farmar','San Pedro',3),
    ('san-francisco','Jujuy',3),
    ('farmacity','Jujuy',3),
    ('farmar','Jujuy',3),
    ('la-esquina','Santiago',3),
    ('la-esquina','Santiago',6),
    ('la-plaza','Santiago',3),
    ('farmar','Santiago',3),
    ('farmacity','Santiago',3)
)
insert into public.comercios_cuotas(comercio_id, cantidad, etiqueta, localidad, activa, orden)
select c.id, d.cantidad, d.cantidad || ' cuotas sin interés', d.localidad, true, d.cantidad
from datos d
join public.comercios c on c.slug = d.slug
on conflict (comercio_id, cantidad, etiqueta, localidad)
do update set activa = true, orden = excluded.orden;

-- Verificación: deberían aparecer 9 comercios de farmacia.
select c.nombre, c.localidades, q.localidad as localidad_cuota,
       q.cantidad, q.etiqueta
from public.comercios c
join public.comercios_categorias cat on cat.id = c.categoria_id
left join public.comercios_cuotas q on q.comercio_id = c.id and q.activa = true
where cat.slug = 'farmacia' and c.activo = true
order by c.nombre, q.localidad, q.cantidad;
