begin;
create table aaa_private.legal_drafts (
  version text primary key,
  controller_name text not null,
  controller_email text not null,
  privacy_notice text not null,
  terms text not null,
  review_notes text not null,
  created_at timestamptz not null default now()
);
alter table aaa_private.legal_drafts enable row level security;
revoke all on aaa_private.legal_drafts from public, anon, authenticated, service_role;
comment on table aaa_private.legal_drafts is 'Private unpublished draft text only. Does not activate a policy or authorize live registrations.';
commit;