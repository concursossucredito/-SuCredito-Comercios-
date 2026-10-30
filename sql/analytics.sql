-- Métricas propias para Sucrédito Comercios.
-- Ejecutar en Supabase > SQL Editor. Los eventos se registran desde la página pública.
create table if not exists public.comercios_analytics_events (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  visitor_id uuid not null,
  page_path text not null default '/',
  localidad text,
  provincia text,
  referrer text,
  utm_source text,
  utm_medium text,
  utm_campaign text
);
alter table public.comercios_analytics_events add column if not exists localidad text;
alter table public.comercios_analytics_events add column if not exists provincia text;
alter table public.comercios_analytics_events add column if not exists referrer text;
alter table public.comercios_analytics_events add column if not exists utm_source text;
alter table public.comercios_analytics_events add column if not exists utm_medium text;
alter table public.comercios_analytics_events add column if not exists utm_campaign text;
alter table public.comercios_analytics_events enable row level security;
revoke all on public.comercios_analytics_events from anon, authenticated;
create index if not exists comercios_analytics_events_created_at_idx on public.comercios_analytics_events (created_at desc);
create index if not exists comercios_analytics_events_visitor_day_idx on public.comercios_analytics_events (visitor_id, created_at desc);

create or replace function public.registrar_visita_comercios(
  p_visitor_id uuid, p_page_path text default '/', p_localidad text default null,
  p_provincia text default null, p_referrer text default null,
  p_utm_source text default null, p_utm_medium text default null, p_utm_campaign text default null
) returns void
language plpgsql security definer set search_path = ''
as $$
begin
  if p_visitor_id is null then return; end if;
  insert into public.comercios_analytics_events(visitor_id,page_path,localidad,provincia,referrer,utm_source,utm_medium,utm_campaign)
  values (
    p_visitor_id,
    left(regexp_replace(coalesce(p_page_path,'/'), '[^a-zA-Z0-9/_?=&%-]', '', 'g'), 180),
    left(nullif(p_localidad,''),100), left(nullif(p_provincia,''),100),
    left(nullif(p_referrer,''),300), left(nullif(p_utm_source,''),100),
    left(nullif(p_utm_medium,''),100), left(nullif(p_utm_campaign,''),150)
  );
end;
$$;
revoke all on function public.registrar_visita_comercios(uuid,text,text,text,text,text,text,text) from public;
grant execute on function public.registrar_visita_comercios(uuid,text,text,text,text,text,text,text) to anon, authenticated;

drop function if exists public.obtener_estadisticas_comercios(date,date);
drop function if exists public.obtener_estadisticas_comercios(date,date,text);

create or replace function public.obtener_estadisticas_comercios(
  p_desde timestamptz default (now() - interval '29 days'),
  p_hasta timestamptz default now(),
  p_campana text default null
)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  result jsonb;
  v_desde timestamptz := coalesce(p_desde,now()-interval '29 days');
  v_hasta timestamptz := coalesce(p_hasta,now());
  v_campana text := nullif(trim(p_campana),'');
begin
  if auth.uid() is null or not exists (
    select 1 from public.comercios_admins a
    where a.user_id=auth.uid() and a.activo=true
  ) then raise exception 'No autorizado para consultar estadísticas'; end if;
  if v_hasta <= v_desde then raise exception 'El rango de fecha y hora no es válido'; end if;

  select jsonb_build_object(
    'total_views', count(*),
    'unique_visitors', count(distinct visitor_id),
    'daily', coalesce((
      select jsonb_agg(jsonb_build_object('date',d.dia,'views',d.views,'visitors',d.visitors) order by d.dia)
      from (
        select days.dia::date as dia,count(e.id)::int as views,count(distinct e.visitor_id)::int as visitors
        from generate_series(date_trunc('day',v_desde at time zone 'America/Argentina/Buenos_Aires'),date_trunc('day',v_hasta at time zone 'America/Argentina/Buenos_Aires'),interval '1 day') as days(dia)
        left join public.comercios_analytics_events e
          on e.created_at >= greatest(v_desde, days.dia at time zone 'America/Argentina/Buenos_Aires') and e.created_at < least(v_hasta, (days.dia + interval '1 day') at time zone 'America/Argentina/Buenos_Aires')
          and (v_campana is null or e.utm_campaign=v_campana)
        group by days.dia::date
      ) d
    ),'[]'::jsonb),
    'hourly', coalesce((
      select jsonb_agg(jsonb_build_object('hour',h.hora,'views',h.views,'visitors',h.visitors) order by h.hora)
      from (
        select extract(hour from created_at at time zone 'America/Argentina/Buenos_Aires')::int as hora,count(*)::int as views,
          count(distinct visitor_id)::int as visitors
        from public.comercios_analytics_events
        where created_at >= v_desde and created_at < v_hasta
          and (v_campana is null or utm_campaign=v_campana)
        group by extract(hour from created_at at time zone 'America/Argentina/Buenos_Aires')::int
      ) h
    ),'[]'::jsonb),
    'top_pages', coalesce((
      select jsonb_agg(jsonb_build_object('path',p.page_path,'views',p.views) order by p.views desc)
      from (select page_path,count(*)::int views from public.comercios_analytics_events
        where created_at >= v_desde and created_at < v_hasta
          and (v_campana is null or utm_campaign=v_campana)
        group by page_path order by count(*) desc limit 10) p
    ),'[]'::jsonb),
    'localidades', coalesce((
      select jsonb_agg(jsonb_build_object('nombre',p.nombre,'visitas',p.visitas,'visitantes',p.visitantes) order by p.visitas desc)
      from (select coalesce(nullif(localidad,''),'No identificada') nombre,count(*)::int visitas,
        count(distinct visitor_id)::int visitantes from public.comercios_analytics_events
        where created_at >= v_desde and created_at < v_hasta
          and (v_campana is null or utm_campaign=v_campana)
        group by 1 order by count(*) desc limit 20) p
    ),'[]'::jsonb),
    'provincias', coalesce((
      select jsonb_agg(jsonb_build_object('nombre',p.nombre,'visitas',p.visitas,'visitantes',p.visitantes) order by p.visitas desc)
      from (select coalesce(nullif(provincia,''),'No identificada') nombre,count(*)::int visitas,
        count(distinct visitor_id)::int visitantes from public.comercios_analytics_events
        where created_at >= v_desde and created_at < v_hasta
          and (v_campana is null or utm_campaign=v_campana)
        group by 1 order by count(*) desc limit 20) p
    ),'[]'::jsonb),
    'campaigns', coalesce((
      select jsonb_agg(jsonb_build_object('campana',p.campana,'origen',p.origen,'visitas',p.visitas,'visitantes',p.visitantes) order by p.visitas desc)
      from (select coalesce(nullif(utm_campaign,''),'Sin campaña etiquetada') campana,
        coalesce(nullif(utm_source,''),'Sin origen') origen,count(*)::int visitas,
        count(distinct visitor_id)::int visitantes from public.comercios_analytics_events
        where created_at >= v_desde and created_at < v_hasta
        group by 1,2 order by count(*) desc limit 50) p
    ),'[]'::jsonb)
  ) into result
  from public.comercios_analytics_events
  where created_at >= v_desde and created_at < v_hasta
    and (v_campana is null or utm_campaign=v_campana);
  return result;
end;
$$;
revoke all on function public.obtener_estadisticas_comercios(timestamptz,timestamptz,text) from public, anon;
grant execute on function public.obtener_estadisticas_comercios(timestamptz,timestamptz,text) to authenticated;
