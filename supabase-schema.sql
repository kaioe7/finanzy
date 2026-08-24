-- Execute este arquivo uma única vez no Supabase: SQL Editor > New query > Run.
-- MetaBolso: banco, perfis, segurança por usuário e suporte administrativo.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null default 'Cliente',
  email text not null default '',
  role text not null default 'client' check (role in ('client','admin')),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  description text not null,
  value numeric(14,2) not null check (value > 0),
  type text not null check (type in ('income','expense')),
  category text not null,
  date date not null,
  created_at timestamptz not null default now()
);

create table if not exists public.fixed_expenses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  value numeric(14,2) not null check (value > 0),
  due smallint not null check (due between 1 and 31),
  category text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  target numeric(14,2) not null check (target > 0),
  current numeric(14,2) not null default 0 check (current >= 0),
  deadline date not null,
  created_at timestamptz not null default now()
);

create index if not exists transactions_user_id_idx on public.transactions(user_id);
create index if not exists fixed_expenses_user_id_idx on public.fixed_expenses(user_id);
create index if not exists goals_user_id_idx on public.goals(user_id);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, name, email)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'name', 'Cliente'), coalesce(new.email, ''));
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.profiles where id = (select auth.uid()) and role = 'admin' and active = true);
$$;

alter table public.profiles enable row level security;
alter table public.transactions enable row level security;
alter table public.fixed_expenses enable row level security;
alter table public.goals enable row level security;

revoke all on public.profiles, public.transactions, public.fixed_expenses, public.goals from anon;
grant select, update on public.profiles to authenticated;
grant select, insert, update, delete on public.transactions, public.fixed_expenses, public.goals to authenticated;

drop policy if exists "profiles_select" on public.profiles;
create policy "profiles_select" on public.profiles for select to authenticated
using ((select auth.uid()) = id or (select public.is_admin()));
drop policy if exists "profiles_update" on public.profiles;
create policy "profiles_update" on public.profiles for update to authenticated
using ((select public.is_admin()))
with check ((select public.is_admin()));

drop policy if exists "transactions_select" on public.transactions;
create policy "transactions_select" on public.transactions for select to authenticated using ((select auth.uid()) = user_id or (select public.is_admin()));
drop policy if exists "transactions_insert" on public.transactions;
create policy "transactions_insert" on public.transactions for insert to authenticated with check ((select auth.uid()) = user_id);
drop policy if exists "transactions_update" on public.transactions;
create policy "transactions_update" on public.transactions for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
drop policy if exists "transactions_delete" on public.transactions;
create policy "transactions_delete" on public.transactions for delete to authenticated using ((select auth.uid()) = user_id);

drop policy if exists "fixed_select" on public.fixed_expenses;
create policy "fixed_select" on public.fixed_expenses for select to authenticated using ((select auth.uid()) = user_id or (select public.is_admin()));
drop policy if exists "fixed_insert" on public.fixed_expenses;
create policy "fixed_insert" on public.fixed_expenses for insert to authenticated with check ((select auth.uid()) = user_id);
drop policy if exists "fixed_update" on public.fixed_expenses;
create policy "fixed_update" on public.fixed_expenses for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
drop policy if exists "fixed_delete" on public.fixed_expenses;
create policy "fixed_delete" on public.fixed_expenses for delete to authenticated using ((select auth.uid()) = user_id);

drop policy if exists "goals_select" on public.goals;
create policy "goals_select" on public.goals for select to authenticated using ((select auth.uid()) = user_id or (select public.is_admin()));
drop policy if exists "goals_insert" on public.goals;
create policy "goals_insert" on public.goals for insert to authenticated with check ((select auth.uid()) = user_id);
drop policy if exists "goals_update" on public.goals;
create policy "goals_update" on public.goals for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
drop policy if exists "goals_delete" on public.goals;
create policy "goals_delete" on public.goals for delete to authenticated using ((select auth.uid()) = user_id);

-- Depois que cadastrar sua conta de administrador, promova-a pelo SQL Editor:
-- update public.profiles set role = 'admin' where email = 'seu@email.com';
