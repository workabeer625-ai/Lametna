-- ============================================================
-- لمّتنا / Lametna — 0005 Moderation, notifications, audit
-- ============================================================

create table if not exists public.reports (
  id            bigserial primary key,
  reporter_id   uuid not null references public.profiles(id) on delete cascade,
  reported_id   uuid not null references public.profiles(id) on delete cascade,
  room_id       uuid references public.rooms(id) on delete set null,
  message_id    bigint references public.messages(id) on delete set null,
  reason        text not null check (reason in
                  ('abuse','racism','sectarian','bullying','incitement','profanity','doxxing','impersonation','spam','other')),
  details       text check (char_length(details) <= 500),
  status        report_status not null default 'open',
  handled_by    uuid references public.profiles(id) on delete set null,
  handled_at    timestamptz,
  created_at    timestamptz not null default now(),
  constraint reports_no_self check (reporter_id <> reported_id)
);
create index if not exists reports_status_idx on public.reports (status, created_at desc);
create index if not exists reports_reported_idx on public.reports (reported_id);
create unique index if not exists reports_dedupe_idx
  on public.reports (reporter_id, reported_id, coalesce(room_id, '00000000-0000-0000-0000-000000000000'::uuid))
  where status = 'open';

create table if not exists public.bans (
  id          bigserial primary key,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  scope       ban_scope not null default 'room',
  room_id     uuid references public.rooms(id) on delete cascade,
  reason      text not null default '',
  created_by  uuid references public.profiles(id) on delete set null,
  created_at  timestamptz not null default now(),
  expires_at  timestamptz,
  constraint bans_scope_room check ((scope = 'room' and room_id is not null) or (scope = 'global' and room_id is null))
);
create index if not exists bans_user_idx on public.bans (user_id, scope);
create index if not exists bans_room_idx on public.bans (room_id);

-- Personal block list (mute another user everywhere for me)
create table if not exists public.user_blocks (
  blocker_id  uuid not null references public.profiles(id) on delete cascade,
  blocked_id  uuid not null references public.profiles(id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint blocks_no_self check (blocker_id <> blocked_id)
);

create table if not exists public.notifications (
  id          bigserial primary key,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  title_ar    text not null,
  title_en    text not null default '',
  body_ar     text not null default '',
  body_en     text not null default '',
  kind        text not null default 'info',
  payload     jsonb not null default '{}'::jsonb,
  read_at     timestamptz,
  created_at  timestamptz not null default now()
);
create index if not exists notifications_user_idx on public.notifications (user_id, created_at desc);

create table if not exists public.audit_logs (
  id          bigserial primary key,
  actor_id    uuid references public.profiles(id) on delete set null,
  action      text not null,
  entity      text not null default '',
  entity_id   text,
  metadata    jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now()
);
create index if not exists audit_logs_created_idx on public.audit_logs (created_at desc);
create index if not exists audit_logs_actor_idx on public.audit_logs (actor_id, created_at desc);

-- ---------- banned words (moderation dictionary) ------------
create table if not exists public.banned_words (
  id        bigserial primary key,
  word      text not null unique,
  severity  int not null default 1 check (severity between 1 and 3),
  locale    text not null default 'ar'
);
