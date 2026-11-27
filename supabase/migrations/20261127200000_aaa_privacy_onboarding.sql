-- Privacy-by-design onboarding. Apply after initial identity migration.
begin;
create table aaa_private.policy_versions (
  version text primary key check(length(version) between 1 and 80),
  privacy_url text not null check(privacy_url ~ '^https://'),
  terms_url text not null check(terms_url ~ '^https://'),
  consent_text_version text not null check(length(consent_text_version) between 1 and 80),
  active boolean not null default false,
  published_at timestamptz not null default now()
);
create unique index aaa_one_active_policy on aaa_private.policy_versions(active) where active;
create table aaa_private.onboarding (
  user_id uuid primary key references auth.users(id) on delete cascade,
  policy_version text not null references aaa_private.policy_versions(version),
  adult_declared boolean not null check(adult_declared),
  terms_accepted_at timestamptz not null,
  notice_presented_at timestamptz not null,
  updated_at timestamptz not null default now()
);
create table aaa_private.consent_history (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  purpose text not null check(purpose in ('recommendations')),
  granted boolean not null,
  policy_version text not null references aaa_private.policy_versions(version),
  text_version text not null,
  changed_at timestamptz not null default now()
);
create index aaa_consent_user_time on aaa_private.consent_history(user_id,purpose,changed_at desc);
alter table aaa_private.policy_versions enable row level security;
alter table aaa_private.onboarding enable row level security;
alter table aaa_private.consent_history enable row level security;
revoke all on aaa_private.policy_versions,aaa_private.onboarding,aaa_private.consent_history from public,anon,authenticated;
alter table public.aaa_profiles add column region text check(length(region)<=120),
  add column locale text check(locale in ('es','en','pt','fr','de','it')),
  add column genres text[] not null default '{}' check(cardinality(genres)<=20 and genres <@ array['house','tech-house','techno','hard-techno','trance','drum-bass','disco','afro-house','latin','hip-hop','pop','rock','jazz','other']::text[]),
  add column event_types text[] not null default '{}' check(cardinality(event_types)<=10 and event_types <@ array['club','festival','concert','day-party','bar','live','other']::text[]),
  add column radius_km integer check(radius_km between 1 and 1000);
-- Prevent bypassing consent recording through direct profile updates.
revoke insert,update on public.aaa_profiles from authenticated;
alter table public.aaa_privacy_requests drop constraint aaa_privacy_requests_kind_check;
alter table public.aaa_privacy_requests add constraint aaa_privacy_requests_kind_check check(kind in ('export','delete_account','rectification','restriction','objection','access','portability'));
alter table public.aaa_privacy_requests add column status text not null default 'received' check(status in ('received','in_review','completed','rejected')),
 add column due_at timestamptz not null default (now()+interval '1 month'),
 add column resolved_at timestamptz;
alter table public.aaa_privacy_requests drop constraint aaa_privacy_requests_user_id_kind_key;
create unique index aaa_one_open_request on public.aaa_privacy_requests(user_id,kind) where status in ('received','in_review');
revoke insert on public.aaa_privacy_requests from authenticated;
create function public.aaa_privacy_state() returns jsonb language plpgsql security definer set search_path='' as $$
declare v aaa_private.policy_versions; o aaa_private.onboarding;
begin
 if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
 select * into v from aaa_private.policy_versions where active;
 if not found then raise exception 'Privacy configuration unavailable'; end if;
 select * into o from aaa_private.onboarding where user_id=auth.uid();
 return jsonb_build_object('version',v.version,'privacyUrl',v.privacy_url,'termsUrl',v.terms_url,
 'textVersion',v.consent_text_version,'completed',coalesce(o.policy_version=v.version,false),
 'consents',coalesce((select jsonb_agg(jsonb_build_object('purpose',c.purpose,'granted',c.granted,'version',c.policy_version,'textVersion',c.text_version,'changedAt',c.changed_at) order by c.changed_at desc,c.id desc) from aaa_private.consent_history c where c.user_id=auth.uid()),'[]'::jsonb));
