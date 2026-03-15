-- TradePlaybook MVP schema (profiles + trades) with RLS

create extension if not exists "uuid-ossp";

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  display_name text
);

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name', ''));
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

create table if not exists public.trades (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,

  open_date date not null,
  close_date date,

  symbol text not null,
  side text not null check (side in ('LONG_CALL','LONG_PUT')),
  expiry date not null,
  strike numeric not null,

  contracts int not null check (contracts > 0),
  entry_price numeric not null check (entry_price >= 0),
  exit_price numeric check (exit_price >= 0),
  fees numeric not null default 0 check (fees >= 0),

  thesis text,
  setup_tag text,
  outcome_tag text,
  notes text,

  created_at timestamptz not null default now()
);

create index if not exists trades_user_id_created_at_idx
  on public.trades(user_id, created_at desc);

alter table public.profiles enable row level security;
alter table public.trades enable row level security;

-- profiles policies
-- Supabase/Postgres versions may not support `create policy if not exists`.
-- Use DROP POLICY + CREATE POLICY instead.

-- profiles policies
DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;
CREATE POLICY "profiles_select_own"
ON public.profiles FOR SELECT
USING (id = auth.uid());

DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
CREATE POLICY "profiles_update_own"
ON public.profiles FOR UPDATE
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- trades policies
DROP POLICY IF EXISTS "trades_select_own" ON public.trades;
CREATE POLICY "trades_select_own"
ON public.trades FOR SELECT
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "trades_insert_own" ON public.trades;
CREATE POLICY "trades_insert_own"
ON public.trades FOR INSERT
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "trades_update_own" ON public.trades;
CREATE POLICY "trades_update_own"
ON public.trades FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "trades_delete_own" ON public.trades;
CREATE POLICY "trades_delete_own"
ON public.trades FOR DELETE
USING (user_id = auth.uid());
