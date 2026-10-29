-- Пространство: таблица для синхронизации. Вставьте целиком в SQL Editor и нажмите Run.
create table if not exists public.items (
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  kind       text not null,
  id         text not null,
  data       jsonb,
  deleted    boolean not null default false,
  updated_at timestamptz not null default now(),
  synced_at  timestamptz not null default clock_timestamp(),
  primary key (user_id, kind, id)
);
create index if not exists items_user_synced on public.items (user_id, synced_at);

create or replace function public.items_touch() returns trigger language plpgsql as $$
begin new.synced_at := clock_timestamp(); return new; end $$;
drop trigger if exists items_touch on public.items;
create trigger items_touch before insert or update on public.items
  for each row execute function public.items_touch();

alter table public.items enable row level security;
drop policy if exists "own rows" on public.items;
create policy "own rows" on public.items for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
grant select, insert, update, delete on public.items to authenticated;
