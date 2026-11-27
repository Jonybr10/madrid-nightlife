-- AAA Identity: apply only to the private Supabase project, never to GitHub Pages.
begin;
create schema if not exists aaa_private;
revoke all on schema aaa_private from public, anon, authenticated;
create type public.aaa_account_role as enum ('client','operator','researcher','admin');
create table public.aaa_access (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role public.aaa_account_role not null default 'client',
  enabled boolean not null default false,
  experience boolean not null default false,
  operations boolean not null default false,
  catalog_edit boolean not null default false,
  cron_manage boolean not null default false,
  changed_at timestamptz not null default now(),
  check (role <> 'client' or (not catalog_edit and not cron_manage))
);
create table public.aaa_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text check (char_length(display_name)<=100),
  country text check (country is null or country ~ '^[A-Z]{2}$'),
  city text check (char_length(city)<=120),
  personalization boolean not null default false,
  privacy_notice_version text,
  updated_at timestamptz not null default now()
);
create table public.aaa_artist_favorites (
  user_id uuid not null references auth.users(id) on delete cascade,
  artist_id text not null check (char_length(artist_id) between 1 and 250),
  artist_name text not null check (char_length(artist_name) between 1 and 180),
  created_at timestamptz not null default now(),
  primary key(user_id,artist_id)
);
create table public.aaa_saved_events (
  user_id uuid not null references auth.users(id) on delete cascade,
  event_id text not null check (char_length(event_id) between 1 and 250),
  created_at timestamptz not null default now(),
  primary key(user_id,event_id)
);
create table public.aaa_privacy_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check(kind in ('export','delete_account')),
  created_at timestamptz not null default now(),
  unique(user_id,kind)
);
create table aaa_private.access_audit (
  id bigint generated always as identity primary key,
  actor uuid references auth.users(id) on delete set null,
  subject uuid references auth.users(id) on delete set null,
  changed_at timestamptz not null default now(),
  old_access jsonb not null, new_access jsonb not null
);
create table aaa_private.service_identities (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  scopes text[] not null default '{}',
  enabled boolean not null default false,
  created_at timestamptz not null default now()
);
-- Service identities are a registry, NOT authentication credentials. A trusted
-- server must authenticate machine requests, enforce scopes and log activity.
alter table public.aaa_access enable row level security;
alter table public.aaa_profiles enable row level security;
alter table public.aaa_artist_favorites enable row level security;
alter table public.aaa_saved_events enable row level security;
alter table public.aaa_privacy_requests enable row level security;
alter table aaa_private.access_audit enable row level security;
alter table aaa_private.service_identities enable row level security;
revoke all on public.aaa_access, public.aaa_profiles, public.aaa_artist_favorites, public.aaa_saved_events, public.aaa_privacy_requests from public, anon, authenticated;
grant select on public.aaa_access to authenticated;
grant select, insert, update on public.aaa_profiles to authenticated;
grant select, insert, delete on public.aaa_artist_favorites, public.aaa_saved_events to authenticated;
grant select, insert on public.aaa_privacy_requests to authenticated;
create policy access_self on public.aaa_access for select to authenticated using ((select auth.uid())=user_id);
create policy profile_self on public.aaa_profiles for all to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
create policy favorites_self on public.aaa_artist_favorites for all to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
create policy saved_self on public.aaa_saved_events for all to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
create policy privacy_self on public.aaa_privacy_requests for select to authenticated using ((select auth.uid())=user_id);
create policy privacy_insert_self on public.aaa_privacy_requests for insert to authenticated with check ((select auth.uid())=user_id);
-- Staff/clients use the same identity provider; only an admin can assign privileges.
create function aaa_private.new_account() returns trigger language plpgsql security definer set search_path='' as $$
begin
  insert into public.aaa_access(user_id) values(new.id) on conflict do nothing;
  insert into public.aaa_profiles(user_id) values(new.id) on conflict do nothing;
  return new;
end; $$;
revoke all on function aaa_private.new_account() from public, anon, authenticated;
create trigger aaa_new_account after insert on auth.users for each row execute function aaa_private.new_account();
insert into public.aaa_access(user_id) select id from auth.users on conflict do nothing;
insert into public.aaa_profiles(user_id) select id from auth.users on conflict do nothing;
create function aaa_private.require_admin() returns void language plpgsql security definer set search_path='' as $$
begin
  if coalesce(auth.jwt()->>'aal','') <> 'aal2' or not exists (
    select 1 from public.aaa_access where user_id=auth.uid() and enabled and role='admin'
  ) then raise exception 'Administrator with MFA required' using errcode='42501'; end if;
end; $$;
revoke all on function aaa_private.require_admin() from public, anon, authenticated;
create function public.aaa_list_accounts() returns table(user_id uuid,email text,role public.aaa_account_role,enabled boolean,experience boolean,operations boolean,catalog_edit boolean,cron_manage boolean,changed_at timestamptz)
language plpgsql security definer set search_path='' as $$
begin
  perform aaa_private.require_admin();
  return query select a.user_id,u.email::text,a.role,a.enabled,a.experience,a.operations,a.catalog_edit,a.cron_manage,a.changed_at
  from public.aaa_access a join auth.users u on u.id=a.user_id order by a.changed_at desc limit 500;
end; $$;
create function public.aaa_set_access(p_user uuid,p_role public.aaa_account_role,p_enabled boolean,p_experience boolean,p_operations boolean,p_catalog_edit boolean,p_cron_manage boolean)
returns void language plpgsql security definer set search_path='' as $$
declare oldrow public.aaa_access; newrow public.aaa_access;
begin
  perform aaa_private.require_admin();
  if p_user=auth.uid() then raise exception 'Self privilege changes require trusted database operator'; end if;
  select * into oldrow from public.aaa_access where user_id=p_user for update;
  if not found then raise exception 'Account not found'; end if;
  update public.aaa_access set role=p_role,enabled=p_enabled,experience=p_experience,operations=p_operations,
    catalog_edit=p_catalog_edit,cron_manage=p_cron_manage,changed_at=now() where user_id=p_user returning * into newrow;
  insert into aaa_private.access_audit(actor,subject,old_access,new_access)
    values(auth.uid(),p_user,to_jsonb(oldrow),to_jsonb(newrow));
end; $$;
revoke all on function public.aaa_list_accounts() from public, anon, authenticated;
revoke all on function public.aaa_set_access(uuid,public.aaa_account_role,boolean,boolean,boolean,boolean,boolean) from public, anon, authenticated;
grant execute on function public.aaa_list_accounts() to authenticated;
grant execute on function public.aaa_set_access(uuid,public.aaa_account_role,boolean,boolean,boolean,boolean,boolean) to authenticated;
commit;
