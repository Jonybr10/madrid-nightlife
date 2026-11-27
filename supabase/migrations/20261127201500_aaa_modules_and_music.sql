-- AAA modular services and independently declared musical preferences.
-- Apply after privacy onboarding. No Spotify ingestion, payment processing or live data.
begin;
create table aaa_private.modules (
  code text primary key check(code ~ '^[a-z][a-z0-9_]{1,63}$'),
  name text not null,
  description text not null,
  enabled boolean not null default false,
  requires_personalization boolean not null default false
);
create table aaa_private.plans (
  code text primary key check(code ~ '^[a-z][a-z0-9_]{1,63}$'),
  name text not null,
  billing_kind text not null check(billing_kind in ('free','subscription','one_time')),
  enabled boolean not null default false
);
create table aaa_private.plan_modules (
  plan_code text references aaa_private.plans(code) on delete cascade,
  module_code text references aaa_private.modules(code) on delete cascade,
  primary key(plan_code,module_code)
);
create table aaa_private.offers (
  id uuid primary key default gen_random_uuid(),
  plan_code text not null references aaa_private.plans(code),
  currency text not null check(currency ~ '^[A-Z]{3}$'),
  amount_minor bigint not null check(amount_minor>=0),
  interval_unit text check(interval_unit in ('month','year')),
  enabled boolean not null default false,
  created_at timestamptz not null default now()
);
create table aaa_private.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  offer_id uuid not null references aaa_private.offers(id),
  currency text not null check(currency ~ '^[A-Z]{3}$'),
  amount_minor bigint not null check(amount_minor>=0),
  state text not null default 'pending' check(state in ('pending','paid','failed','refunded','cancelled')),
  payment_provider text,
  provider_order_id text,
  created_at timestamptz not null default now(),
  unique(payment_provider,provider_order_id),
  unique(id,user_id)
);
create table aaa_private.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  plan_code text not null references aaa_private.plans(code),
  state text not null check(state in ('pending','active','past_due','cancelled','expired')),
  provider text not null,
  provider_subscription_id text not null,
  current_period_end timestamptz,
  unique(provider,provider_subscription_id),
  unique(id,user_id)
);
create table aaa_private.entitlements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  module_code text not null references aaa_private.modules(code),
  source text not null check(source in ('order','subscription','manual')),
  order_id uuid,
  subscription_id uuid,
  valid_from timestamptz not null default now(),
  valid_until timestamptz,
  revoked_at timestamptz,
  check(valid_until is null or valid_until>valid_from),
  check((source='order' and order_id is not null and subscription_id is null) or
        (source='subscription' and subscription_id is not null and order_id is null) or
        (source='manual' and order_id is null and subscription_id is null)),
  foreign key(order_id,user_id) references aaa_private.orders(id,user_id),
  foreign key(subscription_id,user_id) references aaa_private.subscriptions(id,user_id)
);
create index aaa_entitlements_user on aaa_private.entitlements(user_id,module_code);
create table aaa_private.payment_events (
  provider text not null, provider_event_id text not null,
  received_at timestamptz not null default now(),
  processed_at timestamptz,
  primary key(provider,provider_event_id)
);
-- Provider capabilities: not a store of user tokens or musical history.
create table aaa_private.identity_provider_policy (
  provider text primary key,
  login_enabled boolean not null default false,
  allowed_scopes text[] not null default '{}',
  music_import_enabled boolean not null default false check(not music_import_enabled),
  reviewed_at date,
  policy_url text not null
);
insert into aaa_private.identity_provider_policy(provider,allowed_scopes,policy_url) values
 ('google',array['openid','email','profile'],'https://developers.google.com/identity/openid-connect/openid-connect'),
 ('spotify',array[]::text[],'https://developer.spotify.com/policy');
