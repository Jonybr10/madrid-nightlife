-- Founder ownership and staging-only synthetic identities.
-- Apply after prior identity, onboarding and module migrations. No user is created by this migration.
begin;
create table aaa_private.environment (
  singleton boolean primary key default true check(singleton),
  kind text not null check(kind in ('unconfigured','staging','production'))
);
insert into aaa_private.environment(kind) values ('unconfigured');
create table aaa_private.founder_owner (
  singleton boolean primary key default true check(singleton),
  user_id uuid not null unique references auth.users(id) on delete restrict,
  appointed_at timestamptz not null default now()
);
create table aaa_private.test_accounts (
  user_id uuid primary key references auth.users(id) on delete cascade,
  persona text not null unique check(persona in ('founder_systems','founder_experience','founder_testing')),
  created_at timestamptz not null default now()
);
alter table aaa_private.environment enable row level security;
alter table aaa_private.founder_owner enable row level security;
alter table aaa_private.test_accounts enable row level security;
revoke all on aaa_private.environment,aaa_private.founder_owner,aaa_private.test_accounts from public,anon,authenticated,service_role;
-- Trusted database operator only; after real founder registers with verified email and completes onboarding.
create function aaa_private.appoint_initial_founder(p_user uuid) returns void
language plpgsql security definer set search_path='' as $$
declare previous public.aaa_access; current_access public.aaa_access;
begin
  if not exists(select 1 from aaa_private.environment where singleton and kind='production')
  then raise exception 'Production environment must be explicitly configured'; end if;
  if not exists(select 1 from auth.users u join aaa_private.onboarding o on o.user_id=u.id
      join aaa_private.policy_versions v on v.version=o.policy_version and v.active
      where u.id=p_user and u.email_confirmed_at is not null and o.adult_declared)
     or exists(select 1 from aaa_private.test_accounts where user_id=p_user)
     or exists(select 1 from auth.users where id=p_user and coalesce(raw_app_meta_data->>'aaa_fixture','')<>'')
  then raise exception 'Verified real account with current onboarding required'; end if;
  insert into aaa_private.founder_owner(user_id) values(p_user);
  select * into previous from public.aaa_access where user_id=p_user for update;
  if not found then raise exception 'Access record missing'; end if;
  update public.aaa_access set role='admin',enabled=true,experience=true,operations=true,catalog_edit=true,cron_manage=true,changed_at=now()
    where user_id=p_user returning * into current_access;
  insert into aaa_private.access_audit(actor,subject,old_access,new_access) values(null,p_user,to_jsonb(previous),to_jsonb(current_access));
end; $$;
revoke all on function aaa_private.appoint_initial_founder(uuid) from public,anon,authenticated,service_role;
-- Administrator status alone does not confer ownership. Protect the owner and
-- reserve assignment of other administrators to the owner in production.
create or replace function public.aaa_set_access(p_user uuid,p_role public.aaa_account_role,p_enabled boolean,p_experience boolean,p_operations boolean,p_catalog_edit boolean,p_cron_manage boolean)
returns void language plpgsql security definer set search_path='' as $$
declare oldrow public.aaa_access; newrow public.aaa_access; owner_action boolean;
begin
  perform aaa_private.require_admin();
  if not exists(select 1 from aaa_private.onboarding o join aaa_private.policy_versions v on v.version=o.policy_version and v.active where o.user_id=auth.uid())
  then raise exception 'Current onboarding required' using errcode='42501'; end if;
  select exists(select 1 from aaa_private.founder_owner where user_id=auth.uid()) into owner_action;
  if p_user=auth.uid() or exists(select 1 from aaa_private.founder_owner where user_id=p_user)
  then raise exception 'Protected ownership or self privilege change' using errcode='42501'; end if;
  select * into oldrow from public.aaa_access where user_id=p_user for update;
  if not found then raise exception 'Account not found'; end if;
  if (oldrow.role='admin' or p_role='admin') and not owner_action
  then raise exception 'Only Founder Prime can manage administrator roles' using errcode='42501'; end if;
  update public.aaa_access set role=p_role,enabled=p_enabled,experience=p_experience,operations=p_operations,
    catalog_edit=p_catalog_edit,cron_manage=p_cron_manage,changed_at=now() where user_id=p_user returning * into newrow;
  insert into aaa_private.access_audit(actor,subject,old_access,new_access)
    values(auth.uid(),p_user,to_jsonb(oldrow),to_jsonb(newrow));
end; $$;
-- Service-only RPC for fixtures. Explicit staging configuration is required,
-- and the Auth admin must have marked the synthetic identity first.
create function public.aaa_provision_fixture(p_user uuid,p_persona text) returns void
language plpgsql security definer set search_path='' as $$
declare mail text; mark text; oldrow public.aaa_access; newrow public.aaa_access; label text;
begin
  if not exists(select 1 from aaa_private.environment where singleton and kind='staging')
  then raise exception 'Fixture provisioning forbidden outside staging' using errcode='42501'; end if;
  select email,raw_app_meta_data->>'aaa_fixture' into mail,mark from auth.users where id=p_user;
  if p_persona is null or p_persona not in ('founder_systems','founder_experience','founder_testing')
    or mark is distinct from p_persona
    or mail is distinct from (replace(p_persona,'_','-')||'@example.com')
    or exists(select 1 from aaa_private.founder_owner where user_id=p_user)
  then raise exception 'Synthetic fixture identity required' using errcode='42501'; end if;
  insert into aaa_private.test_accounts(user_id,persona) values(p_user,p_persona);
  select * into oldrow from public.aaa_access where user_id=p_user for update;
  if not found then raise exception 'Access record missing'; end if;
  label:=case p_persona when 'founder_systems' then 'AAA Founder Systems' when 'founder_experience' then 'AAA Founder Experience' else 'AAA Founder Testing' end;
  update public.aaa_profiles set display_name=label,personalization=false where user_id=p_user;
  update public.aaa_access set role=case when p_persona='founder_systems' then 'admin'::public.aaa_account_role else 'client'::public.aaa_account_role end,
    enabled=true,experience=p_persona<>'founder_systems',operations=p_persona='founder_systems',
    catalog_edit=p_persona='founder_systems',cron_manage=p_persona='founder_systems',changed_at=now()
    where user_id=p_user returning * into newrow;
  insert into aaa_private.access_audit(actor,subject,old_access,new_access) values(null,p_user,to_jsonb(oldrow),to_jsonb(newrow));
end; $$;
revoke all on function public.aaa_provision_fixture(uuid,text) from public,anon,authenticated,service_role;
grant execute on function public.aaa_provision_fixture(uuid,text) to service_role;
commit;
