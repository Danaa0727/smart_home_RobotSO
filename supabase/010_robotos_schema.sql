create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  display_name text,
  role text not null default 'GUEST' check (role in ('ADMIN', 'USER', 'GUEST')),
  created_at timestamptz not null default now()
);

create or replace function public.app_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid()
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, display_name, role)
  values (new.id, new.email, split_part(new.email, '@', 1), 'GUEST')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

insert into public.profiles (id, email, display_name, role)
select id, email, split_part(email, '@', 1), 'GUEST' from auth.users
on conflict (id) do nothing;

create table if not exists public.processes (
  id bigint generated always as identity primary key,
  pid integer not null unique,
  name text not null,
  priority integer not null default 3 check (priority between 1 and 5),
  state text not null default 'NEW' check (state in ('NEW', 'READY', 'RUNNING', 'WAITING', 'TERMINATED')),
  cpu_required integer not null default 10 check (cpu_required > 0),
  cpu_remaining integer not null default 10 check (cpu_remaining >= 0),
  cpu_usage numeric not null default 0,
  memory_kb integer not null default 16 check (memory_kb > 0),
  is_critical boolean not null default false,
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.devices (
  id bigint generated always as identity primary key,
  name text not null unique,
  type text not null check (type in ('camera', 'sensor', 'motor', 'comms', 'power', 'nav')),
  status text not null default 'ONLINE' check (status in ('ONLINE', 'OFFLINE', 'ERROR', 'DEGRADED')),
  priority integer not null default 3 check (priority between 1 and 5),
  last_event text,
  updated_at timestamptz not null default now()
);

create table if not exists public.events (
  id bigint generated always as identity primary key,
  type text not null,
  source text not null,
  severity text not null default 'INFO' check (severity in ('INFO', 'WARNING', 'ERROR', 'CRITICAL')),
  description text not null,
  resolved boolean not null default false,
  user_id uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.system_settings (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.logs add column if not exists event_type text;
alter table public.logs add column if not exists user_id uuid references auth.users (id) on delete set null;

truncate table public.memory_blocks, public.files, public.logs, public.surveillance_clips,
  public.energy_usage, public.energy_devices restart identity cascade;

do $$
declare
  t text;
  p record;
begin
  foreach t in array array[
    'profiles', 'processes', 'devices', 'events', 'system_settings',
    'memory_blocks', 'files', 'logs', 'surveillance_clips',
    'energy_devices', 'energy_usage', 'experiment_results'
  ]
  loop
    execute format('alter table public.%I enable row level security', t);
    for p in select policyname from pg_policies where schemaname = 'public' and tablename = t loop
      execute format('drop policy %I on public.%I', p.policyname, t);
    end loop;
  end loop;
end $$;

create policy "perfil propio o admin" on public.profiles for select to authenticated
  using (id = auth.uid() or public.app_role() = 'ADMIN');
create policy "solo admin cambia roles" on public.profiles for update to authenticated
  using (public.app_role() = 'ADMIN') with check (public.app_role() = 'ADMIN');

create policy "admin y user leen procesos" on public.processes for select to authenticated
  using (public.app_role() in ('ADMIN', 'USER'));
create policy "solo admin crea procesos" on public.processes for insert to authenticated
  with check (public.app_role() = 'ADMIN');
create policy "solo admin elimina procesos" on public.processes for delete to authenticated
  using (public.app_role() = 'ADMIN');
create policy "cambio de estado de procesos" on public.processes for update to authenticated
  using (public.app_role() = 'ADMIN' or (public.app_role() = 'USER' and is_critical = false))
  with check (public.app_role() = 'ADMIN' or (public.app_role() = 'USER' and is_critical = false));

create policy "todos leen dispositivos" on public.devices for select to authenticated
  using (public.app_role() is not null);
create policy "solo admin escribe dispositivos" on public.devices for all to authenticated
  using (public.app_role() = 'ADMIN') with check (public.app_role() = 'ADMIN');

create policy "admin y user leen eventos" on public.events for select to authenticated
  using (public.app_role() in ('ADMIN', 'USER'));
create policy "todos registran eventos" on public.events for insert to authenticated
  with check (public.app_role() is not null);
create policy "solo admin resuelve eventos" on public.events for update to authenticated
  using (public.app_role() = 'ADMIN') with check (public.app_role() = 'ADMIN');

create policy "todos leen configuracion" on public.system_settings for select to authenticated
  using (public.app_role() is not null);
create policy "solo admin cambia configuracion" on public.system_settings for all to authenticated
  using (public.app_role() = 'ADMIN') with check (public.app_role() = 'ADMIN');

create policy "solo admin lee logs" on public.logs for select to authenticated
  using (public.app_role() = 'ADMIN');
create policy "todos escriben logs" on public.logs for insert to authenticated
  with check (public.app_role() is not null);

create policy "admin y user leen archivos" on public.files for select to authenticated
  using (public.app_role() in ('ADMIN', 'USER'));
create policy "escritura de archivos" on public.files for insert to authenticated
  with check (public.app_role() = 'ADMIN' or (public.app_role() = 'USER' and path like '/users/%'));
create policy "modificar archivos" on public.files for update to authenticated
  using (public.app_role() = 'ADMIN' or (public.app_role() = 'USER' and path like '/users/%'))
  with check (public.app_role() = 'ADMIN' or (public.app_role() = 'USER' and path like '/users/%'));
create policy "solo admin elimina archivos" on public.files for delete to authenticated
  using (public.app_role() = 'ADMIN');

do $$
declare
  t text;
begin
  foreach t in array array[
    'memory_blocks', 'surveillance_clips', 'energy_devices', 'energy_usage', 'experiment_results'
  ]
  loop
    execute format(
      'create policy "admin y user leen" on public.%I for select to authenticated using (public.app_role() in (''ADMIN'', ''USER''))', t);
    execute format(
      'create policy "solo admin escribe" on public.%I for all to authenticated using (public.app_role() = ''ADMIN'') with check (public.app_role() = ''ADMIN'')', t);
  end loop;
end $$;

insert into public.system_settings (key, value) values
  ('scheduler', '"priority"'),
  ('quantum', '3'),
  ('tick_ms', '800'),
  ('memory_total_kb', '1024'),
  ('block_kb', '16'),
  ('battery_saver_pct', '30'),
  ('battery_critical_pct', '15')
on conflict (key) do update set value = excluded.value, updated_at = now();

insert into public.processes (pid, name, priority, state, cpu_required, cpu_remaining, memory_kb, is_critical) values
  (1, 'motor_control', 1, 'RUNNING', 30, 22, 96, true),
  (2, 'obstacle_detection', 1, 'READY', 25, 25, 128, true),
  (3, 'navigation', 2, 'READY', 40, 40, 160, true),
  (4, 'camera_stream', 3, 'WAITING', 20, 20, 192, false),
  (5, 'ai_vision', 4, 'READY', 35, 35, 224, false),
  (6, 'telemetry', 5, 'NEW', 15, 15, 64, false);

insert into public.memory_blocks (owner, start_kb, size_kb) values
  ('kernel', 0, 128),
  ('P1', 128, 96),
  ('P2', 224, 128),
  ('P3', 352, 160),
  ('P4', 512, 192),
  ('P5', 704, 224),
  ('P6', 928, 64);

insert into public.devices (name, type, status, priority, last_event) values
  ('Cámara frontal', 'camera', 'ONLINE', 3, 'Inicio normal'),
  ('Sensor de distancia', 'sensor', 'ONLINE', 1, 'Inicio normal'),
  ('Motor izquierdo', 'motor', 'ONLINE', 1, 'Inicio normal'),
  ('Motor derecho', 'motor', 'ONLINE', 1, 'Inicio normal'),
  ('Módulo de comunicación', 'comms', 'ONLINE', 2, 'Inicio normal'),
  ('Batería', 'power', 'ONLINE', 1, 'Inicio normal'),
  ('GPS y navegación', 'nav', 'ONLINE', 2, 'Inicio normal');

insert into public.files (path, content, size_bytes)
select v.path, v.content, octet_length(v.content)
from (values
  ('/system/kernel.cfg', 'scheduler=priority;quantum=3'),
  ('/apps/navigation.app', 'ruta=patrulla_casa'),
  ('/drivers/motor.drv', 'driver motor v1.0'),
  ('/config/robot.json', '{"nombre":"RobotOS","tipo":"robot autonomo"}'),
  ('/users/admin/notas.txt', 'Notas del administrador'),
  ('/logs/system.log', 'Sistema iniciado correctamente')
) as v(path, content);

insert into public.logs (level, source, message, event_type) values
  ('INFO', 'kernel', 'Arranque del sistema completado', 'BOOT'),
  ('INFO', 'scheduler', 'Planificador Prioridad activo', 'SCHEDULER'),
  ('INFO', 'memory', 'Memoria total 1024 KB, kernel reservado 128 KB', 'MEMORY'),
  ('WARNING', 'comms', 'Latencia alta en el módulo de comunicación', 'DEVICE');

insert into public.events (type, source, severity, description, resolved) values
  ('BOOT', 'kernel', 'INFO', 'Sistema iniciado', true),
  ('DEVICE', 'comms', 'WARNING', 'Latencia alta en el módulo de comunicación', true);
