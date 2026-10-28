-- Ejecutar una sola vez en Supabase > SQL Editor.
-- Crea el almacenamiento para que el panel permita subir imágenes desde la PC.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'comercios-imagenes',
  'comercios-imagenes',
  true,
  10485760,
  array['image/png','image/jpeg','image/webp','image/gif','image/svg+xml']
)
on conflict (id) do update
set public = true,
    file_size_limit = 10485760,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Imagenes comercios lectura publica" on storage.objects;
create policy "Imagenes comercios lectura publica"
on storage.objects for select
to anon, authenticated
using (bucket_id = 'comercios-imagenes');

drop policy if exists "Admins suben imagenes comercios" on storage.objects;
create policy "Admins suben imagenes comercios"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'comercios-imagenes'
  and exists (
    select 1 from public.comercios_admins a
    where a.user_id = auth.uid() and a.activo = true
  )
);

drop policy if exists "Admins actualizan imagenes comercios" on storage.objects;
create policy "Admins actualizan imagenes comercios"
on storage.objects for update
to authenticated
using (
  bucket_id = 'comercios-imagenes'
  and exists (
    select 1 from public.comercios_admins a
    where a.user_id = auth.uid() and a.activo = true
  )
)
with check (
  bucket_id = 'comercios-imagenes'
  and exists (
    select 1 from public.comercios_admins a
    where a.user_id = auth.uid() and a.activo = true
  )
);

drop policy if exists "Admins borran imagenes comercios" on storage.objects;
create policy "Admins borran imagenes comercios"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'comercios-imagenes'
  and exists (
    select 1 from public.comercios_admins a
    where a.user_id = auth.uid() and a.activo = true
  )
);
