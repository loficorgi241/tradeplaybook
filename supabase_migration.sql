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
create policy if not exists "profiles_select_own"
on public.profiles for select
using (id = auth.uid());

create policy if not exists "profiles_update_own"
on public.profiles for update
using (id = auth.uid())
with check (id = auth.uid());

-- trades policies
create policy if not exists "trades_select_own"
on public.trades for select
using (user_id = auth.uid());

create policy if not exists "trades_insert_own"
on public.trades for insert
with check (user_id = auth.uid());

create policy if not exists "trades_update_own"
on public.trades for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy if not exists "trades_delete_own"
on public.trades for delete
using (user_id = auth.uid());
