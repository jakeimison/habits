-- Habits app: accounts, friends, leaderboard and cloud backup.
-- Paste this whole file into Supabase → SQL Editor → New query → Run. Safe to run more than once.

-- 1. Tables ---------------------------------------------------------------
create table if not exists public.profiles (
  id          uuid primary key references auth.users on delete cascade,
  username    text unique not null check (username ~ '^[A-Za-z0-9_]{3,20}$'),
  friend_code text unique not null default upper(substr(md5(random()::text || clock_timestamp()::text), 1, 6)),
  created_at  timestamptz not null default now()
);

create unique index if not exists profiles_username_lower on public.profiles (lower(username));

create table if not exists public.stats (
  user_id      uuid primary key references public.profiles on delete cascade,
  week_start   date not null,
  week_xp      int  not null default 0 check (week_xp between 0 and 100000),
  total_xp     int  not null default 0 check (total_xp between 0 and 10000000),
  level        int  not null default 1,
  streak       int  not null default 0,
  perfect_days int  not null default 0,
  updated_at   timestamptz not null default now()
);

create table if not exists public.friendships (
  user_id    uuid not null references public.profiles on delete cascade,
  friend_id  uuid not null references public.profiles on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, friend_id),
  check (user_id <> friend_id)
);

create table if not exists public.saves (
  user_id    uuid primary key references public.profiles on delete cascade,
  state      jsonb not null,
  updated_at timestamptz not null default now()
);

-- 2. Row-level security: people only see themselves and their friends ----
alter table public.profiles    enable row level security;
alter table public.stats       enable row level security;
alter table public.friendships enable row level security;
alter table public.saves       enable row level security;

create or replace function public.is_friend(other uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from friendships where user_id = auth.uid() and friend_id = other);
$$;

drop policy if exists "profiles: read self and friends" on public.profiles;
create policy "profiles: read self and friends" on public.profiles for select
  using (id = auth.uid() or public.is_friend(id));
drop policy if exists "profiles: create own" on public.profiles;
create policy "profiles: create own" on public.profiles for insert with check (id = auth.uid());
drop policy if exists "profiles: edit own" on public.profiles;
create policy "profiles: edit own" on public.profiles for update using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "stats: read self and friends" on public.stats;
create policy "stats: read self and friends" on public.stats for select
  using (user_id = auth.uid() or public.is_friend(user_id));
drop policy if exists "stats: write own" on public.stats;
create policy "stats: write own" on public.stats for insert with check (user_id = auth.uid());
drop policy if exists "stats: update own" on public.stats;
create policy "stats: update own" on public.stats for update using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "friendships: read own" on public.friendships;
create policy "friendships: read own" on public.friendships for select using (user_id = auth.uid());

drop policy if exists "saves: own only" on public.saves;
create policy "saves: own only" on public.saves for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- 3. Friend actions (run as the database so they can link both people) ----
create or replace function public.add_friend(code text) returns text
language plpgsql security definer set search_path = public as $$
declare fid uuid; fname text;
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;
  select id, username into fid, fname from profiles where friend_code = upper(trim(code));
  if fid is null then raise exception 'No one has that friend code'; end if;
  if fid = auth.uid() then raise exception 'That is your own code'; end if;
  insert into friendships (user_id, friend_id) values (auth.uid(), fid), (fid, auth.uid())
    on conflict do nothing;
  return fname;
end $$;

create or replace function public.remove_friend(fid uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  delete from friendships where (user_id = auth.uid() and friend_id = fid)
                             or (user_id = fid and friend_id = auth.uid());
end $$;

create or replace function public.username_available(name text) returns boolean
language sql stable security definer set search_path = public as $$
  select not exists (select 1 from profiles where lower(username) = lower(name));
$$;

revoke all on function public.add_friend(text), public.remove_friend(uuid), public.username_available(text), public.is_friend(uuid) from public;
grant execute on function public.add_friend(text), public.remove_friend(uuid), public.username_available(text), public.is_friend(uuid) to authenticated;
grant execute on function public.username_available(text) to anon;
