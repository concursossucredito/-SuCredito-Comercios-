-- Sucrédito Comercios v2: múltiples categorías por comercio
-- Ejecutar una sola vez en Supabase SQL Editor antes de usar el nuevo administrador.
create table if not exists public.comercios_categorias_relacion (
  comercio_id uuid not null references public.comercios(id) on delete cascade,
  categoria_id uuid not null references public.comercios_categorias(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (comercio_id, categoria_id)
);
create index if not exists idx_comercios_categorias_relacion_categoria
  on public.comercios_categorias_relacion (categoria_id);
alter table public.comercios_categorias_relacion enable row level security;
drop policy if exists "Public read comercio category relations" on public.comercios_categorias_relacion;
create policy "Public read comercio category relations" on public.comercios_categorias_relacion
  for select using (true);
drop policy if exists "Admins manage comercio category relations" on public.comercios_categorias_relacion;
create policy "Admins manage comercio category relations" on public.comercios_categorias_relacion
  for all using (exists (select 1 from public.comercios_admins a where a.user_id=auth.uid() and a.activo=true))
  with check (exists (select 1 from public.comercios_admins a where a.user_id=auth.uid() and a.activo=true));
insert into public.comercios_categorias_relacion (comercio_id,categoria_id)
select id,categoria_id from public.comercios where categoria_id is not null
on conflict do nothing;
grant select on public.comercios_categorias_relacion to anon,authenticated;
grant insert,update,delete on public.comercios_categorias_relacion to authenticated;
