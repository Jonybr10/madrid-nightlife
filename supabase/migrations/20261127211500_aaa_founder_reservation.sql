begin;
create table aaa_private.founder_reservation (
 singleton boolean primary key default true check(singleton),
 expected_email text not null check(expected_email=lower(trim(expected_email)) and length(expected_email)<=254),
 provider text not null default 'google' check(provider='google'),
 reserved_at timestamptz not null default now()
);
alter table aaa_private.founder_reservation enable row level security;
revoke all on aaa_private.founder_reservation from public,anon,authenticated,service_role;
create function aaa_private.verify_founder_candidate(p_user uuid) returns boolean
language sql stable security invoker set search_path='' as $$
 select exists (
   select 1 from aaa_private.founder_reservation r
   join auth.users u on lower(u.email)=r.expected_email
   join auth.identities i on i.user_id=u.id and i.provider=r.provider
   where r.singleton and u.id=p_user and u.email_confirmed_at is not null
   and lower(i.identity_data->>'email')=r.expected_email
   and i.identity_data->>'email_verified'='true'
   and coalesce(i.provider_id,'')<>''
 );
$$;
revoke all on function aaa_private.verify_founder_candidate(uuid) from public,anon,authenticated,service_role;
create or replace function aaa_private.appoint_initial_founder(p_user uuid) returns void
language plpgsql security definer set search_path='' as $$
declare previous public.aaa_access; current_access public.aaa_access;
begin
 if not exists(select 1 from aaa_private.environment where singleton and kind='production')
 then raise exception 'Production environment must be explicitly configured'; end if;
 if not aaa_private.verify_founder_candidate(p_user)
 then raise exception 'Reserved verified Google identity required' using errcode='42501'; end if;
 if not exists(select 1 from auth.users u join aaa_private.onboarding o on o.user_id=u.id
 join aaa_private.policy_versions v on v.version=o.policy_version and v.active
 where u.id=p_user and u.email_confirmed_at is not null and o.adult_declared)
 or exists(select 1 from aaa_private.test_accounts where user_id=p_user)
 or exists(select 1 from auth.users where id=p_user and coalesce(raw_app_meta_data->>'aaa_fixture','')<>'')
 then raise exception 'Verified real account with current onboarding required'; end if;
 if not exists(select 1 from auth.mfa_factors where user_id=p_user and status='verified' and factor_type='totp')
 then raise exception 'Verified TOTP factor required before ownership appointment'; end if;
 insert into aaa_private.founder_owner(user_id) values(p_user);
 select * into previous from public.aaa_access where user_id=p_user for update;
 if not found then raise exception 'Access record missing'; end if;
 update public.aaa_access set role='admin',enabled=true,experience=true,operations=true,catalog_edit=true,cron_manage=true,changed_at=now()
 where user_id=p_user returning * into current_access;
 insert into aaa_private.access_audit(actor,subject,old_access,new_access) values(null,p_user,to_jsonb(previous),to_jsonb(current_access));
end; $$;
revoke all on function aaa_private.appoint_initial_founder(uuid) from public,anon,authenticated,service_role;
commit;