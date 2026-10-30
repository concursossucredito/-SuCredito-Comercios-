-- Estadísticas de visitas para Sucrédito Comercios
-- Ejecutar una sola vez en Supabase > SQL Editor.
create table if not exists public.comercios_analytics_events (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  visitor_id uuid not null,
  page_path text not null default '/'
);

alter table public.comercios_analytics_events enable row level security;
revoke all on public.comercios_analytics_events from anon, authenticated;

create index if not exists comercios_analytics_events_created_at_idx
  on public.comercios_analytics_events (created_at desc);
create index if not exists comercios_analytics_events_visitor_day_idx
  on public.comercios_analytics_events (visitor_id, created_at desc);

create or replace function public.registrar_visita_comercios(p_visitor_id uuid, p_page_path text default '/')
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_visitor_id is null then return; end if;
  insert into public.comercios_analytics_events(visitor_id, page_path)
  values (
    p_visitor_id,
    left(regexp_replace(coalesce(p_page_path, '/'), '[^a-zA-Z0-9/_-]', '', 'g'), 180)
  );
end;
$$;

revoke all on function public.registrar_visita_comercios(uuid, text) from public;
grant execute on function public.registrar_visita_comercios(uuid, text) to anon, authenticated;

create or replace function public.obtener_estadisticas_comercios()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  result jsonb;
begin
  if auth.uid() is null or not exists (
    select 1 from public.comercios_admins a
    where a.user_id = auth.uid() and a.activo = true
  ) then
    raise exception 'No autorizado para consultar estadísticas';
  end if;

  select jsonb_build_object(
    'total_views', (select count(*) from public.comercios_analytics_events),
    'unique_visitors', (select count(distinct visitor_id) from public.comercios_analytics_events),
    'views_30_days', (select count(*) from public.comercios_analytics_events where created_at >= now() - interval '30 days'),
    'visitors_30_days', (select count(distinct visitor_id) from public.comercios_analytics_events where created_at >= now() - interval '30 days'),
    'daily', coalesce((
      select jsonb_agg(jsonb_build_object('date', d.day, 'views', d.views, 'visitors', d.visitors) order by d.day)
      from (
        select day::date as day,
               count(e.id)::int as views,
               count(distinct e.visitor_id)::int as visitors
        from generate_series(current_date - 29, current_date, interval '1 day') as day
        left join public.comercios_analytics_events e
          on e.created_at >= day and e.created_at < day + interval '1 day'
        group by day::date
      ) d
    ), '[]'::jsonb),
    'top_pages', coalesce((
      select jsonb_agg(jsonb_build_object('path', p.page_path, 'views', p.views) order by p.views desc)
      from (
        select page_path, count(*)::int as views
        from public.comercios_analytics_events
        where created_at >= now() - interval '30 days'
        group by page_path
        order by count(*) desc
        limit 8
      ) p
    ), '[]'::jsonb)
  ) into result;
  return result;
end;
$$;

revoke all on function public.obtener_estadisticas_comercios() from public, anon;
grant execute on function public.obtener_estadisticas_comercios() to authenticated;
