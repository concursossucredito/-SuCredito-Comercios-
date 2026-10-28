-- Ejecutar una sola vez en Supabase SQL Editor.
-- Configuración editable del logo y el hero de la página pública.

create table if not exists public.comercios_configuracion_v2 (
  clave text primary key,
  valor text not null default '',
  actualizado_en timestamptz not null default now()
);

alter table public.comercios_configuracion_v2 enable row level security;

drop policy if exists "config v2 lectura publica" on public.comercios_configuracion_v2;
create policy "config v2 lectura publica"
on public.comercios_configuracion_v2
for select to anon, authenticated
using (true);

drop policy if exists "config v2 admin inserta" on public.comercios_configuracion_v2;
create policy "config v2 admin inserta"
on public.comercios_configuracion_v2
for insert to authenticated
with check (
  exists (
    select 1 from public.comercios_admins a
    where a.user_id = auth.uid() and a.activo = true
  )
);

drop policy if exists "config v2 admin actualiza" on public.comercios_configuracion_v2;
create policy "config v2 admin actualiza"
on public.comercios_configuracion_v2
for update to authenticated
using (
  exists (
    select 1 from public.comercios_admins a
    where a.user_id = auth.uid() and a.activo = true
  )
)
with check (
  exists (
    select 1 from public.comercios_admins a
    where a.user_id = auth.uid() and a.activo = true
  )
);

insert into public.comercios_configuracion_v2(clave,valor) values
('logo_url','https://concursossucredito.github.io/-SuCredito-Comercios-/logo.png'),
('hero_eyebrow','Comprá cerca tuyo'),
('hero_title','Encontrá tus comercios favoritos.'),
('hero_text','Descubrí dónde comprar con tu Sucrédito, explorá los rubros y consultá las cuotas disponibles en cada comercio.'),
('hero_image_url','')
on conflict (clave) do nothing;

select clave, valor from public.comercios_configuracion_v2 order by clave;
