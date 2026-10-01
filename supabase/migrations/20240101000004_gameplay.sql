-- ============================================================
-- لمّتنا / Lametna — 0004 Gameplay tables
-- ============================================================

create table if not exists public.game_sessions (
  id            uuid primary key default gen_random_uuid(),
  room_id       uuid not null references public.rooms(id) on delete cascade,
  game_key      text not null references public.games(key) on delete restrict,
  status        session_status not null default 'pending',
  total_rounds  int not null default 5,
  current_round int not null default 0,
  config        jsonb not null default '{}'::jsonb,
  result        jsonb,
  started_at    timestamptz not null default now(),
  ended_at      timestamptz
);
create index if not exists game_sessions_room_idx on public.game_sessions (room_id, started_at desc);
create unique index if not exists game_sessions_one_active
  on public.game_sessions (room_id) where status in ('pending','running');

create table if not exists public.rounds (
  id           uuid primary key default gen_random_uuid(),
  session_id   uuid not null references public.game_sessions(id) on delete cascade,
  round_index  int not null,
  phase        round_phase not null default 'pending',
  -- prompt is PUBLIC round data (letter, question, hints…). Secrets never go here.
  prompt       jsonb not null default '{}'::jsonb,
  -- secret_data is server-only (liar word, who-am-I assignments…). Blocked by RLS.
  secret_data  jsonb not null default '{}'::jsonb,
  starts_at    timestamptz not null default now(),
  ends_at      timestamptz not null,
  resolved_at  timestamptz,
  result       jsonb,
  unique (session_id, round_index)
);
create index if not exists rounds_session_idx on public.rounds (session_id, round_index);
create index if not exists rounds_open_idx on public.rounds (ends_at) where resolved_at is null;

-- ---------- content bank ------------------------------------
create table if not exists public.questions (
  id           bigserial primary key,
  game_key     text not null references public.games(key) on delete cascade,
  locale       text not null default 'ar' check (locale in ('ar','en')),
  region       text not null default 'global',   -- 'yemen' | 'arab' | 'global'
  difficulty   int not null default 1 check (difficulty between 1 and 3),
  body         text not null,                    -- question / proverb start / word
  answer       text,                             -- canonical answer
  alt_answers  text[] not null default '{}',     -- accepted dialect variants
  choices      jsonb,                            -- for MCQ / true-false
  hints        text[] not null default '{}',     -- progressive hints (guess_word)
  metadata     jsonb not null default '{}'::jsonb,
  is_active    boolean not null default true,
  created_at   timestamptz not null default now()
);
create index if not exists questions_pick_idx on public.questions (game_key, locale, is_active);
create index if not exists questions_region_idx on public.questions (region);

create table if not exists public.answers (
  id          bigserial primary key,
  round_id    uuid not null references public.rounds(id) on delete cascade,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  payload     jsonb not null default '{}'::jsonb,   -- {"name":"أحمد","animal":"أسد",...} or {"value":"..."}
  is_final    boolean not null default true,
  points      int not null default 0,
  elapsed_ms  int,
  created_at  timestamptz not null default now(),
  unique (round_id, user_id)
);
create index if not exists answers_round_idx on public.answers (round_id);

create table if not exists public.votes (
  id          bigserial primary key,
  round_id    uuid not null references public.rounds(id) on delete cascade,
  voter_id    uuid not null references public.profiles(id) on delete cascade,
  target_user uuid references public.profiles(id) on delete cascade,
  target_key  text,
  kind        vote_kind not null default 'lynch',
  value       boolean,
  created_at  timestamptz not null default now(),
  unique (round_id, voter_id, kind, target_key)
);
create index if not exists votes_round_idx on public.votes (round_id, kind);

-- ---------- mafia (secret state) ----------------------------
create table if not exists public.mafia_roles (
  session_id  uuid not null references public.game_sessions(id) on delete cascade,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  role        mafia_role not null,
  is_alive    boolean not null default true,
  died_round  int,
  revealed    boolean not null default false,
  primary key (session_id, user_id)
);
comment on table public.mafia_roles is
  'RLS: لاعب يقرأ دوره فقط، أو الأدوار بعد انتهاء المباراة. Players may read ONLY their own role until the session ends.';

create table if not exists public.mafia_actions (
  id          bigserial primary key,
  round_id    uuid not null references public.rounds(id) on delete cascade,
  actor_id    uuid not null references public.profiles(id) on delete cascade,
  action      mafia_action_kind not null,
  target_id   uuid references public.profiles(id) on delete cascade,
  created_at  timestamptz not null default now(),
  unique (round_id, actor_id, action)
);
create index if not exists mafia_actions_round_idx on public.mafia_actions (round_id);

-- ---------- scores ------------------------------------------
create table if not exists public.scores (
  id          bigserial primary key,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  session_id  uuid references public.game_sessions(id) on delete set null,
  game_key    text not null references public.games(key) on delete cascade,
  points      int not null default 0,
  is_win      boolean not null default false,
  created_at  timestamptz not null default now()
);
create index if not exists scores_user_idx on public.scores (user_id, created_at desc);
create index if not exists scores_game_idx on public.scores (game_key, created_at desc);
create index if not exists scores_period_idx on public.scores (created_at desc);
