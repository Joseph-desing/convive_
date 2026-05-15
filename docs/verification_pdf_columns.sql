alter table public.properties
add column if not exists verification_pdf_url text;

alter table public.properties
add column if not exists admin_notes text;

alter table public.properties
add column if not exists status text not null default 'pending'
check (status in ('pending', 'active', 'inactive'));

update public.properties
set status = case
  when is_active is true then 'active'
  when coalesce(nullif(trim(admin_notes), ''), '') <> '' then 'inactive'
  else 'pending'
end;

create index if not exists idx_properties_status
on public.properties(status);

create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.users
    where users.id = auth.uid()
      and users.role = 'admin'
  );
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

drop policy if exists "Admins can select all properties"
on public.properties;

create policy "Admins can select all properties"
on public.properties
for select
using (public.is_admin());

drop policy if exists "Admins can update all properties"
on public.properties;

create policy "Admins can update all properties"
on public.properties
for update
using (public.is_admin())
with check (public.is_admin());

alter table public.roommate_searches
add column if not exists verification_pdf_url text;

alter table public.roommate_searches
add column if not exists is_active boolean not null default false;

alter table public.roommate_searches
add column if not exists admin_notes text;

alter table public.roommate_searches
add column if not exists status text not null default 'pending'
check (status in ('pending', 'active', 'inactive'));

update public.roommate_searches
set status = case
  when is_active is true then 'active'
  when status = 'inactive' then 'inactive'
  else 'pending'
end;

create index if not exists idx_roommate_searches_status
on public.roommate_searches(status);

drop policy if exists "Admins can select all roommate searches"
on public.roommate_searches;

create policy "Admins can select all roommate searches"
on public.roommate_searches
for select
using (public.is_admin());

drop policy if exists "Admins can update all roommate searches"
on public.roommate_searches;

create policy "Admins can update all roommate searches"
on public.roommate_searches
for update
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "Users can select own roommate searches"
on public.roommate_searches;

create policy "Users can select own roommate searches"
on public.roommate_searches
for select
using (auth.uid() = user_id);

drop policy if exists "Users can insert own roommate searches"
on public.roommate_searches;

create policy "Users can insert own roommate searches"
on public.roommate_searches
for insert
with check (auth.uid() = user_id);

drop policy if exists "Users can update own roommate searches"
on public.roommate_searches;

create policy "Users can update own roommate searches"
on public.roommate_searches
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Optional repair for publications created before admin status was enforced.
-- Use this if a newly-created publication appears in "Mis publicaciones"
-- but not in Admin > Posts > Pendientes.
--
-- update public.properties
-- set status = 'pending', is_active = false
-- where title = 'PRUEBA DEPARTAMENTO';

-- Repair specific publications only when you know they should be pending.
-- Do not run a blanket update here because it can hide previously active posts.
--
-- update public.properties
-- set status = 'pending',
--     is_active = false
-- where id = 'PROPERTY_ID';
--
-- update public.roommate_searches
-- set status = 'pending',
--     is_active = false
-- where id = 'ROOMMATE_SEARCH_ID';