-- Auth owns identity identifiers and provider linkage (auth.identities); do not duplicate raw claims.
create table public.aaa_profile_details (
  user_id uuid primary key references auth.users(id) on delete cascade,
  given_name text check(length(given_name)<=100),
  family_name text check(length(family_name)<=100),
  preferred_locale text check(length(preferred_locale)<=35),
  updated_at timestamptz not null default now()
);
-- User-entered preferences only; not an import destination for external provider datasets.
create table public.aaa_music_preferences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  item_type text not null check(item_type in ('track','album','genre','venue','series')),
  title text not null check(length(trim(title)) between 1 and 200),
  artist_name text check(length(artist_name)<=180),
  catalog_id text check(length(catalog_id)<=250),
  created_at timestamptz not null default now(),
  unique(user_id,id)
);
create index aaa_music_preferences_user on public.aaa_music_preferences(user_id);
alter table public.aaa_profile_details enable row level security;
alter table public.aaa_music_preferences enable row level security;
revoke all on public.aaa_profile_details,public.aaa_music_preferences from public,anon,authenticated;
grant select,insert,update,delete on public.aaa_profile_details to authenticated;
grant select,insert,delete on public.aaa_music_preferences to authenticated;
create policy profile_details_self on public.aaa_profile_details for all to authenticated
 using(auth.uid()=user_id) with check(auth.uid()=user_id);
create policy music_preferences_self on public.aaa_music_preferences for all to authenticated
 using(auth.uid()=user_id) with check(auth.uid()=user_id);
do $$
declare t text;
begin
 foreach t in array array['modules','plans','plan_modules','offers','orders','subscriptions','entitlements','payment_events','identity_provider_policy'] loop
  execute format('alter table aaa_private.%I enable row level security',t);
  execute format('revoke all on aaa_private.%I from public,anon,authenticated',t);
 end loop;
end; $$;
insert into aaa_private.modules(code,name,description,enabled,requires_personalization) values
 ('global_agenda','Agenda mundial','Exploración de eventos y locales',true,false),
 ('favorites','Mis favoritos','Preferencias declaradas y eventos guardados',true,false),
 ('personal_plus','AAA Personal+','Recomendaciones con preferencias declaradas en AAA',true,true);
insert into aaa_private.plans(code,name,billing_kind,enabled) values ('free','AAA Free','free',true),('premium','AAA Premium','subscription',false);
insert into aaa_private.plan_modules(plan_code,module_code) select 'free',code from aaa_private.modules;
-- One canonical authorization check. Free access requires approved account and current onboarding.
-- An active paid entitlement must also pass order/subscription state and period checks.
create function aaa_private.has_module(p_user uuid,p_module text) returns boolean language sql stable security definer set search_path='' as $$
 select exists(
  select 1 from public.aaa_access a
  join public.aaa_profiles p on p.user_id=a.user_id
  join aaa_private.onboarding o on o.user_id=a.user_id
  join aaa_private.policy_versions v on v.version=o.policy_version and v.active
  join aaa_private.modules m on m.code=p_module and m.enabled
  where a.user_id=p_user and a.enabled and a.experience
   and (not m.requires_personalization or p.personalization)
   and (
    exists(select 1 from aaa_private.plan_modules pm join aaa_private.plans pl on pl.code=pm.plan_code
     where pm.module_code=m.code and pl.code='free' and pl.enabled and pl.billing_kind='free')
    or exists(select 1 from aaa_private.entitlements e where e.user_id=a.user_id and e.module_code=m.code
      and e.revoked_at is null and e.valid_from<=now() and (e.valid_until is null or e.valid_until>now())
      and (e.source='manual'
       or (e.source='order' and exists(select 1 from aaa_private.orders ord
         join aaa_private.offers f on f.id=ord.offer_id join aaa_private.plans pl on pl.code=f.plan_code
         join aaa_private.plan_modules pm on pm.plan_code=pl.code and pm.module_code=m.code
         where ord.id=e.order_id and ord.user_id=a.user_id and ord.state='paid' and pl.enabled and pl.billing_kind='one_time'))
       or (e.source='subscription' and exists(select 1 from aaa_private.subscriptions s
         join aaa_private.plans pl on pl.code=s.plan_code join aaa_private.plan_modules pm on pm.plan_code=pl.code and pm.module_code=m.code
         where s.id=e.subscription_id and s.user_id=a.user_id and s.state='active' and s.current_period_end>now()
          and pl.enabled and pl.billing_kind='subscription'))))
   )
 );
$$;
revoke all on function aaa_private.has_module(uuid,text) from public,anon,authenticated;
create function public.aaa_my_modules() returns table(code text,name text,description text,available boolean,requires_personalization boolean)
language sql stable security definer set search_path='' as $$
 select m.code,m.name,m.description,aaa_private.has_module(auth.uid(),m.code),m.requires_personalization
 from aaa_private.modules m where auth.uid() is not null and m.enabled order by m.code;
$$;
revoke all on function public.aaa_my_modules() from public,anon,authenticated;
grant execute on function public.aaa_my_modules() to authenticated;
commit;