end; $$;
create function public.aaa_save_onboarding(p_version text,p_adult boolean,p_terms boolean,p_notice boolean,p_display text,p_country text,p_region text,p_city text,p_locale text,p_genres text[],p_event_types text[],p_radius integer,p_recommendations boolean)
returns void language plpgsql security definer set search_path='' as $$
declare v aaa_private.policy_versions; previous boolean; previous_version text; previous_text text; uid uuid:=auth.uid();
begin
 if uid is null then raise exception 'Authentication required' using errcode='42501'; end if;
 select * into v from aaa_private.policy_versions where active for share;
 if not found or v.version is distinct from p_version then raise exception 'Policy changed: reload and review'; end if;
 if p_adult is distinct from true or p_terms is distinct from true or p_notice is distinct from true or p_recommendations is null then raise exception 'Adult declaration, terms and notice required'; end if;
 -- serialize writes for same user; decisions and profile update are atomic.
 perform 1 from public.aaa_profiles where user_id=uid for update;
 if not found then raise exception 'Profile unavailable'; end if;
 select granted,policy_version,text_version into previous,previous_version,previous_text from aaa_private.consent_history where user_id=uid and purpose='recommendations' order by changed_at desc,id desc limit 1;
 if previous is distinct from p_recommendations or previous_version is distinct from v.version or previous_text is distinct from v.consent_text_version then
  insert into aaa_private.consent_history(user_id,purpose,granted,policy_version,text_version) values(uid,'recommendations',p_recommendations,v.version,v.consent_text_version);
 end if;
 insert into aaa_private.onboarding(user_id,policy_version,adult_declared,terms_accepted_at,notice_presented_at)
 values(uid,v.version,true,now(),now())
 on conflict(user_id) do update set policy_version=excluded.policy_version,
 terms_accepted_at=case when aaa_private.onboarding.policy_version is distinct from excluded.policy_version then now() else aaa_private.onboarding.terms_accepted_at end,
 notice_presented_at=case when aaa_private.onboarding.policy_version is distinct from excluded.policy_version then now() else aaa_private.onboarding.notice_presented_at end,updated_at=now();
 update public.aaa_profiles set display_name=nullif(trim(p_display),''),country=nullif(upper(trim(p_country)),''),
 region=nullif(trim(p_region),''),city=nullif(trim(p_city),''),locale=p_locale,genres=coalesce(p_genres,'{}'),event_types=coalesce(p_event_types,'{}'),
 radius_km=p_radius,personalization=p_recommendations,privacy_notice_version=v.version,updated_at=now() where user_id=uid;
end; $$;
create function public.aaa_withdraw_recommendations() returns void language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); v aaa_private.policy_versions;
begin
 if uid is null then raise exception 'Authentication required' using errcode='42501'; end if;
 perform 1 from public.aaa_profiles where user_id=uid for update;
 select * into v from aaa_private.policy_versions where active;
 if not found then select pv.* into v from aaa_private.policy_versions pv join aaa_private.onboarding o on o.policy_version=pv.version where o.user_id=uid; end if;
 if found then insert into aaa_private.consent_history(user_id,purpose,granted,policy_version,text_version) values(uid,'recommendations',false,v.version,v.consent_text_version); end if;
 update public.aaa_profiles set personalization=false,updated_at=now() where user_id=uid;
end; $$;
create function public.aaa_request_privacy(p_kind text) returns uuid language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); rid uuid;
begin
 if uid is null then raise exception 'Authentication required' using errcode='42501'; end if;
 insert into public.aaa_privacy_requests(user_id,kind) values(uid,p_kind)
 on conflict(user_id,kind) where status in ('received','in_review') do nothing returning id into rid;
 if rid is null then select id into rid from public.aaa_privacy_requests where user_id=uid and kind=p_kind and status in ('received','in_review'); end if;
 return rid;
end; $$;
revoke all on function public.aaa_privacy_state(),public.aaa_save_onboarding(text,boolean,boolean,boolean,text,text,text,text,text,text[],text[],integer,boolean),public.aaa_withdraw_recommendations(),public.aaa_request_privacy(text) from public,anon,authenticated;
grant execute on function public.aaa_privacy_state(),public.aaa_save_onboarding(text,boolean,boolean,boolean,text,text,text,text,text,text[],text[],integer,boolean),public.aaa_withdraw_recommendations(),public.aaa_request_privacy(text) to authenticated;
commit;
