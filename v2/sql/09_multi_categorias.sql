-- Sucrédito Comercios v2: múltiples categorías por comercio
-- Ejecutar una sola vez en Supabase SQL Editor antes de usar el nuevo administrador.
-- Las columnas heredan automáticamente los tipos reales de las tablas existentes.
create table if not exists public.comercios_categorias_relacion as
select c.id as comercio_id, cat.id as categoria_id, now()::timestamptz as created_at
from public.comercios c
cross join public.comercios_categorias cat
where false;

alter table public.comercios_categorias_relacion
  alter column comercio_id set not null,
  alter column categoria_id set not null,
  alter column created_at set default now();

do $$
begin
  if not exists (select 1 from pg_constraint where conname='comercios_categorias_relacion_pk') then
    alter table public.comercios_categorias_relacion
      add constraint comercios_categorias_relacion_pk primary key (comercio_id,categoria_id);
  end if;
  if not exists (select 1 from pg_constraint where conname='comercios_categorias_relacion_comercio_fk') then
    alter table public.comercios_categorias_relacion
      add constraint comercios_categorias_relacion_comercio_fk
      foreign key (comercio_id) references public.comercios(id) on delete cascade;
  end if;
  if not exists (select 1 from pg_constraint where conname='comercios_categorias_relacion_categoria_fk') then
    alter table public.comercios_categorias_relacion
      add constraint comercios_categorias_relacion_categoria_fk
      foreign key (categoria_id) references public.comercios_categorias(id) on delete cascade;
  end if;
end $$;

create index if not exists idx_comercios_categorias_relacion_categoria
  on public.comercios_categorias_relacion (categoria_id);

alter table public.comercios_categorias_relacion enable row level security;

drop policy if exists "Public read comercio category relations" on public.comercios_categorias_relacion;
create policy "Public read comercio category relations"
  on public.comercios_categorias_relacion for select using (true);

drop policy if exists "Admins manage comercio category relations" on public.comercios_categorias_relacion;
create policy "Admins manage comercio category relations"
  on public.comercios_categorias_relacion for all
  using (exists (select 1 from public.comercios_admins a where a.user_id=auth.uid() and a.activo=true))
  with check (exists (select 1 from public.comercios_admins a where a.user_id=auth.uid() and a.activo=true));

insert into public.comercios_categorias_relacion (comercio_id,categoria_id)
select id,categoria_id from public.comercios where categoria_id is not null
on conflict do nothing;

grant select on public.comercios_categorias_relacion to anon,authenticated;
grant insert,update,delete on public.comercios_categorias_relacion to authenticated;
