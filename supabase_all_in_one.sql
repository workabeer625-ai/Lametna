-- ============================================================
-- لمّتنا / Lametna — كل ملفات قاعدة البيانات مدمجة بالترتيب
-- مولّد آليًا من supabase/migrations/*.sql + supabase/seed.sql
-- الاستخدام: انسخ كامل هذا الملف والصقه في Supabase SQL Editor ثم Run
-- ============================================================

-- ─────────────────────────────────────────────────────────
-- supabase/migrations/20240101000001_extensions_and_enums.sql
-- ─────────────────────────────────────────────────────────
-- ============================================================
-- لمّتنا / Lametna — 0001 Extensions & Enums
-- ============================================================
create extension if not exists "pgcrypto" with schema extensions;
create extension if not exists "pg_trgm" with schema extensions;

-- ---------- Enums -------------------------------------------
do $$ begin
  create type room_status as enum ('waiting','starting','playing','paused','finished','cancelled');
exception when duplicate_object then null; end $$;

do $$ begin
  create type player_state as enum ('connected','disconnected','ready','not_ready','alive','dead','spectator','banned');
exception when duplicate_object then null; end $$;

do $$ begin
  create type session_status as enum ('pending','running','finished','aborted');
exception when duplicate_object then null; end $$;

do $$ begin
  create type round_phase as enum (
    'pending','prompt','collecting','night','night_actions','day','discussion','voting','scoring','revealed','finished'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type mafia_role as enum ('mafia','citizen','doctor','detective','guard');
exception when duplicate_object then null; end $$;

do $$ begin
  create type mafia_action_kind as enum ('kill','heal','investigate','protect');
exception when duplicate_object then null; end $$;

do $$ begin
  create type vote_kind as enum ('lynch','best_answer','validate_answer','liar','story_line');
exception when duplicate_object then null; end $$;

do $$ begin
  create type report_status as enum ('open','reviewing','resolved','rejected');
exception when duplicate_object then null; end $$;

do $$ begin
  create type ban_scope as enum ('room','global');
exception when duplicate_object then null; end $$;

do $$ begin
  create type app_role as enum ('player','moderator','admin');
exception when duplicate_object then null; end $$;

do $$ begin
  create type game_category as enum ('yemeni','arabic','global','family','fast','competitive');
exception when duplicate_object then null; end $$;


-- ─────────────────────────────────────────────────────────
-- supabase/migrations/20240101000002_core_tables.sql
-- ─────────────────────────────────────────────────────────
-- ============================================================
-- لمّتنا / Lametna — 0002 Core reference & identity tables
-- ============================================================

-- ---------- countries ---------------------------------------
create table if not exists public.countries (
  code        text primary key,               -- ISO-3166 alpha-2, e.g. 'YE'
  name_ar     text not null,
  name_en     text not null,
  flag_emoji  text not null default '',
  region      text not null default 'other',  -- 'arab' | 'other'
  created_at  timestamptz not null default now()
);
comment on table public.countries is 'اختيارية تمامًا للاعب. Country is always optional for a player.';

-- ---------- avatars (bundled, no uploads) -------------------
create table if not exists public.avatars (
  key         text primary key,               -- matches assets/avatars/<key>.png in the app
  name_ar     text not null,
  name_en     text not null,
  sort_order  int  not null default 0,
  is_active   boolean not null default true
);
comment on table public.avatars is 'صور رمزية مجمّعة داخل التطبيق — لا رفع صور شخصية إطلاقًا.';

-- ---------- profiles ----------------------------------------
create table if not exists public.profiles (
  id              uuid primary key references auth.users(id) on delete cascade,
  nickname        text not null,
  nickname_lower  text generated always as (lower(nickname)) stored,
  avatar_key      text references public.avatars(key) on delete set null,
  country_code    text references public.countries(code) on delete set null,
  show_country    boolean not null default false,
  locale          text not null default 'ar' check (locale in ('ar','en')),
  theme_mode      text not null default 'system' check (theme_mode in ('system','light','dark')),
  role            app_role not null default 'player',
  is_guest        boolean not null default false,
  total_points    int not null default 0 check (total_points >= 0),
  games_played    int not null default 0 check (games_played >= 0),
  games_won       int not null default 0 check (games_won >= 0),
  win_streak      int not null default 0,
  best_streak     int not null default 0,
  level           int generated always as (greatest(1, (total_points / 500) + 1)) stored,
  notifications_enabled boolean not null default true,
  deleted_at      timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  constraint nickname_len check (char_length(nickname) between 2 and 24)
);
create unique index if not exists profiles_nickname_unique
  on public.profiles (nickname_lower) where deleted_at is null;
create index if not exists profiles_points_idx on public.profiles (total_points desc) where deleted_at is null;
create index if not exists profiles_country_idx on public.profiles (country_code) where show_country;

-- ---------- guest_sessions ----------------------------------
create table if not exists public.guest_sessions (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  device_hash  text,                           -- opaque, non-identifying
  created_at   timestamptz not null default now(),
  expires_at   timestamptz not null default (now() + interval '30 days')
);
create index if not exists guest_sessions_user_idx on public.guest_sessions (user_id);
create index if not exists guest_sessions_expiry_idx on public.guest_sessions (expires_at);

-- ---------- games catalogue ---------------------------------
create table if not exists public.games (
  key             text primary key,            -- 'animal_plant_object', 'mafia', ...
  name_ar         text not null,
  name_en         text not null,
  description_ar  text not null default '',
  description_en  text not null default '',
  icon            text not null default '🎮',
  categories      game_category[] not null default '{}',
  min_players     int not null default 3 check (min_players >= 2),
  max_players     int not null default 12 check (max_players <= 24),
  default_rounds  int not null default 5 check (default_rounds between 1 and 20),
  round_seconds   int not null default 90 check (round_seconds between 15 and 600),
  is_active       boolean not null default true,
  sort_order      int not null default 0,
  constraint games_player_range check (max_players >= min_players)
);

-- ---------- achievements (badges) ---------------------------
create table if not exists public.achievements (
  key          text primary key,
  name_ar      text not null,
  name_en      text not null,
  description_ar text not null default '',
  description_en text not null default '',
  icon         text not null default '🏅',
  points       int  not null default 0,
  is_active    boolean not null default true
);

create table if not exists public.user_achievements (
  user_id        uuid not null references public.profiles(id) on delete cascade,
  achievement_key text not null references public.achievements(key) on delete cascade,
  awarded_at     timestamptz not null default now(),
  primary key (user_id, achievement_key)
);
create index if not exists user_achievements_user_idx on public.user_achievements (user_id);


-- ─────────────────────────────────────────────────────────
-- supabase/migrations/20240101000003_rooms.sql
-- ─────────────────────────────────────────────────────────
-- ============================================================
-- لمّتنا / Lametna — 0003 Rooms, players, chat
-- ============================================================

create table if not exists public.rooms (
  id              uuid primary key default gen_random_uuid(),
  code            text not null unique check (code ~ '^[A-Z0-9]{6}$'),
  game_key        text not null references public.games(key) on delete restrict,
  host_id         uuid not null references public.profiles(id) on delete cascade,
  title           text not null default '',
  is_public       boolean not null default true,
  password_hash   text,                         -- bcrypt, never returned to clients
  status          room_status not null default 'waiting',
  min_players     int not null default 3,
  max_players     int not null default 12,
  settings        jsonb not null default '{}'::jsonb,
  locale          text not null default 'ar' check (locale in ('ar','en')),
  created_at      timestamptz not null default now(),
  last_activity_at timestamptz not null default now(),
  expires_at      timestamptz not null default (now() + interval '3 hours'),
  closed_at       timestamptz,
  constraint rooms_player_range check (max_players >= min_players and min_players >= 2 and max_players <= 24),
  constraint rooms_title_len check (char_length(title) <= 48)
);
create index if not exists rooms_public_idx on public.rooms (status, is_public, last_activity_at desc)
  where closed_at is null;
create index if not exists rooms_host_idx on public.rooms (host_id);
create index if not exists rooms_expiry_idx on public.rooms (expires_at) where closed_at is null;

create table if not exists public.room_players (
  room_id      uuid not null references public.rooms(id) on delete cascade,
  user_id      uuid not null references public.profiles(id) on delete cascade,
  state        player_state not null default 'connected',
  is_ready     boolean not null default false,
  is_spectator boolean not null default false,
  is_muted     boolean not null default false,
  is_alive     boolean not null default true,
  seat         int,
  score        int not null default 0,
  joined_at    timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  left_at      timestamptz,
  primary key (room_id, user_id)
);
create index if not exists room_players_user_idx on public.room_players (user_id) where left_at is null;
create index if not exists room_players_room_idx on public.room_players (room_id) where left_at is null;
create unique index if not exists room_players_seat_unique
  on public.room_players (room_id, seat) where left_at is null and seat is not null;

-- ---------- chat (text only, short, rate limited) -----------
create table if not exists public.messages (
  id          bigserial primary key,
  room_id     uuid not null references public.rooms(id) on delete cascade,
  user_id     uuid references public.profiles(id) on delete set null,
  body        text not null,
  is_system   boolean not null default false,
  is_hidden   boolean not null default false,
  channel     text not null default 'public' check (channel in ('public','mafia','dead')),
  created_at  timestamptz not null default now(),
  constraint messages_len check (char_length(body) between 1 and 300)
);
create index if not exists messages_room_idx on public.messages (room_id, created_at desc);
create index if not exists messages_rate_idx on public.messages (user_id, created_at desc);


-- ─────────────────────────────────────────────────────────
-- supabase/migrations/20240101000004_gameplay.sql
-- ─────────────────────────────────────────────────────────
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


-- ─────────────────────────────────────────────────────────
-- supabase/migrations/20240101000005_moderation.sql
-- ─────────────────────────────────────────────────────────
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


-- ─────────────────────────────────────────────────────────
-- supabase/migrations/20240101000006_helpers.sql
-- ─────────────────────────────────────────────────────────
-- ============================================================
-- لمّتنا / Lametna — 0006 Helper functions & triggers
-- ============================================================

-- ---------- updated_at trigger ------------------------------
create or replace function public.tg_set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at before update on public.profiles
  for each row execute function public.tg_set_updated_at();

-- ---------- auth helpers ------------------------------------
create or replace function public.current_uid()
returns uuid language sql stable as $$ select auth.uid() $$;

create or replace function public.is_admin(p_user uuid default auth.uid())
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles p where p.id = p_user and p.role in ('admin','moderator'));
$$;

create or replace function public.is_room_member(p_room uuid, p_user uuid default auth.uid())
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.room_players rp
    where rp.room_id = p_room and rp.user_id = p_user and rp.left_at is null
  );
$$;

create or replace function public.is_room_host(p_room uuid, p_user uuid default auth.uid())
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.rooms r where r.id = p_room and r.host_id = p_user);
$$;

create or replace function public.session_room(p_session uuid)
returns uuid language sql stable security definer set search_path = public as $$
  select room_id from public.game_sessions where id = p_session;
$$;

create or replace function public.round_room(p_round uuid)
returns uuid language sql stable security definer set search_path = public as $$
  select gs.room_id from public.rounds r join public.game_sessions gs on gs.id = r.session_id where r.id = p_round;
$$;

create or replace function public.is_globally_banned(p_user uuid default auth.uid())
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.bans b
    where b.user_id = p_user and b.scope = 'global'
      and (b.expires_at is null or b.expires_at > now())
  );
$$;

-- ---------- audit -------------------------------------------
create or replace function public.log_audit(p_action text, p_entity text, p_entity_id text, p_meta jsonb default '{}'::jsonb)
returns void language sql security definer set search_path = public as $$
  insert into public.audit_logs (actor_id, action, entity, entity_id, metadata)
  values (auth.uid(), p_action, p_entity, p_entity_id, coalesce(p_meta,'{}'::jsonb));
$$;

-- ---------- room code generator -----------------------------
create or replace function public.generate_room_code()
returns text language plpgsql security definer set search_path = public, extensions as $$
declare
  alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- no I,O,0,1
  v_code text;
  i int;
begin
  for attempt in 1..20 loop
    v_code := '';
    for i in 1..6 loop
      v_code := v_code || substr(alphabet, 1 + floor(random() * length(alphabet))::int, 1);
    end loop;
    if not exists (select 1 from public.rooms where code = v_code and closed_at is null) then
      return v_code;
    end if;
  end loop;
  raise exception 'ROOM_CODE_EXHAUSTED';
end $$;

-- ---------- text moderation ---------------------------------
-- Normalises Arabic (removes tashkeel/tatweel, unifies alef/yaa) then screens.
create or replace function public.normalize_ar(p_text text)
returns text language sql immutable as $$
  select lower(trim(regexp_replace(
    translate(
      regexp_replace(coalesce(p_text,''), '[\u064B-\u0652\u0640]', '', 'g'),
      'أإآىةؤئ', 'اااهةوي'
    ), '\s+', ' ', 'g')));
$$;

create or replace function public.contains_banned_word(p_text text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.banned_words bw
    where position(public.normalize_ar(bw.word) in public.normalize_ar(p_text)) > 0
  );
$$;

create or replace function public.contains_link(p_text text)
returns boolean language sql immutable as $$
  select coalesce(p_text,'') ~* '(https?://|www\.|t\.me/|wa\.me/|[a-z0-9-]+\.(com|net|org|xyz|ru|top|link|click|info)(/|\s|$))';
$$;

-- Answers must not be empty/abusive/link-spam.
create or replace function public.is_clean_text(p_text text)
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(p_text,'') <> ''
     and not public.contains_link(p_text)
     and not public.contains_banned_word(p_text);
$$;

-- ---------- room activity touch ------------------------------
create or replace function public.touch_room(p_room uuid)
returns void language sql security definer set search_path = public as $$
  update public.rooms
     set last_activity_at = now(),
         expires_at = now() + interval '3 hours'
   where id = p_room;
$$;

-- ---------- profile bootstrap on signup ----------------------
create or replace function public.tg_handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_nick text;
  v_guest boolean;
begin
  v_guest := coalesce((new.raw_user_meta_data ->> 'is_guest')::boolean, new.email is null);
  v_nick  := nullif(trim(new.raw_user_meta_data ->> 'nickname'), '');
  if v_nick is null then
    v_nick := case when v_guest then 'ضيف-' else 'لاعب-' end || substr(replace(new.id::text,'-',''), 1, 5);
  end if;
  -- guarantee uniqueness
  while exists (select 1 from public.profiles p where p.nickname_lower = lower(v_nick)) loop
    v_nick := v_nick || floor(random()*10)::int::text;
  end loop;

  insert into public.profiles (id, nickname, is_guest, avatar_key, locale)
  values (
    new.id,
    v_nick,
    v_guest,
    (select key from public.avatars where is_active order by random() limit 1),
    coalesce(new.raw_user_meta_data ->> 'locale', 'ar')
  )
  on conflict (id) do nothing;

  if v_guest then
    insert into public.guest_sessions (user_id) values (new.id);
  end if;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.tg_handle_new_user();


-- ─────────────────────────────────────────────────────────
-- supabase/migrations/20240101000007_rpc_rooms.sql
-- ─────────────────────────────────────────────────────────
-- ============================================================
-- لمّتنا / Lametna — 0007 Room RPCs (server authoritative)
-- All of these are SECURITY DEFINER: the client can never
-- write to rooms/room_players directly (see RLS migration).
-- ============================================================

-- ---------- create_room --------------------------------------
create or replace function public.create_room(
  p_game_key    text,
  p_is_public   boolean default true,
  p_password    text default null,
  p_title       text default '',
  p_max_players int default null,
  p_settings    jsonb default '{}'::jsonb,
  p_locale      text default 'ar'
) returns public.rooms
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_uid  uuid := auth.uid();
  v_game public.games;
  v_room public.rooms;
  v_active int;
begin
  if v_uid is null then raise exception 'AUTH_REQUIRED'; end if;
  if public.is_globally_banned(v_uid) then raise exception 'USER_BANNED'; end if;

  select * into v_game from public.games where key = p_game_key and is_active;
  if not found then raise exception 'GAME_NOT_FOUND'; end if;

  -- free-tier guard: max 2 open rooms hosted per user
  select count(*) into v_active from public.rooms
   where host_id = v_uid and closed_at is null and status <> 'finished';
  if v_active >= 2 then raise exception 'TOO_MANY_ROOMS'; end if;

  -- leave any previous room first
  perform public.leave_room(rp.room_id) from public.room_players rp
    where rp.user_id = v_uid and rp.left_at is null;

  insert into public.rooms (code, game_key, host_id, title, is_public, password_hash,
                            min_players, max_players, settings, locale)
  values (
    public.generate_room_code(),
    p_game_key,
    v_uid,
    left(coalesce(nullif(trim(p_title),''), ''), 48),
    coalesce(p_is_public, true),
    case when nullif(p_password,'') is null then null
         else extensions.crypt(p_password, extensions.gen_salt('bf', 8)) end,
    v_game.min_players,
    least(coalesce(p_max_players, v_game.max_players), v_game.max_players),
    coalesce(p_settings, '{}'::jsonb),
    coalesce(p_locale, 'ar')
  )
  returning * into v_room;

  insert into public.room_players (room_id, user_id, state, seat)
  values (v_room.id, v_uid, 'connected', 1);

  insert into public.messages (room_id, is_system, body)
  values (v_room.id, true, 'تم إنشاء الغرفة');

  perform public.log_audit('room.create','room', v_room.id::text,
                           jsonb_build_object('game', p_game_key, 'public', p_is_public));
  return v_room;
end $$;

-- ---------- join_room ----------------------------------------
create or replace function public.join_room(
  p_code     text,
  p_password text default null,
  p_as_spectator boolean default false
) returns public.rooms
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_uid   uuid := auth.uid();
  v_room  public.rooms;
  v_count int;
  v_seat  int;
  v_existing public.room_players;
begin
  if v_uid is null then raise exception 'AUTH_REQUIRED'; end if;
  if public.is_globally_banned(v_uid) then raise exception 'USER_BANNED'; end if;

  select * into v_room from public.rooms
   where code = upper(trim(p_code)) and closed_at is null
   for update;
  if not found then raise exception 'ROOM_NOT_FOUND'; end if;
  if v_room.status in ('finished','cancelled') then raise exception 'ROOM_CLOSED'; end if;

  if exists (select 1 from public.bans b
              where b.user_id = v_uid and b.room_id = v_room.id
                and (b.expires_at is null or b.expires_at > now())) then
    raise exception 'ROOM_BANNED';
  end if;

  if v_room.password_hash is not null
     and extensions.crypt(coalesce(p_password,''), v_room.password_hash) <> v_room.password_hash then
    raise exception 'WRONG_PASSWORD';
  end if;

  -- rejoin (reconnect) path
  select * into v_existing from public.room_players
    where room_id = v_room.id and user_id = v_uid;
  if found then
    update public.room_players
       set left_at = null, state = 'connected', last_seen_at = now()
     where room_id = v_room.id and user_id = v_uid;
    perform public.touch_room(v_room.id);
    return v_room;
  end if;

  select count(*) into v_count from public.room_players
   where room_id = v_room.id and left_at is null and not is_spectator;

  if not p_as_spectator and v_count >= v_room.max_players then
    raise exception 'ROOM_FULL';
  end if;
  if v_room.status = 'playing' and not p_as_spectator then
    raise exception 'GAME_IN_PROGRESS';
  end if;

  select coalesce(max(seat),0) + 1 into v_seat from public.room_players
   where room_id = v_room.id and left_at is null;

  insert into public.room_players (room_id, user_id, state, is_spectator, seat)
  values (v_room.id, v_uid, 'connected', p_as_spectator,
          case when p_as_spectator then null else v_seat end);

  insert into public.messages (room_id, is_system, body)
  values (v_room.id, true,
          (select nickname from public.profiles where id = v_uid) || ' انضم إلى الغرفة');

  perform public.touch_room(v_room.id);
  return v_room;
end $$;

-- ---------- leave_room ---------------------------------------
create or replace function public.leave_room(p_room uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_uid  uuid := auth.uid();
  v_room public.rooms;
  v_next uuid;
  v_left int;
begin
  if v_uid is null then raise exception 'AUTH_REQUIRED'; end if;
  select * into v_room from public.rooms where id = p_room for update;
  if not found then return; end if;

  update public.room_players
     set left_at = now(), state = 'disconnected', is_ready = false
   where room_id = p_room and user_id = v_uid and left_at is null;
  if not found then return; end if;

  select count(*) into v_left from public.room_players
   where room_id = p_room and left_at is null and not is_spectator;

  if v_left = 0 then
    update public.rooms set status = 'cancelled', closed_at = now() where id = p_room;
  elsif v_room.host_id = v_uid then
    -- automatic host transfer to the longest-present player
    select user_id into v_next from public.room_players
     where room_id = p_room and left_at is null and not is_spectator
     order by joined_at asc limit 1;
    if v_next is not null then
      update public.rooms set host_id = v_next where id = p_room;
      insert into public.messages (room_id, is_system, body)
      values (p_room, true, 'تم نقل إدارة الغرفة إلى ' ||
              (select nickname from public.profiles where id = v_next));
    end if;
  end if;

  perform public.touch_room(p_room);
end $$;

-- ---------- heartbeat / presence ------------------------------
create or replace function public.heartbeat(p_room uuid)
returns void language sql security definer set search_path = public as $$
  update public.room_players
     set last_seen_at = now(),
         state = case when state = 'disconnected' then 'connected' else state end
   where room_id = p_room and user_id = auth.uid() and left_at is null;
$$;

-- ---------- set_ready -----------------------------------------
create or replace function public.set_ready(p_room uuid, p_ready boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_room_member(p_room) then raise exception 'NOT_A_MEMBER'; end if;
  update public.room_players
     set is_ready = p_ready, state = case when p_ready then 'ready' else 'not_ready' end,
         last_seen_at = now()
   where room_id = p_room and user_id = auth.uid() and left_at is null and not is_spectator;
  perform public.touch_room(p_room);
end $$;

-- ---------- transfer_host --------------------------------------
create or replace function public.transfer_host(p_room uuid, p_new_host uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_room_host(p_room) and not public.is_admin() then raise exception 'NOT_HOST'; end if;
  if not public.is_room_member(p_room, p_new_host) then raise exception 'TARGET_NOT_MEMBER'; end if;
  update public.rooms set host_id = p_new_host where id = p_room;
  insert into public.messages (room_id, is_system, body)
  values (p_room, true, 'المضيف الجديد: ' || (select nickname from public.profiles where id = p_new_host));
  perform public.log_audit('room.transfer_host','room', p_room::text, jsonb_build_object('to', p_new_host));
  perform public.touch_room(p_room);
end $$;

-- ---------- kick / ban / mute -----------------------------------
create or replace function public.kick_player(p_room uuid, p_user uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_room_host(p_room) and not public.is_admin() then raise exception 'NOT_HOST'; end if;
  if p_user = auth.uid() then raise exception 'CANNOT_KICK_SELF'; end if;
  update public.room_players set left_at = now(), state = 'disconnected'
   where room_id = p_room and user_id = p_user;
  insert into public.messages (room_id, is_system, body)
  values (p_room, true, 'تم إخراج ' || (select nickname from public.profiles where id = p_user));
  perform public.log_audit('room.kick','room', p_room::text, jsonb_build_object('user', p_user));
end $$;

create or replace function public.ban_player(p_room uuid, p_user uuid, p_reason text default '')
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_room_host(p_room) and not public.is_admin() then raise exception 'NOT_HOST'; end if;
  if p_user = auth.uid() then raise exception 'CANNOT_BAN_SELF'; end if;
  insert into public.bans (user_id, scope, room_id, reason, created_by)
  values (p_user, 'room', p_room, left(coalesce(p_reason,''),200), auth.uid());
  update public.room_players set left_at = now(), state = 'banned'
   where room_id = p_room and user_id = p_user;
  perform public.log_audit('room.ban','room', p_room::text, jsonb_build_object('user', p_user));
end $$;

create or replace function public.mute_player(p_room uuid, p_user uuid, p_muted boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_room_host(p_room) and not public.is_admin() then raise exception 'NOT_HOST'; end if;
  update public.room_players set is_muted = p_muted where room_id = p_room and user_id = p_user;
  perform public.log_audit('room.mute','room', p_room::text,
                           jsonb_build_object('user', p_user, 'muted', p_muted));
end $$;

-- personal block (client-side hiding + server-side chat filtering)
create or replace function public.block_user(p_user uuid, p_blocked boolean default true)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null or p_user = auth.uid() then raise exception 'INVALID'; end if;
  if p_blocked then
    insert into public.user_blocks (blocker_id, blocked_id) values (auth.uid(), p_user)
    on conflict do nothing;
  else
    delete from public.user_blocks where blocker_id = auth.uid() and blocked_id = p_user;
  end if;
end $$;

-- ---------- chat -------------------------------------------------
create or replace function public.send_message(p_room uuid, p_body text, p_channel text default 'public')
returns public.messages
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_msg public.messages;
  v_recent int;
  v_body text := trim(p_body);
  v_alive boolean;
begin
  if not public.is_room_member(p_room) then raise exception 'NOT_A_MEMBER'; end if;
  if (select is_muted from public.room_players where room_id = p_room and user_id = v_uid) then
    raise exception 'MUTED';
  end if;
  if char_length(v_body) = 0 or char_length(v_body) > 300 then raise exception 'BAD_LENGTH'; end if;
  if public.contains_link(v_body) then raise exception 'LINKS_NOT_ALLOWED'; end if;
  if public.contains_banned_word(v_body) then raise exception 'BLOCKED_CONTENT'; end if;

  -- rate limit: 10 messages / 60 seconds
  select count(*) into v_recent from public.messages
   where user_id = v_uid and created_at > now() - interval '60 seconds';
  if v_recent >= 10 then raise exception 'RATE_LIMITED'; end if;

  -- channel authorisation
  if p_channel = 'mafia' then
    if not exists (select 1 from public.mafia_roles mr
                    join public.game_sessions gs on gs.id = mr.session_id
                   where gs.room_id = p_room and gs.status = 'running'
                     and mr.user_id = v_uid and mr.role = 'mafia' and mr.is_alive) then
      raise exception 'NOT_MAFIA';
    end if;
  elsif p_channel = 'dead' then
    select is_alive into v_alive from public.room_players where room_id = p_room and user_id = v_uid;
    if coalesce(v_alive, true) then raise exception 'NOT_DEAD'; end if;
  elsif p_channel = 'public' then
    -- dead players cannot speak in the public channel during a running mafia game
    if exists (select 1 from public.game_sessions gs
                where gs.room_id = p_room and gs.status = 'running' and gs.game_key = 'mafia')
       and not coalesce((select is_alive from public.room_players
                          where room_id = p_room and user_id = v_uid), true) then
      raise exception 'DEAD_CANNOT_SPEAK';
    end if;
  else
    raise exception 'BAD_CHANNEL';
  end if;

  insert into public.messages (room_id, user_id, body, channel)
  values (p_room, v_uid, v_body, p_channel)
  returning * into v_msg;

  perform public.touch_room(p_room);
  return v_msg;
end $$;

-- ---------- reporting ---------------------------------------------
create or replace function public.report_user(
  p_reported uuid, p_reason text, p_room uuid default null,
  p_message_id bigint default null, p_details text default null
) returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
  if p_reported = auth.uid() then raise exception 'CANNOT_REPORT_SELF'; end if;
  insert into public.reports (reporter_id, reported_id, room_id, message_id, reason, details)
  values (auth.uid(), p_reported, p_room, p_message_id, p_reason, left(coalesce(p_details,''),500))
  on conflict do nothing;
  perform public.log_audit('report.create','profile', p_reported::text,
                           jsonb_build_object('reason', p_reason));
end $$;

-- ---------- public room browser (no password hash leaked) ----------
create or replace function public.list_public_rooms(p_game_key text default null, p_limit int default 30)
returns table (
  id uuid, code text, game_key text, title text, status room_status,
  player_count bigint, max_players int, has_password boolean,
  host_nickname text, locale text, created_at timestamptz
) language sql stable security definer set search_path = public as $$
  select r.id, r.code, r.game_key, r.title, r.status,
         (select count(*) from public.room_players rp
           where rp.room_id = r.id and rp.left_at is null and not rp.is_spectator),
         r.max_players,
         r.password_hash is not null,
         p.nickname, r.locale, r.created_at
    from public.rooms r
    join public.profiles p on p.id = r.host_id
   where r.is_public
     and r.closed_at is null
     and r.status in ('waiting','starting','playing')
     and r.expires_at > now()
     and (p_game_key is null or r.game_key = p_game_key)
   order by r.status asc, r.last_activity_at desc
   limit greatest(1, least(coalesce(p_limit,30), 50));
$$;

-- ---------- cleanup (called by the scheduled Edge Function) ---------
create or replace function public.cleanup_stale_rooms()
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_rooms int; v_msgs int; v_rounds int; v_guests int;
begin
  -- close rooms with no activity
  with closed as (
    update public.rooms set status = 'cancelled', closed_at = now()
     where closed_at is null and (expires_at < now() or last_activity_at < now() - interval '2 hours')
     returning id
  ) select count(*) into v_rooms from closed;

  -- abort orphaned sessions
  update public.game_sessions gs set status = 'aborted', ended_at = now()
   where gs.status in ('pending','running')
     and exists (select 1 from public.rooms r where r.id = gs.room_id and r.closed_at is not null);

  -- hard-delete rooms closed more than 24h ago (cascades to players/rounds/messages)
  delete from public.rooms where closed_at is not null and closed_at < now() - interval '24 hours';

  -- trim chat history: keep 7 days max
  with d as (delete from public.messages where created_at < now() - interval '7 days' returning 1)
  select count(*) into v_msgs from d;

  -- trim resolved rounds older than 7 days
  with d as (delete from public.rounds where resolved_at is not null and resolved_at < now() - interval '7 days' returning 1)
  select count(*) into v_rounds from d;

  -- expire guest sessions
  with d as (delete from public.guest_sessions where expires_at < now() returning 1)
  select count(*) into v_guests from d;

  -- trim audit logs (90 days)
  delete from public.audit_logs where created_at < now() - interval '90 days';
  -- trim notifications (30 days)
  delete from public.notifications where created_at < now() - interval '30 days';

  return jsonb_build_object('rooms_closed', v_rooms, 'messages_deleted', v_msgs,
                            'rounds_deleted', v_rounds, 'guests_expired', v_guests, 'at', now());
end $$;


-- ─────────────────────────────────────────────────────────
-- supabase/migrations/20240101000008_rpc_gameplay.sql
-- ─────────────────────────────────────────────────────────
-- ============================================================
-- لمّتنا / Lametna — 0008 Gameplay RPCs
-- The client NEVER computes points, roles, timers or results.
-- ============================================================

-- ---------- internal: create the next round -------------------
create or replace function public._begin_round(p_session uuid, p_index int)
returns public.rounds
language plpgsql security definer set search_path = public as $$
declare
  v_s        public.game_sessions;
  v_game     public.games;
  v_room     public.rooms;
  v_round    public.rounds;
  v_seconds  int;
  v_prompt   jsonb := '{}'::jsonb;
  v_secret   jsonb := '{}'::jsonb;
  v_phase    round_phase := 'collecting';
  v_letters  constant text[] := array['ا','ب','ت','ج','ح','خ','د','ر','س','ش','ص','ط','ع','ف','ق','ك','ل','م','ن','ه','و','ي'];
  v_q        public.questions;
  v_players  uuid[];
  v_liar     uuid;
  v_assign   jsonb := '{}'::jsonb;
  v_pid      uuid;
  v_i        int := 0;
begin
  select * into v_s from public.game_sessions where id = p_session;
  select * into v_room from public.rooms where id = v_s.room_id;
  select * into v_game from public.games where key = v_s.game_key;
  v_seconds := coalesce((v_s.config ->> 'round_seconds')::int, v_game.round_seconds);

  select array_agg(user_id order by seat) into v_players
    from public.room_players
   where room_id = v_s.room_id and left_at is null and not is_spectator and is_alive;

  if v_s.game_key = 'animal_plant_object' then
    v_prompt := jsonb_build_object(
      'stage','answer',
      'letter', v_letters[1 + floor(random() * array_length(v_letters,1))::int],
      'categories', coalesce(v_s.config -> 'categories',
        '["name","animal","plant","object","country","city","food","job"]'::jsonb)
    );

  elsif v_s.game_key = 'mafia' then
    if p_index % 2 = 1 then
      v_phase := 'night';
      v_seconds := coalesce((v_s.config ->> 'night_seconds')::int, 45);
      v_prompt := jsonb_build_object('stage','night','cycle', (p_index + 1) / 2);
    else
      v_phase := 'voting';
      v_seconds := coalesce((v_s.config ->> 'day_seconds')::int, 120);
      v_prompt := jsonb_build_object('stage','day','cycle', p_index / 2);
    end if;

  elsif v_s.game_key in ('true_false','guess_word','proverbs','who_am_i') then
    select * into v_q from public.questions
     where game_key = v_s.game_key and is_active and locale = v_room.locale
       and id <> all (coalesce(
             (select array_agg((r.prompt ->> 'question_id')::bigint)
                from public.rounds r
               where r.session_id = p_session and r.prompt ? 'question_id'), '{}'::bigint[]))
     order by random() limit 1;
    if v_q.id is null then
      select * into v_q from public.questions
       where game_key = v_s.game_key and is_active order by random() limit 1;
    end if;
    if v_q.id is null then raise exception 'NO_CONTENT_FOR_GAME'; end if;

    v_prompt := jsonb_build_object(
      'stage','answer',
      'question_id', v_q.id,
      'body', v_q.body,
      'choices', v_q.choices,
      -- guess_word reveals hints progressively on the client using a server clock
      'hints', case when v_s.game_key = 'guess_word' then to_jsonb(v_q.hints) else '[]'::jsonb end,
      'metadata', v_q.metadata
    );
    v_secret := jsonb_build_object('answer', v_q.answer, 'alt', to_jsonb(v_q.alt_answers));

  elsif v_s.game_key = 'liar' then
    select * into v_q from public.questions where game_key = 'liar' and is_active
     order by random() limit 1;
    if v_q.id is null then raise exception 'NO_CONTENT_FOR_GAME'; end if;
    v_liar := v_players[1 + floor(random() * array_length(v_players,1))::int];
    foreach v_pid in array v_players loop
      v_assign := v_assign || jsonb_build_object(
        v_pid::text,
        case when v_pid = v_liar then coalesce(v_q.metadata ->> 'decoy', '') else v_q.body end);
    end loop;
    v_prompt := jsonb_build_object('stage','describe', 'category', coalesce(v_q.metadata ->> 'category',''));
    v_secret := jsonb_build_object('liar', v_liar, 'word', v_q.body, 'assignments', v_assign);

  elsif v_s.game_key = 'group_story' then
    select * into v_q from public.questions where game_key = 'group_story' and is_active
     order by random() limit 1;
    v_prompt := jsonb_build_object('stage','write',
                'opening', coalesce(v_q.body, 'كان يا ما كان…'));
  else
    raise exception 'UNKNOWN_GAME %', v_s.game_key;
  end if;

  insert into public.rounds (session_id, round_index, phase, prompt, secret_data, starts_at, ends_at)
  values (p_session, p_index, v_phase, v_prompt, v_secret, now(), now() + make_interval(secs => v_seconds))
  returning * into v_round;

  update public.game_sessions set current_round = p_index where id = p_session;
  perform public.touch_room(v_s.room_id);
  return v_round;
end $$;

-- ---------- start_game ----------------------------------------
create or replace function public.start_game(p_room uuid, p_rounds int default null, p_config jsonb default '{}'::jsonb)
returns public.game_sessions
language plpgsql security definer set search_path = public as $$
declare
  v_room    public.rooms;
  v_game    public.games;
  v_session public.game_sessions;
  v_count   int;
  v_players uuid[];
  v_mafia_n int;
  v_i       int;
  v_roles   mafia_role[];
begin
  if not public.is_room_host(p_room) then raise exception 'NOT_HOST'; end if;
  select * into v_room from public.rooms where id = p_room for update;
  if v_room.status not in ('waiting','finished') then raise exception 'ALREADY_STARTED'; end if;
  select * into v_game from public.games where key = v_room.game_key;

  select count(*), array_agg(user_id order by seat) into v_count, v_players
    from public.room_players
   where room_id = p_room and left_at is null and not is_spectator;

  if v_count < v_room.min_players then raise exception 'NOT_ENOUGH_PLAYERS'; end if;
  if exists (select 1 from public.room_players
              where room_id = p_room and left_at is null and not is_spectator
                and not is_ready and user_id <> v_room.host_id) then
    raise exception 'PLAYERS_NOT_READY';
  end if;

  -- reset per-match player state (supports "play again")
  update public.room_players
     set score = 0, is_alive = true, state = 'alive'
   where room_id = p_room and left_at is null;

  update public.rooms set status = 'playing' where id = p_room;

  insert into public.game_sessions (room_id, game_key, status, total_rounds, config)
  values (p_room, v_room.game_key, 'running',
          coalesce(p_rounds, v_game.default_rounds),
          coalesce(p_config,'{}'::jsonb) || v_room.settings)
  returning * into v_session;

  -- Mafia: roles are assigned HERE, on the server, and never leave the DB
  -- except to their own owner (see RLS policy on mafia_roles).
  if v_room.game_key = 'mafia' then
    v_mafia_n := greatest(1, floor(v_count / 3.5)::int);
    v_roles := array_fill('citizen'::mafia_role, array[v_count]);
    for v_i in 1..v_mafia_n loop v_roles[v_i] := 'mafia'; end loop;
    if v_count >= 5 then v_roles[v_mafia_n + 1] := 'doctor'; end if;
    if v_count >= 6 then v_roles[v_mafia_n + 2] := 'detective'; end if;
    if v_count >= 8 then v_roles[v_mafia_n + 3] := 'guard'; end if;
    -- Fisher-Yates style shuffle over the player array
    select array_agg(uid order by random()) into v_players from unnest(v_players) as t(uid);
    for v_i in 1..v_count loop
      insert into public.mafia_roles (session_id, user_id, role)
      values (v_session.id, v_players[v_i], v_roles[v_i]);
    end loop;
    update public.game_sessions
       set total_rounds = 40,  -- mafia ends on a win condition, not a round count
           config = v_session.config || jsonb_build_object('mafia_count', v_mafia_n)
     where id = v_session.id
     returning * into v_session;
  end if;

  perform public._begin_round(v_session.id, 1);
  perform public.log_audit('game.start','session', v_session.id::text,
                           jsonb_build_object('game', v_room.game_key, 'players', v_count));
  return v_session;
end $$;

-- ---------- submit_answer --------------------------------------
create or replace function public.submit_answer(p_round uuid, p_payload jsonb)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_uid   uuid := auth.uid();
  v_round public.rounds;
  v_room  uuid;
  v_txt   text;
begin
  select * into v_round from public.rounds where id = p_round;
  if not found then raise exception 'ROUND_NOT_FOUND'; end if;
  v_room := public.round_room(p_round);
  if not public.is_room_member(v_room) then raise exception 'NOT_A_MEMBER'; end if;
  if v_round.resolved_at is not null then raise exception 'ROUND_CLOSED'; end if;
  if now() > v_round.ends_at + interval '2 seconds' then raise exception 'TIME_OVER'; end if;
  if not coalesce((select is_alive from public.room_players
                    where room_id = v_room and user_id = v_uid), false) then
    raise exception 'NOT_ALIVE';
  end if;
  if (select is_spectator from public.room_players where room_id = v_room and user_id = v_uid) then
    raise exception 'SPECTATOR';
  end if;

  -- content screening on every free-text value
  for v_txt in select value from jsonb_each_text(coalesce(p_payload,'{}'::jsonb)) loop
    if char_length(v_txt) > 200 then raise exception 'ANSWER_TOO_LONG'; end if;
    if v_txt <> '' and (public.contains_link(v_txt) or public.contains_banned_word(v_txt)) then
      raise exception 'BLOCKED_CONTENT';
    end if;
  end loop;

  -- immutable once submitted
  insert into public.answers (round_id, user_id, payload, elapsed_ms)
  values (p_round, v_uid, coalesce(p_payload,'{}'::jsonb),
          greatest(0, extract(epoch from (now() - v_round.starts_at)) * 1000)::int)
  on conflict (round_id, user_id) do nothing;

  if not found then raise exception 'ALREADY_SUBMITTED'; end if;
  perform public.touch_room(v_room);
end $$;

-- ---------- cast_vote -------------------------------------------
create or replace function public.cast_vote(
  p_round uuid, p_kind vote_kind,
  p_target_user uuid default null, p_target_key text default null, p_value boolean default null)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_uid   uuid := auth.uid();
  v_round public.rounds;
  v_room  uuid;
begin
  select * into v_round from public.rounds where id = p_round;
  if not found then raise exception 'ROUND_NOT_FOUND'; end if;
  v_room := public.round_room(p_round);
  if not public.is_room_member(v_room) then raise exception 'NOT_A_MEMBER'; end if;
  if v_round.resolved_at is not null then raise exception 'ROUND_CLOSED'; end if;
  if now() > v_round.ends_at + interval '2 seconds' then raise exception 'TIME_OVER'; end if;
  if not coalesce((select is_alive from public.room_players
                    where room_id = v_room and user_id = v_uid), false) then
    raise exception 'DEAD_CANNOT_VOTE';
  end if;
  if p_target_user is not null and not public.is_room_member(v_room, p_target_user) then
    raise exception 'TARGET_NOT_MEMBER';
  end if;
  if p_kind = 'lynch' then
    if p_target_user = v_uid then raise exception 'CANNOT_VOTE_SELF'; end if;
    if p_target_user is not null and not coalesce(
        (select is_alive from public.room_players where room_id = v_room and user_id = p_target_user), false) then
      raise exception 'TARGET_DEAD';
    end if;
    -- one lynch vote per player per round (changeable until the round closes)
    delete from public.votes where round_id = p_round and voter_id = v_uid and kind = 'lynch';
  end if;

  insert into public.votes (round_id, voter_id, target_user, target_key, kind, value)
  values (p_round, v_uid, p_target_user, p_target_key, p_kind, p_value)
  on conflict (round_id, voter_id, kind, target_key) do update
    set target_user = excluded.target_user, value = excluded.value, created_at = now();

  perform public.touch_room(v_room);
end $$;

-- ---------- mafia night action -----------------------------------
create or replace function public.submit_mafia_action(
  p_round uuid, p_action mafia_action_kind, p_target uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_uid   uuid := auth.uid();
  v_round public.rounds;
  v_room  uuid;
  v_sess  uuid;
  v_role  mafia_role;
  v_alive boolean;
  v_result jsonb := '{}'::jsonb;
begin
  select * into v_round from public.rounds where id = p_round;
  if not found then raise exception 'ROUND_NOT_FOUND'; end if;
  if v_round.phase <> 'night' then raise exception 'NOT_NIGHT'; end if;
  if v_round.resolved_at is not null or now() > v_round.ends_at + interval '2 seconds' then
    raise exception 'ROUND_CLOSED';
  end if;

  v_sess := v_round.session_id;
  v_room := public.round_room(p_round);

  select role, is_alive into v_role, v_alive from public.mafia_roles
   where session_id = v_sess and user_id = v_uid;
  if v_role is null then raise exception 'NOT_IN_GAME'; end if;
  if not v_alive then raise exception 'DEAD_CANNOT_ACT'; end if;

  -- role ↔ action authorisation
  if (p_action = 'kill'        and v_role <> 'mafia')
  or (p_action = 'heal'        and v_role <> 'doctor')
  or (p_action = 'investigate' and v_role <> 'detective')
  or (p_action = 'protect'     and v_role <> 'guard') then
    raise exception 'ACTION_NOT_ALLOWED';
  end if;

  if not exists (select 1 from public.mafia_roles
                  where session_id = v_sess and user_id = p_target and is_alive) then
    raise exception 'TARGET_NOT_ALIVE';
  end if;
  if p_action = 'kill' and p_target = v_uid then raise exception 'CANNOT_KILL_SELF'; end if;
  if p_action = 'investigate' and p_target = v_uid then raise exception 'CANNOT_INVESTIGATE_SELF'; end if;

  insert into public.mafia_actions (round_id, actor_id, action, target_id)
  values (p_round, v_uid, p_action, p_target)
  on conflict (round_id, actor_id, action) do nothing;
  if not found then raise exception 'ACTION_ALREADY_SUBMITTED'; end if;

  -- the detective result is returned ONLY to the detective, and never stored publicly
  if p_action = 'investigate' then
    v_result := jsonb_build_object('is_mafia',
      (select role = 'mafia' from public.mafia_roles where session_id = v_sess and user_id = p_target));
  end if;

  perform public.touch_room(v_room);
  return v_result;
end $$;


-- ─────────────────────────────────────────────────────────
-- supabase/migrations/20240101000009_rpc_resolve.sql
-- ─────────────────────────────────────────────────────────
-- ============================================================
-- لمّتنا / Lametna — 0009 Round resolution, scoring, win checks
-- Idempotent and server-authoritative. Any room member (or the
-- scheduled Edge Function) may *trigger* resolution, but only
-- the server decides the outcome.
-- ============================================================

create or replace function public._award(p_round uuid, p_user uuid, p_points int)
returns void language plpgsql security definer set search_path = public as $$
declare v_room uuid;
begin
  if p_points = 0 then return; end if;
  v_room := public.round_room(p_round);
  update public.answers set points = points + p_points where round_id = p_round and user_id = p_user;
  update public.room_players set score = score + p_points where room_id = v_room and user_id = p_user;
end $$;

-- flexible Arabic comparison (exact, dialect variants, or trigram similarity)
create or replace function public.answer_matches(p_given text, p_answer text, p_alt text[], p_fuzzy boolean default false)
returns boolean language sql stable security definer set search_path = public, extensions as $$
  select case
    when coalesce(p_given,'') = '' then false
    when public.normalize_ar(p_given) = public.normalize_ar(coalesce(p_answer,'')) then true
    when exists (select 1 from unnest(coalesce(p_alt,'{}'::text[])) a
                  where public.normalize_ar(a) = public.normalize_ar(p_given)) then true
    when p_fuzzy and coalesce(p_answer,'') <> ''
         and extensions.similarity(public.normalize_ar(p_given), public.normalize_ar(p_answer)) >= 0.72 then true
    else false
  end;
$$;

-- ---------- achievements --------------------------------------
create or replace function public._grant_achievement(p_user uuid, p_key text)
returns void language plpgsql security definer set search_path = public as $$
begin
  insert into public.user_achievements (user_id, achievement_key)
  values (p_user, p_key) on conflict do nothing;
  if found then
    insert into public.notifications (user_id, title_ar, title_en, body_ar, body_en, kind, payload)
    select p_user, 'شارة جديدة! 🏅', 'New badge! 🏅', a.name_ar, a.name_en, 'achievement',
           jsonb_build_object('key', a.key)
      from public.achievements a where a.key = p_key;
  end if;
end $$;

create or replace function public._evaluate_achievements(p_user uuid, p_game text, p_is_win boolean)
returns void language plpgsql security definer set search_path = public as $$
declare v_p public.profiles;
begin
  select * into v_p from public.profiles where id = p_user;
  if v_p.id is null then return; end if;

  if p_is_win and v_p.games_won >= 1 then perform public._grant_achievement(p_user, 'first_win'); end if;
  if v_p.games_played >= 20 then perform public._grant_achievement(p_user, 'active_player'); end if;
  if v_p.win_streak >= 3 then perform public._grant_achievement(p_user, 'streak_master'); end if;

  if p_is_win and p_game = 'mafia'
     and (select count(*) from public.scores where user_id = p_user and game_key = 'mafia' and is_win) >= 3 then
    perform public._grant_achievement(p_user, 'mafia_king');
  end if;
  if p_game = 'animal_plant_object'
     and (select coalesce(sum(points),0) from public.scores
           where user_id = p_user and game_key = 'animal_plant_object') >= 300 then
    perform public._grant_achievement(p_user, 'apo_expert');
  end if;
  if p_game = 'proverbs'
     and (select count(*) from public.scores where user_id = p_user and game_key = 'proverbs' and is_win) >= 3 then
    perform public._grant_achievement(p_user, 'proverbs_champion');
  end if;
end $$;

-- ---------- finish a session ----------------------------------
create or replace function public._finish_session(p_session uuid, p_winners uuid[], p_reason text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_s      public.game_sessions;
  v_result jsonb;
  v_rp     record;
  v_win    boolean;
begin
  select * into v_s from public.game_sessions where id = p_session for update;
  if v_s.status = 'finished' then return v_s.result; end if;

  if p_winners is null or array_length(p_winners,1) is null then
    select array_agg(user_id) into p_winners from (
      select user_id from public.room_players
       where room_id = v_s.room_id and left_at is null and not is_spectator
       order by score desc limit 1
    ) t;
  end if;

  select jsonb_build_object(
           'reason', p_reason,
           'winners', to_jsonb(coalesce(p_winners,'{}'::uuid[])),
           'standings', coalesce(jsonb_agg(jsonb_build_object(
              'user_id', rp.user_id, 'nickname', p.nickname,
              'avatar_key', p.avatar_key, 'score', rp.score)
              order by rp.score desc), '[]'::jsonb))
    into v_result
    from public.room_players rp
    join public.profiles p on p.id = rp.user_id
   where rp.room_id = v_s.room_id and not rp.is_spectator;

  for v_rp in
    select user_id, score from public.room_players
     where room_id = v_s.room_id and not is_spectator
  loop
    v_win := v_rp.user_id = any(coalesce(p_winners,'{}'::uuid[]));
    insert into public.scores (user_id, session_id, game_key, points, is_win)
    values (v_rp.user_id, p_session, v_s.game_key, greatest(v_rp.score, 0), v_win);

    update public.profiles
       set total_points = total_points + greatest(v_rp.score, 0),
           games_played = games_played + 1,
           games_won    = games_won + (case when v_win then 1 else 0 end),
           win_streak   = case when v_win then win_streak + 1 else 0 end,
           best_streak  = greatest(best_streak, case when v_win then win_streak + 1 else 0 end)
     where id = v_rp.user_id;

    perform public._evaluate_achievements(v_rp.user_id, v_s.game_key, v_win);
  end loop;

  update public.game_sessions set status = 'finished', ended_at = now(), result = v_result
   where id = p_session;
  update public.rooms set status = 'finished' where id = v_s.room_id;
  update public.room_players set is_ready = false where room_id = v_s.room_id;

  insert into public.messages (room_id, is_system, body) values (v_s.room_id, true, 'انتهت المباراة');
  perform public.log_audit('game.finish','session', p_session::text, jsonb_build_object('reason', p_reason));
  return v_result;
end $$;

-- ---------- mafia win check ------------------------------------
create or replace function public._mafia_check_win(p_session uuid)
returns text language plpgsql security definer set search_path = public as $$
declare v_mafia int; v_others int;
begin
  select count(*) filter (where role = 'mafia' and is_alive),
         count(*) filter (where role <> 'mafia' and is_alive)
    into v_mafia, v_others
    from public.mafia_roles where session_id = p_session;
  if v_mafia = 0 then return 'citizens'; end if;
  if v_mafia >= v_others then return 'mafia'; end if;
  return null;
end $$;

-- ---------- the resolver ----------------------------------------
create or replace function public.resolve_round(p_round uuid)
returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_round   public.rounds;
  v_s       public.game_sessions;
  v_room    uuid;
  v_alive   int;
  v_submitted int;
  v_result  jsonb := '{}'::jsonb;
  v_stage   text;
  v_letter  text;
  v_cats    text[];
  v_cat     text;
  v_ans     record;
  v_val     text;
  v_norm    text;
  v_dups    jsonb;
  v_pts     int;
  v_rank    int;
  v_killed  uuid;
  v_saved   boolean := false;
  v_lynched uuid;
  v_top     int;
  v_winner  text;
  v_liar    uuid;
  v_accused uuid;
  v_correct boolean;
  v_fuzzy   boolean;
begin
  select * into v_round from public.rounds where id = p_round for update;
  if not found then raise exception 'ROUND_NOT_FOUND'; end if;
  if v_round.resolved_at is not null then return coalesce(v_round.result, '{}'::jsonb); end if;

  select * into v_s from public.game_sessions where id = v_round.session_id;
  v_room := v_s.room_id;
  if not public.is_room_member(v_room) and not public.is_admin() then
    -- also allow the service role (Edge Function cron) which has no auth.uid()
    if auth.uid() is not null then raise exception 'NOT_A_MEMBER'; end if;
  end if;

  select count(*) into v_alive from public.room_players
   where room_id = v_room and left_at is null and not is_spectator and is_alive;

  v_stage := coalesce(v_round.prompt ->> 'stage', 'answer');

  -- Early resolution is allowed only when everyone who *can* act has acted.
  if now() < v_round.ends_at then
    if v_stage in ('answer','describe','write') then
      select count(*) into v_submitted from public.answers where round_id = p_round;
    elsif v_stage in ('vote','day') then
      select count(distinct voter_id) into v_submitted from public.votes where round_id = p_round;
    elsif v_stage = 'night' then
      select count(*) into v_submitted from public.mafia_actions where round_id = p_round;
      select count(*) into v_alive from public.mafia_roles
       where session_id = v_s.id and is_alive and role <> 'citizen';
    else
      v_submitted := 0;
    end if;
    if v_submitted < v_alive then
      return jsonb_build_object('pending', true, 'ends_at', v_round.ends_at);
    end if;
  end if;

  -- =========================================================
  -- جماد حيوان نبات  /  Animal-Plant-Object
  -- =========================================================
  if v_s.game_key = 'animal_plant_object' then
    v_letter := v_round.prompt ->> 'letter';
    select array_agg(value::text) into v_cats
      from jsonb_array_elements_text(v_round.prompt -> 'categories') as t(value);

    v_dups := '{}'::jsonb;
    foreach v_cat in array v_cats loop
      -- count normalised duplicates per category
      v_dups := v_dups || jsonb_build_object(v_cat, coalesce((
        select jsonb_object_agg(n, c) from (
          select public.normalize_ar(a.payload ->> v_cat) as n, count(*) as c
            from public.answers a
           where a.round_id = p_round and coalesce(a.payload ->> v_cat,'') <> ''
           group by 1
        ) d), '{}'::jsonb));
    end loop;

    for v_ans in select * from public.answers where round_id = p_round loop
      v_pts := 0;
      foreach v_cat in array v_cats loop
        v_val  := coalesce(v_ans.payload ->> v_cat, '');
        v_norm := public.normalize_ar(v_val);
        if v_norm <> '' and left(v_norm, 1) = public.normalize_ar(v_letter) then
          if coalesce(((v_dups -> v_cat) ->> v_norm)::int, 1) > 1 then
            v_pts := v_pts + 5;
          else
            v_pts := v_pts + 10;
          end if;
        end if;
      end loop;
      perform public._award(p_round, v_ans.user_id, v_pts);
    end loop;

    -- optional speed bonus for the first valid submission
    if coalesce((v_s.config ->> 'speed_bonus')::boolean, true) then
      perform public._award(p_round, (
        select user_id from public.answers where round_id = p_round
         order by elapsed_ms asc nulls last limit 1), 5);
    end if;

    select jsonb_build_object('stage','scored','letter', v_letter,
             'answers', coalesce(jsonb_agg(jsonb_build_object(
               'user_id', a.user_id, 'nickname', p.nickname,
               'payload', a.payload, 'points', a.points) order by a.points desc), '[]'::jsonb))
      into v_result
      from public.answers a join public.profiles p on p.id = a.user_id
     where a.round_id = p_round;

  -- =========================================================
  -- صح/خطأ، خمن الكلمة، الأمثال، من أنا  (single correct answer)
  -- =========================================================
  elsif v_s.game_key in ('true_false','guess_word','proverbs','who_am_i') then
    v_fuzzy := v_s.game_key in ('proverbs','who_am_i','guess_word');
    v_rank := 0;
    for v_ans in
      select a.*, p.nickname from public.answers a join public.profiles p on p.id = a.user_id
       where a.round_id = p_round order by a.elapsed_ms asc nulls last
    loop
      v_correct := public.answer_matches(
        v_ans.payload ->> 'value',
        v_round.secret_data ->> 'answer',
        (select array_agg(x) from jsonb_array_elements_text(coalesce(v_round.secret_data -> 'alt','[]'::jsonb)) t(x)),
        v_fuzzy);
      if v_correct then
        v_rank := v_rank + 1;
        v_pts := 10 + case v_rank when 1 then 5 when 2 then 3 when 3 then 1 else 0 end;
      else
        v_pts := 0;
      end if;
      perform public._award(p_round, v_ans.user_id, v_pts);
      update public.answers set payload = payload || jsonb_build_object('correct', v_correct)
       where id = v_ans.id;
    end loop;

    select jsonb_build_object('stage','scored',
             'correct_answer', v_round.secret_data ->> 'answer',
             'answers', coalesce(jsonb_agg(jsonb_build_object(
               'user_id', a.user_id, 'nickname', p.nickname,
               'value', a.payload ->> 'value',
               'correct', coalesce((a.payload ->> 'correct')::boolean,false),
               'points', a.points) order by a.points desc), '[]'::jsonb))
      into v_result
      from public.answers a join public.profiles p on p.id = a.user_id
     where a.round_id = p_round;

  -- =========================================================
  -- الكذاب بيننا  /  The liar among us  (2 stages)
  -- =========================================================
  elsif v_s.game_key = 'liar' then
    if v_stage = 'describe' then
      update public.rounds
         set prompt = prompt || jsonb_build_object('stage','vote',
                        'descriptions', coalesce((
                          select jsonb_agg(jsonb_build_object(
                                   'user_id', a.user_id, 'nickname', p.nickname,
                                   'text', a.payload ->> 'value'))
                            from public.answers a join public.profiles p on p.id = a.user_id
                           where a.round_id = p_round), '[]'::jsonb)),
             ends_at = now() + interval '60 seconds'
       where id = p_round;
      perform public.touch_room(v_room);
      return jsonb_build_object('stage','vote','advanced', true);
    end if;

    v_liar := (v_round.secret_data ->> 'liar')::uuid;
    select target_user, count(*) into v_accused, v_top from public.votes
     where round_id = p_round and kind = 'liar'
     group by target_user order by count(*) desc limit 1;

    for v_ans in select voter_id, target_user from public.votes where round_id = p_round and kind = 'liar' loop
      if v_ans.target_user = v_liar then perform public._award(p_round, v_ans.voter_id, 10); end if;
    end loop;
    if v_accused is distinct from v_liar then
      perform public._award(p_round, v_liar, 20);
    end if;

    v_result := jsonb_build_object('stage','scored',
      'liar', v_liar, 'word', v_round.secret_data ->> 'word',
      'accused', v_accused, 'caught', (v_accused is not distinct from v_liar));

  -- =========================================================
  -- القصة الجماعية  /  Group story  (write → vote)
  -- =========================================================
  elsif v_s.game_key = 'group_story' then
    if v_stage = 'write' then
      update public.rounds
         set prompt = prompt || jsonb_build_object('stage','vote',
                        'lines', coalesce((
                          select jsonb_agg(jsonb_build_object(
                                   'user_id', a.user_id, 'nickname', p.nickname,
                                   'text', a.payload ->> 'value') order by a.created_at)
                            from public.answers a join public.profiles p on p.id = a.user_id
                           where a.round_id = p_round), '[]'::jsonb)),
             ends_at = now() + interval '45 seconds'
       where id = p_round;
      perform public.touch_room(v_room);
      return jsonb_build_object('stage','vote','advanced', true);
    end if;

    for v_ans in select a.user_id, count(v.id) as votes
                   from public.answers a
                   left join public.votes v on v.round_id = p_round
                        and v.kind = 'story_line' and v.target_user = a.user_id
                  where a.round_id = p_round group by a.user_id
    loop
      perform public._award(p_round, v_ans.user_id, 5 + (v_ans.votes * 5)::int);
    end loop;

    select jsonb_build_object('stage','scored','lines', v_round.prompt -> 'lines',
             'best', (select v.target_user from public.votes v
                       where v.round_id = p_round and v.kind = 'story_line'
                       group by v.target_user order by count(*) desc limit 1))
      into v_result;

  -- =========================================================
  -- المافيا  /  Mafia
  -- =========================================================
  elsif v_s.game_key = 'mafia' then
    if v_round.phase = 'night' then
      -- mafia pick by internal majority; ties broken randomly
      select target_id into v_killed from public.mafia_actions
       where round_id = p_round and action = 'kill'
       group by target_id order by count(*) desc, random() limit 1;

      if v_killed is not null then
        v_saved := exists (select 1 from public.mafia_actions
                            where round_id = p_round and action in ('heal','protect')
                              and target_id = v_killed);
        if not v_saved then
          update public.mafia_roles set is_alive = false, died_round = v_round.round_index
           where session_id = v_s.id and user_id = v_killed;
          update public.room_players set is_alive = false, state = 'dead'
           where room_id = v_room and user_id = v_killed;
        end if;
      end if;

      v_result := jsonb_build_object(
        'stage','night_result',
        'killed', case when v_killed is not null and not v_saved then v_killed else null end,
        'killed_nickname', case when v_killed is not null and not v_saved
                                then (select nickname from public.profiles where id = v_killed) end,
        'saved', v_saved);
    else
      -- day: lynch by plurality; a tie means nobody is lynched
      select target_user, count(*) into v_lynched, v_top from public.votes
       where round_id = p_round and kind = 'lynch' and target_user is not null
       group by target_user order by count(*) desc limit 1;

      if v_lynched is not null and (
           select count(*) from (
             select count(*) c from public.votes
              where round_id = p_round and kind = 'lynch' and target_user is not null
              group by target_user having count(*) = v_top) t) > 1 then
        v_lynched := null; -- tie
      end if;

      if v_lynched is not null then
        update public.mafia_roles set is_alive = false, died_round = v_round.round_index, revealed = true
         where session_id = v_s.id and user_id = v_lynched;
        update public.room_players set is_alive = false, state = 'dead'
         where room_id = v_room and user_id = v_lynched;
      end if;

      v_result := jsonb_build_object(
        'stage','day_result', 'lynched', v_lynched,
        'lynched_nickname', (select nickname from public.profiles where id = v_lynched),
        'lynched_role', (select role from public.mafia_roles
                          where session_id = v_s.id and user_id = v_lynched),
        'votes', coalesce((select jsonb_agg(jsonb_build_object('target', target_user, 'count', c))
                             from (select target_user, count(*) c from public.votes
                                    where round_id = p_round and kind = 'lynch'
                                    group by target_user) t), '[]'::jsonb));
    end if;

    -- survival points
    update public.room_players set score = score + 5
     where room_id = v_room and is_alive and not is_spectator and left_at is null;
  end if;

  -- ---------- close the round -------------------------------
  update public.rounds
     set resolved_at = now(), phase = 'revealed', result = v_result
   where id = p_round;
  perform public.touch_room(v_room);

  -- ---------- advance the session ----------------------------
  if v_s.game_key = 'mafia' then
    v_winner := public._mafia_check_win(v_s.id);
    if v_winner is not null then
      update public.mafia_roles set revealed = true where session_id = v_s.id;
      v_result := v_result || jsonb_build_object('game_over', true, 'winning_side', v_winner,
        'final', public._finish_session(v_s.id,
          (select array_agg(user_id) from public.mafia_roles
            where session_id = v_s.id and ((v_winner = 'mafia' and role = 'mafia')
                                        or (v_winner = 'citizens' and role <> 'mafia'))),
          'mafia_' || v_winner));
    else
      perform public._begin_round(v_s.id, v_round.round_index + 1);
    end if;
  else
    if v_round.round_index >= v_s.total_rounds then
      v_result := v_result || jsonb_build_object('game_over', true,
        'final', public._finish_session(v_s.id, null, 'rounds_complete'));
    else
      perform public._begin_round(v_s.id, v_round.round_index + 1);
    end if;
  end if;

  update public.rounds set result = v_result where id = p_round;
  return v_result;
end $$;

-- ---------- abort / play again -----------------------------------
create or replace function public.abort_game(p_room uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v_s uuid;
begin
  if not public.is_room_host(p_room) and not public.is_admin() then raise exception 'NOT_HOST'; end if;
  select id into v_s from public.game_sessions
   where room_id = p_room and status in ('pending','running') limit 1;
  if v_s is not null then
    update public.game_sessions set status = 'aborted', ended_at = now() where id = v_s;
  end if;
  update public.rooms set status = 'waiting' where id = p_room;
  update public.room_players set is_ready = false, is_alive = true, state = 'connected', score = 0
   where room_id = p_room and left_at is null;
  insert into public.messages (room_id, is_system, body) values (p_room, true, 'تم إيقاف المباراة');
end $$;

create or replace function public.play_again(p_room uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_room_host(p_room) then raise exception 'NOT_HOST'; end if;
  update public.rooms set status = 'waiting' where id = p_room;
  update public.room_players
     set is_ready = false, is_alive = true, state = 'connected', score = 0
   where room_id = p_room and left_at is null;
  perform public.touch_room(p_room);
end $$;

-- ---------- my secret mafia role (own row only) --------------------
create or replace function public.my_mafia_role(p_room uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_s uuid; v_r record;
begin
  select id into v_s from public.game_sessions
   where room_id = p_room and status = 'running' order by started_at desc limit 1;
  if v_s is null then return null; end if;
  select role, is_alive into v_r from public.mafia_roles
   where session_id = v_s and user_id = auth.uid();
  if not found then return null; end if;
  return jsonb_build_object('role', v_r.role, 'is_alive', v_r.is_alive,
    'partners', case when v_r.role = 'mafia' then coalesce((
        select jsonb_agg(jsonb_build_object('user_id', m.user_id, 'nickname', p.nickname))
          from public.mafia_roles m join public.profiles p on p.id = m.user_id
         where m.session_id = v_s and m.role = 'mafia' and m.user_id <> auth.uid()), '[]'::jsonb)
      else '[]'::jsonb end);
end $$;

-- ---------- per-player secret for the current round -------------------
-- Some games hand each player a DIFFERENT private value (the liar's decoy
-- word, a "Who am I?" assignment). It lives in rounds.secret_data, which is
-- unreadable by clients; this function returns only the caller's slice.
create or replace function public.my_round_secret(p_round uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_round public.rounds;
  v_room  uuid;
begin
  select * into v_round from public.rounds where id = p_round;
  if not found then return null; end if;
  v_room := public.round_room(p_round);
  if not public.is_room_member(v_room) then raise exception 'NOT_A_MEMBER'; end if;

  if v_round.secret_data ? 'assignments' then
    return jsonb_build_object(
      'word', (v_round.secret_data -> 'assignments') ->> auth.uid()::text);
  end if;
  return '{}'::jsonb;
end $$;


-- ─────────────────────────────────────────────────────────
-- supabase/migrations/20240101000010_rls.sql
-- ─────────────────────────────────────────────────────────
-- ============================================================
-- لمّتنا / Lametna — 0010 Row Level Security
-- Default stance: everything denied, reads scoped to room
-- membership, all sensitive writes go through SECURITY DEFINER
-- RPCs only.
-- ============================================================

alter table public.profiles          enable row level security;
alter table public.guest_sessions    enable row level security;
alter table public.avatars           enable row level security;
alter table public.countries         enable row level security;
alter table public.games             enable row level security;
alter table public.achievements      enable row level security;
alter table public.user_achievements enable row level security;
alter table public.rooms             enable row level security;
alter table public.room_players      enable row level security;
alter table public.messages          enable row level security;
alter table public.game_sessions     enable row level security;
alter table public.rounds            enable row level security;
alter table public.questions         enable row level security;
alter table public.answers           enable row level security;
alter table public.votes             enable row level security;
alter table public.mafia_roles       enable row level security;
alter table public.mafia_actions     enable row level security;
alter table public.scores            enable row level security;
alter table public.reports           enable row level security;
alter table public.bans              enable row level security;
alter table public.user_blocks       enable row level security;
alter table public.notifications     enable row level security;
alter table public.audit_logs        enable row level security;
alter table public.banned_words      enable row level security;

-- ---------- column-level hardening ---------------------------
-- Even a permissive row policy must never expose these columns.
revoke select (password_hash) on public.rooms  from anon, authenticated;
revoke select (secret_data)   on public.rounds from anon, authenticated;
revoke select (answer, alt_answers) on public.questions from anon, authenticated;

-- ---------- public reference data -----------------------------
drop policy if exists countries_read on public.countries;
create policy countries_read on public.countries for select using (true);

drop policy if exists avatars_read on public.avatars;
create policy avatars_read on public.avatars for select using (true);

drop policy if exists games_read on public.games;
create policy games_read on public.games for select using (is_active or public.is_admin());

drop policy if exists achievements_read on public.achievements;
create policy achievements_read on public.achievements for select using (true);

drop policy if exists banned_words_admin on public.banned_words;
create policy banned_words_admin on public.banned_words for all
  using (public.is_admin()) with check (public.is_admin());

-- questions: body is readable (needed for the admin panel + offline packs),
-- answers are stripped by the column grant above.
drop policy if exists questions_read on public.questions;
create policy questions_read on public.questions for select using (is_active or public.is_admin());
drop policy if exists questions_admin_write on public.questions;
create policy questions_admin_write on public.questions for all
  using (public.is_admin()) with check (public.is_admin());

-- ---------- profiles -------------------------------------------
drop policy if exists profiles_read on public.profiles;
create policy profiles_read on public.profiles for select
  using (deleted_at is null or id = auth.uid() or public.is_admin());

drop policy if exists profiles_self_update on public.profiles;
create policy profiles_self_update on public.profiles for update
  using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists profiles_admin_update on public.profiles;
create policy profiles_admin_update on public.profiles for update
  using (public.is_admin()) with check (public.is_admin());

-- Points, level, role and match counters are server-owned.
create or replace function public.tg_protect_profile_stats()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if public.is_admin() then return new; end if;
  new.total_points := old.total_points;
  new.games_played := old.games_played;
  new.games_won    := old.games_won;
  new.win_streak   := old.win_streak;
  new.best_streak  := old.best_streak;
  new.role         := old.role;
  new.is_guest     := old.is_guest;
  return new;
end $$;
drop trigger if exists profiles_protect_stats on public.profiles;
create trigger profiles_protect_stats before update on public.profiles
  for each row execute function public.tg_protect_profile_stats();

drop policy if exists guest_sessions_self on public.guest_sessions;
create policy guest_sessions_self on public.guest_sessions for select using (user_id = auth.uid());

drop policy if exists user_achievements_read on public.user_achievements;
create policy user_achievements_read on public.user_achievements for select using (true);

-- ---------- rooms ------------------------------------------------
drop policy if exists rooms_read on public.rooms;
create policy rooms_read on public.rooms for select using (
  (is_public and closed_at is null)
  or public.is_room_member(id)
  or host_id = auth.uid()
  or public.is_admin()
);
-- No direct INSERT/UPDATE/DELETE policies: use create_room / join_room / … RPCs.
drop policy if exists rooms_admin_write on public.rooms;
create policy rooms_admin_write on public.rooms for update
  using (public.is_admin()) with check (public.is_admin());

drop policy if exists room_players_read on public.room_players;
create policy room_players_read on public.room_players for select using (
  public.is_room_member(room_id) or user_id = auth.uid() or public.is_admin()
  or exists (select 1 from public.rooms r where r.id = room_id and r.is_public)
);

drop policy if exists messages_read on public.messages;
create policy messages_read on public.messages for select using (
  not is_hidden
  and public.is_room_member(room_id)
  and (
    channel = 'public'
    or (channel = 'mafia' and exists (
        select 1 from public.mafia_roles mr join public.game_sessions gs on gs.id = mr.session_id
         where gs.room_id = messages.room_id and mr.user_id = auth.uid() and mr.role = 'mafia'))
    or (channel = 'dead' and not coalesce((select rp.is_alive from public.room_players rp
          where rp.room_id = messages.room_id and rp.user_id = auth.uid()), true))
  )
  and not exists (select 1 from public.user_blocks ub
                   where ub.blocker_id = auth.uid() and ub.blocked_id = messages.user_id)
);
drop policy if exists messages_admin on public.messages;
create policy messages_admin on public.messages for all
  using (public.is_admin()) with check (public.is_admin());

-- ---------- gameplay ------------------------------------------------
drop policy if exists sessions_read on public.game_sessions;
create policy sessions_read on public.game_sessions for select
  using (public.is_room_member(room_id) or public.is_admin());

drop policy if exists rounds_read on public.rounds;
create policy rounds_read on public.rounds for select
  using (public.is_room_member(public.session_room(session_id)) or public.is_admin());

drop policy if exists answers_read on public.answers;
create policy answers_read on public.answers for select using (
  user_id = auth.uid()
  or public.is_admin()
  -- other players' answers become visible only once the round is resolved
  or exists (select 1 from public.rounds r
              where r.id = answers.round_id and r.resolved_at is not null
                and public.is_room_member(public.session_room(r.session_id)))
  -- …or during the voting stage of liar / group_story, where they are the ballot
  or exists (select 1 from public.rounds r
              where r.id = answers.round_id and (r.prompt ->> 'stage') = 'vote'
                and public.is_room_member(public.session_room(r.session_id)))
);

drop policy if exists votes_read on public.votes;
create policy votes_read on public.votes for select using (
  voter_id = auth.uid()
  or public.is_admin()
  or exists (select 1 from public.rounds r
              where r.id = votes.round_id and r.resolved_at is not null
                and public.is_room_member(public.session_room(r.session_id)))
);

-- MAFIA SECRECY: a player can read ONLY their own role until the session ends.
drop policy if exists mafia_roles_read on public.mafia_roles;
create policy mafia_roles_read on public.mafia_roles for select using (
  user_id = auth.uid()
  or public.is_admin()
  or (revealed and exists (select 1 from public.game_sessions gs
                            where gs.id = mafia_roles.session_id and gs.status = 'finished'))
);

drop policy if exists mafia_actions_read on public.mafia_actions;
create policy mafia_actions_read on public.mafia_actions for select using (
  actor_id = auth.uid()
  or public.is_admin()
  or exists (select 1 from public.rounds r join public.game_sessions gs on gs.id = r.session_id
              where r.id = mafia_actions.round_id and gs.status = 'finished')
);

drop policy if exists scores_read on public.scores;
create policy scores_read on public.scores for select using (true);

-- ---------- moderation ------------------------------------------------
drop policy if exists reports_own on public.reports;
create policy reports_own on public.reports for select
  using (reporter_id = auth.uid() or public.is_admin());
drop policy if exists reports_admin_update on public.reports;
create policy reports_admin_update on public.reports for update
  using (public.is_admin()) with check (public.is_admin());

drop policy if exists bans_read on public.bans;
create policy bans_read on public.bans for select
  using (user_id = auth.uid() or public.is_admin()
         or (room_id is not null and public.is_room_host(room_id)));
drop policy if exists bans_admin on public.bans;
create policy bans_admin on public.bans for all
  using (public.is_admin()) with check (public.is_admin());

drop policy if exists blocks_own on public.user_blocks;
create policy blocks_own on public.user_blocks for all
  using (blocker_id = auth.uid()) with check (blocker_id = auth.uid());

drop policy if exists notifications_own on public.notifications;
create policy notifications_own on public.notifications for select using (user_id = auth.uid());
drop policy if exists notifications_own_update on public.notifications;
create policy notifications_own_update on public.notifications for update
  using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists audit_admin on public.audit_logs;
create policy audit_admin on public.audit_logs for select using (public.is_admin());

-- ---------- grants -------------------------------------------------------
-- No table-level INSERT/UPDATE/DELETE for clients on gameplay tables.
revoke insert, update, delete on
  public.rooms, public.room_players, public.messages, public.game_sessions,
  public.rounds, public.answers, public.votes, public.mafia_roles,
  public.mafia_actions, public.scores, public.bans, public.audit_logs,
  public.user_achievements, public.guest_sessions
from anon, authenticated;

grant execute on function
  public.create_room(text, boolean, text, text, int, jsonb, text),
  public.join_room(text, text, boolean),
  public.leave_room(uuid),
  public.heartbeat(uuid),
  public.set_ready(uuid, boolean),
  public.transfer_host(uuid, uuid),
  public.kick_player(uuid, uuid),
  public.ban_player(uuid, uuid, text),
  public.mute_player(uuid, uuid, boolean),
  public.block_user(uuid, boolean),
  public.send_message(uuid, text, text),
  public.report_user(uuid, text, uuid, bigint, text),
  public.list_public_rooms(text, int),
  public.start_game(uuid, int, jsonb),
  public.submit_answer(uuid, jsonb),
  public.cast_vote(uuid, vote_kind, uuid, text, boolean),
  public.submit_mafia_action(uuid, mafia_action_kind, uuid),
  public.resolve_round(uuid),
  public.abort_game(uuid),
  public.play_again(uuid),
  public.my_mafia_role(uuid),
  public.my_round_secret(uuid)
to authenticated;

-- internal helpers are NOT callable from the client
revoke execute on function
  public._begin_round(uuid, int),
  public._award(uuid, uuid, int),
  public._finish_session(uuid, uuid[], text),
  public._grant_achievement(uuid, text),
  public._evaluate_achievements(uuid, text, boolean),
  public._mafia_check_win(uuid),
  public.cleanup_stale_rooms()
from anon, authenticated;


-- ─────────────────────────────────────────────────────────
-- supabase/migrations/20240101000011_leaderboards_realtime.sql
-- ─────────────────────────────────────────────────────────
-- ============================================================
-- لمّتنا / Lametna — 0011 Leaderboards + Realtime publication
-- ============================================================

-- ---------- leaderboard ---------------------------------------
-- scope : 'global' | 'arab' | 'yemen'
-- period: 'week'   | 'month' | 'all'
create or replace function public.leaderboard(
  p_scope text default 'global',
  p_period text default 'all',
  p_game_key text default null,
  p_limit int default 50
) returns table (
  rank bigint, user_id uuid, nickname text, avatar_key text,
  country_code text, points bigint, wins bigint, games bigint, level int
) language sql stable security definer set search_path = public as $$
  with since as (
    select case p_period
             when 'week'  then now() - interval '7 days'
             when 'month' then now() - interval '30 days'
             else '-infinity'::timestamptz end as ts
  ),
  agg as (
    select s.user_id,
           sum(s.points)::bigint as points,
           count(*) filter (where s.is_win)::bigint as wins,
           count(*)::bigint as games
      from public.scores s, since
     where s.created_at >= since.ts
       and (p_game_key is null or s.game_key = p_game_key)
     group by s.user_id
  )
  select row_number() over (order by a.points desc, a.wins desc) as rank,
         p.id, p.nickname, p.avatar_key,
         case when p.show_country then p.country_code else null end,
         a.points, a.wins, a.games, p.level
    from agg a
    join public.profiles p on p.id = a.user_id
   where p.deleted_at is null
     and case p_scope
           when 'yemen' then p.show_country and p.country_code = 'YE'
           when 'arab'  then p.show_country and p.country_code in
                (select code from public.countries where region = 'arab')
           else true
         end
   order by a.points desc, a.wins desc
   limit greatest(1, least(coalesce(p_limit,50), 100));
$$;

create or replace function public.my_rank(p_scope text default 'global', p_period text default 'all')
returns jsonb language sql stable security definer set search_path = public as $$
  select coalesce((
    select to_jsonb(l) from public.leaderboard(p_scope, p_period, null, 100) l
     where l.user_id = auth.uid() limit 1), '{}'::jsonb);
$$;

grant execute on function public.leaderboard(text, text, text, int) to authenticated, anon;
grant execute on function public.my_rank(text, text) to authenticated;

-- ---------- admin statistics ------------------------------------
create or replace function public.admin_stats()
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  return jsonb_build_object(
    'users_total',      (select count(*) from public.profiles where deleted_at is null),
    'users_guests',     (select count(*) from public.profiles where is_guest and deleted_at is null),
    'users_new_7d',     (select count(*) from public.profiles where created_at > now() - interval '7 days'),
    'rooms_open',       (select count(*) from public.rooms where closed_at is null),
    'rooms_playing',    (select count(*) from public.rooms where status = 'playing'),
    'sessions_24h',     (select count(*) from public.game_sessions where started_at > now() - interval '24 hours'),
    'messages_24h',     (select count(*) from public.messages where created_at > now() - interval '24 hours'),
    'reports_open',     (select count(*) from public.reports where status = 'open'),
    'bans_global',      (select count(*) from public.bans where scope = 'global'),
    'questions_total',  (select count(*) from public.questions where is_active),
    'top_games',        (select coalesce(jsonb_agg(t), '[]'::jsonb) from
                          (select game_key, count(*) as plays from public.game_sessions
                            where started_at > now() - interval '30 days'
                            group by game_key order by plays desc limit 10) t)
  );
end $$;
grant execute on function public.admin_stats() to authenticated;

create or replace function public.admin_resolve_report(p_report bigint, p_status report_status, p_ban_days int default null)
returns void language plpgsql security definer set search_path = public as $$
declare v_r public.reports;
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  select * into v_r from public.reports where id = p_report;
  if not found then raise exception 'NOT_FOUND'; end if;
  update public.reports set status = p_status, handled_by = auth.uid(), handled_at = now()
   where id = p_report;
  if p_ban_days is not null then
    insert into public.bans (user_id, scope, reason, created_by, expires_at)
    values (v_r.reported_id, 'global', 'report#' || p_report,
            auth.uid(), case when p_ban_days = 0 then null else now() + make_interval(days => p_ban_days) end);
  end if;
  perform public.log_audit('report.resolve','report', p_report::text,
                           jsonb_build_object('status', p_status, 'ban_days', p_ban_days));
end $$;
grant execute on function public.admin_resolve_report(bigint, report_status, int) to authenticated;

-- ---------- Realtime publication ----------------------------------
-- Realtime respects RLS, so subscribers only receive rows they may read.
do $$
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    create publication supabase_realtime;
  end if;
end $$;

alter publication supabase_realtime add table public.rooms;
alter publication supabase_realtime add table public.room_players;
alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.game_sessions;
alter publication supabase_realtime add table public.rounds;
alter publication supabase_realtime add table public.answers;
alter publication supabase_realtime add table public.votes;
alter publication supabase_realtime add table public.notifications;

-- REPLICA IDENTITY FULL lets clients diff old/new rows on UPDATE.
alter table public.room_players replica identity full;
alter table public.rooms        replica identity full;
alter table public.rounds       replica identity full;

-- ---------- account deletion (GDPR-style) ----------------------------
create or replace function public.delete_my_account()
returns void language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception 'AUTH_REQUIRED'; end if;
  perform public.leave_room(rp.room_id) from public.room_players rp
    where rp.user_id = v_uid and rp.left_at is null;
  update public.profiles
     set deleted_at = now(),
         nickname = 'حساب-محذوف-' || substr(replace(v_uid::text,'-',''),1,6),
         avatar_key = null, country_code = null, show_country = false
   where id = v_uid;
  update public.messages set is_hidden = true, body = '[محذوف]' where user_id = v_uid;
  perform public.log_audit('account.delete','profile', v_uid::text, '{}'::jsonb);
end $$;
grant execute on function public.delete_my_account() to authenticated;

-- ---------- authoritative clock for clients ---------------------------
-- Devices must never trust their own clock for round timers. They call
-- this once on connect (and on reconnect) and keep a local offset.
create or replace function public.server_now()
returns timestamptz language sql stable as $$ select now() $$;
grant execute on function public.server_now() to anon, authenticated;


-- ─────────────────────────────────────────────────────────
-- supabase/seed.sql  (بيانات أولية: الألعاب، الدول، الأفاتارات)
-- ─────────────────────────────────────────────────────────
-- ============================================================
-- لمّتنا / Lametna — Seed data
-- Idempotent: safe to re-run (`supabase db reset` or psql -f).
-- ============================================================

-- ---------- avatars (bundled in assets/avatars/) --------------
insert into public.avatars (key, name_ar, name_en, sort_order) values
  ('coffee',  'قهوة',    'Coffee',  1),
  ('lion',    'أسد',     'Lion',    2),
  ('falcon',  'صقر',     'Falcon',  3),
  ('camel',   'جمل',     'Camel',   4),
  ('star',    'نجمة',    'Star',    5),
  ('moon',    'قمر',     'Moon',    6),
  ('palm',    'نخلة',    'Palm',    7),
  ('jambiya', 'جنبية',   'Jambiya', 8),
  ('lantern', 'فانوس',   'Lantern', 9),
  ('mountain','جبل',     'Mountain',10),
  ('sea',     'بحر',     'Sea',     11),
  ('book',    'كتاب',    'Book',    12)
on conflict (key) do update set name_ar = excluded.name_ar, name_en = excluded.name_en;

-- ---------- countries -----------------------------------------
insert into public.countries (code, name_ar, name_en, flag_emoji, region) values
  ('YE','اليمن','Yemen','🇾🇪','arab'),
  ('SA','السعودية','Saudi Arabia','🇸🇦','arab'),
  ('AE','الإمارات','UAE','🇦🇪','arab'),
  ('EG','مصر','Egypt','🇪🇬','arab'),
  ('OM','عُمان','Oman','🇴🇲','arab'),
  ('QA','قطر','Qatar','🇶🇦','arab'),
  ('KW','الكويت','Kuwait','🇰🇼','arab'),
  ('BH','البحرين','Bahrain','🇧🇭','arab'),
  ('JO','الأردن','Jordan','🇯🇴','arab'),
  ('SY','سوريا','Syria','🇸🇾','arab'),
  ('LB','لبنان','Lebanon','🇱🇧','arab'),
  ('IQ','العراق','Iraq','🇮🇶','arab'),
  ('PS','فلسطين','Palestine','🇵🇸','arab'),
  ('SD','السودان','Sudan','🇸🇩','arab'),
  ('LY','ليبيا','Libya','🇱🇾','arab'),
  ('TN','تونس','Tunisia','🇹🇳','arab'),
  ('DZ','الجزائر','Algeria','🇩🇿','arab'),
  ('MA','المغرب','Morocco','🇲🇦','arab'),
  ('MR','موريتانيا','Mauritania','🇲🇷','arab'),
  ('SO','الصومال','Somalia','🇸🇴','arab'),
  ('DJ','جيبوتي','Djibouti','🇩🇯','arab'),
  ('KM','جزر القمر','Comoros','🇰🇲','arab'),
  ('TR','تركيا','Turkey','🇹🇷','other'),
  ('MY','ماليزيا','Malaysia','🇲🇾','other'),
  ('ID','إندونيسيا','Indonesia','🇮🇩','other'),
  ('IN','الهند','India','🇮🇳','other'),
  ('PK','باكستان','Pakistan','🇵🇰','other'),
  ('GB','بريطانيا','United Kingdom','🇬🇧','other'),
  ('US','أمريكا','United States','🇺🇸','other'),
  ('DE','ألمانيا','Germany','🇩🇪','other'),
  ('FR','فرنسا','France','🇫🇷','other'),
  ('CA','كندا','Canada','🇨🇦','other'),
  ('AU','أستراليا','Australia','🇦🇺','other'),
  ('ZZ','دولة أخرى','Other','🌍','other')
on conflict (code) do update set name_ar = excluded.name_ar;

-- ---------- games ------------------------------------------------
insert into public.games (key, name_ar, name_en, description_ar, description_en, icon,
                          categories, min_players, max_players, default_rounds, round_seconds, sort_order) values
  ('animal_plant_object','جماد حيوان نبات','Categories',
   'حرف عشوائي وفئات متعددة — اكتب بسرعة قبل انتهاء الوقت.',
   'A random letter and multiple categories — write fast before the timer ends.',
   '✍️', '{arabic,family,fast,competitive}', 2, 12, 5, 90, 1),

  ('mafia','المافيا','Mafia',
   'ليل ونهار، أدوار سرية، نقاش وتصويت. من المافيا بيننا؟',
   'Night and day, secret roles, discussion and voting. Who is the mafia?',
   '🕵️', '{global,competitive}', 5, 16, 40, 120, 2),

  ('who_am_i','من أنا؟','Who Am I?',
   'شخصية سرية وأسئلة بنعم أو لا حتى تصل إلى التخمين الصحيح.',
   'A secret character and yes/no questions until you guess right.',
   '❓', '{arabic,global,family}', 3, 10, 5, 120, 3),

  ('true_false','صح أم خطأ','True or False',
   'معلومات عربية ويمنية وعالمية — أجب بسرعة واكسب نقاطًا.',
   'Arab, Yemeni and world facts — answer fast and score.',
   '✅', '{global,fast,family}', 2, 16, 8, 25, 4),

  ('guess_word','خمن الكلمة','Guess the Word',
   'تلميحات تظهر تدريجيًا، وكلما أسرعت زادت نقاطك.',
   'Hints reveal progressively — the faster you are, the more points you get.',
   '🔤', '{arabic,fast,competitive}', 2, 12, 6, 60, 5),

  ('liar','الكذاب بيننا','The Liar',
   'الجميع يعرف الكلمة إلا واحدًا. صِف الكلمة دون كشفها، ثم صوّتوا.',
   'Everyone knows the word except one. Describe it without revealing it, then vote.',
   '🎭', '{arabic,competitive}', 4, 12, 4, 60, 6),

  ('proverbs','أكمل المثل','Finish the Proverb',
   'أمثال عربية ويمنية — أكمل المثل، ونقبل أكثر من رواية.',
   'Arab and Yemeni proverbs — complete them; several variants are accepted.',
   '📜', '{yemeni,arabic,family}', 2, 12, 8, 40, 7),

  ('group_story','القصة الجماعية','Group Story',
   'كل لاعب يضيف جملة، ثم تصوّتون على أجمل جملة.',
   'Each player adds a sentence, then you vote for the best one.',
   '📖', '{family,arabic}', 3, 10, 4, 90, 8)
on conflict (key) do update set
  name_ar = excluded.name_ar, name_en = excluded.name_en,
  description_ar = excluded.description_ar, description_en = excluded.description_en,
  categories = excluded.categories, min_players = excluded.min_players,
  max_players = excluded.max_players, round_seconds = excluded.round_seconds;

-- ---------- achievements ------------------------------------------
insert into public.achievements (key, name_ar, name_en, description_ar, description_en, icon, points) values
  ('first_win','أول انتصار','First Win','فزت بأول مباراة لك','Won your first match','🥇',50),
  ('mafia_king','ملك المافيا','Mafia King','فزت 3 مرات في المافيا','Won 3 mafia matches','🕶️',150),
  ('fast_answer','أسرع إجابة','Fastest Answer','كنت الأسرع في جولة','Fastest answer in a round','⚡',30),
  ('apo_expert','خبير جماد حيوان','Categories Expert','300 نقطة في جماد حيوان نبات','300 points in Categories','✍️',100),
  ('proverbs_champion','بطل الأمثال','Proverbs Champion','فزت 3 مرات في أكمل المثل','Won 3 proverb matches','📜',100),
  ('active_player','لاعب نشيط','Active Player','لعبت 20 مباراة','Played 20 matches','🔥',80),
  ('streak_master','فوز متتالي','Win Streak','3 انتصارات متتالية','3 wins in a row','🏆',120)
on conflict (key) do update set name_ar = excluded.name_ar;

-- ---------- moderation dictionary (extend from the admin panel) ------
insert into public.banned_words (word, severity, locale) values
  ('كلب',1,'ar'), ('حمار',1,'ar'), ('غبي',1,'ar'), ('حقير',2,'ar'),
  ('يلعن',2,'ar'), ('قذر',2,'ar'), ('خنزير',2,'ar'), ('تافه',1,'ar'),
  ('idiot',1,'en'), ('stupid',1,'en'), ('moron',2,'en')
on conflict (word) do nothing;

-- ============================================================
--  CONTENT BANK
-- ============================================================

-- ---------- صح أم خطأ / True-False ----------------------------
insert into public.questions (game_key, locale, region, difficulty, body, answer, choices) values
  ('true_false','ar','yemen',1,'صنعاء القديمة مدرجة في قائمة التراث العالمي لليونسكو.','صح','["صح","خطأ"]'),
  ('true_false','ar','yemen',1,'سقطرى جزيرة يمنية تشتهر بشجرة دم الأخوين.','صح','["صح","خطأ"]'),
  ('true_false','ar','yemen',2,'عدن عاصمة اليمن الحالية المعترف بها دستوريًا.','خطأ','["صح","خطأ"]'),
  ('true_false','ar','yemen',1,'السلطة والبنة من الأكلات اليمنية المشهورة.','صح','["صح","خطأ"]'),
  ('true_false','ar','yemen',2,'جبل النبي شعيب أعلى قمة في شبه الجزيرة العربية.','صح','["صح","خطأ"]'),
  ('true_false','ar','arab',1,'نهر النيل أطول نهر في أفريقيا.','صح','["صح","خطأ"]'),
  ('true_false','ar','arab',1,'الرياض عاصمة المملكة العربية السعودية.','صح','["صح","خطأ"]'),
  ('true_false','ar','arab',2,'مدينة البتراء تقع في لبنان.','خطأ','["صح","خطأ"]'),
  ('true_false','ar','arab',1,'اللغة العربية تُكتب من اليمين إلى اليسار.','صح','["صح","خطأ"]'),
  ('true_false','ar','global',1,'الشمس نجم.','صح','["صح","خطأ"]'),
  ('true_false','ar','global',1,'الماء يتجمد عند 100 درجة مئوية.','خطأ','["صح","خطأ"]'),
  ('true_false','ar','global',2,'كوكب المشتري أكبر كواكب المجموعة الشمسية.','صح','["صح","خطأ"]'),
  ('true_false','ar','global',2,'الحوت الأزرق أكبر حيوان على وجه الأرض.','صح','["صح","خطأ"]'),
  ('true_false','ar','global',3,'عدد عظام جسم الإنسان البالغ 206 عظمة.','صح','["صح","خطأ"]'),
  ('true_false','en','global',1,'The Sun is a star.','True','["True","False"]'),
  ('true_false','en','global',1,'Water freezes at 100 degrees Celsius.','False','["True","False"]'),
  ('true_false','en','yemen',1,'Socotra is a Yemeni island famous for the dragon blood tree.','True','["True","False"]'),
  ('true_false','en','global',2,'Jupiter is the largest planet in the Solar System.','True','["True","False"]')
on conflict do nothing;

-- ---------- أكمل المثل / Proverbs -------------------------------
insert into public.questions (game_key, locale, region, difficulty, body, answer, alt_answers) values
  ('proverbs','ar','arab',1,'الصديق وقت …','الضيق','{"الضيقة","وقت الضيق"}'),
  ('proverbs','ar','arab',1,'في التأني السلامة وفي العجلة …','الندامة','{"الندم"}'),
  ('proverbs','ar','arab',1,'من جدّ …','وجد','{"وجد ومن زرع حصد"}'),
  ('proverbs','ar','arab',2,'الطيور على أشكالها …','تقع','{}'),
  ('proverbs','ar','arab',1,'خير الكلام ما قلّ …','ودلّ','{"و دل","ودل"}'),
  ('proverbs','ar','arab',2,'رُبَّ أخٍ لك لم …','تلده أمك','{"تلده امك"}'),
  ('proverbs','ar','arab',2,'عصفور في اليد خير من عشرة على …','الشجرة','{"شجرة"}'),
  ('proverbs','ar','yemen',2,'اللي ما يعرف الصقر …','يشويه','{"يشويهـ","يشوية"}'),
  ('proverbs','ar','yemen',2,'من طلب العلا سهر …','الليالي','{"الليل"}'),
  ('proverbs','ar','yemen',3,'الجار قبل …','الدار','{}'),
  ('proverbs','ar','yemen',2,'ما كل ما يتمنى المرء …','يدركه','{"يدركهـ"}'),
  ('proverbs','ar','yemen',3,'اللي ما له أول ما له …','تالي','{"آخر","اخر"}'),
  ('proverbs','ar','arab',1,'الوقت من …','ذهب','{"الذهب"}'),
  ('proverbs','ar','arab',2,'إن كان الكلام من فضة فالسكوت من …','ذهب','{"الذهب"}')
on conflict do nothing;

-- ---------- خمن الكلمة / Guess the Word ---------------------------
insert into public.questions (game_key, locale, region, difficulty, body, answer, alt_answers, hints) values
  ('guess_word','ar','yemen',1,'خمّن الكلمة','صنعاء','{"صنعا"}','{"مدينة عربية","عاصمة تاريخية","مدينتها القديمة تراث عالمي","تشتهر بباب اليمن"}'),
  ('guess_word','ar','yemen',2,'خمّن الكلمة','سقطرى','{"سقطرا","سوقطرى"}','{"مكان في اليمن","جزيرة","بها نباتات نادرة","شجرة دم الأخوين"}'),
  ('guess_word','ar','yemen',1,'خمّن الكلمة','المندي','{"مندي"}','{"أكلة","تُطهى تحت الأرض","معها أرز","لحم أو دجاج"}'),
  ('guess_word','ar','arab',1,'خمّن الكلمة','القهوة','{"قهوة","البن"}','{"مشروب","لونه غامق","يمني الأصل","تشرب في الصباح"}'),
  ('guess_word','ar','arab',2,'خمّن الكلمة','الأهرامات','{"اهرامات","الاهرامات"}','{"معلم أثري","في مصر","مثلثة الشكل","من عجائب الدنيا"}'),
  ('guess_word','ar','global',2,'خمّن الكلمة','الإنترنت','{"انترنت","الانترنت"}','{"اختراع حديث","يربط العالم","يحتاج اتصالًا","تستخدمه الآن"}'),
  ('guess_word','ar','global',1,'خمّن الكلمة','الشمس','{"شمس"}','{"جرم سماوي","مصدر ضوء","نراها نهارًا","نجم"}'),
  ('guess_word','ar','arab',2,'خمّن الكلمة','الجنبية','{"جنبية"}','{"قطعة تراثية","تُلبس في الوسط","يمنية","خنجر"}'),
  ('guess_word','en','global',1,'Guess the word','coffee','{"café"}','{"a drink","dark colour","originally from Yemen","morning ritual"}'),
  ('guess_word','en','global',2,'Guess the word','pyramid','{"pyramids"}','{"a monument","in Egypt","triangular","ancient wonder"}')
on conflict do nothing;

-- ---------- من أنا؟ / Who Am I --------------------------------------
insert into public.questions (game_key, locale, region, difficulty, body, answer, alt_answers, metadata) values
  ('who_am_i','ar','yemen',2,'شخصية يمنية','عبده خال','{}','{"category":"أدب"}'),
  ('who_am_i','ar','yemen',1,'شخصية يمنية','أبو بكر سالم','{"ابو بكر سالم"}','{"category":"فن"}'),
  ('who_am_i','ar','yemen',2,'شخصية يمنية','توكل كرمان','{}','{"category":"مجتمع"}'),
  ('who_am_i','ar','yemen',2,'شخصية يمنية تاريخية','بلقيس','{"ملكة سبأ","بلقيس ملكة سبا"}','{"category":"تاريخ"}'),
  ('who_am_i','ar','arab',1,'شخصية عربية','أحمد شوقي','{"احمد شوقي","أمير الشعراء"}','{"category":"أدب"}'),
  ('who_am_i','ar','arab',1,'شخصية عربية','نجيب محفوظ','{}','{"category":"أدب"}'),
  ('who_am_i','ar','arab',2,'شخصية عربية','ابن بطوطة','{}','{"category":"رحالة"}'),
  ('who_am_i','ar','arab',1,'شخصية عربية','أم كلثوم','{"ام كلثوم"}','{"category":"فن"}'),
  ('who_am_i','ar','global',1,'شخصية عالمية','ألبرت أينشتاين','{"اينشتاين","albert einstein"}','{"category":"علوم"}'),
  ('who_am_i','ar','global',1,'شخصية عالمية','ليونيل ميسي','{"ميسي","messi"}','{"category":"رياضة"}'),
  ('who_am_i','ar','global',2,'شخصية عالمية','نيلسون مانديلا','{"مانديلا"}','{"category":"سياسة"}'),
  ('who_am_i','ar','global',2,'شخصية عالمية','ابن سينا','{"avicenna"}','{"category":"طب"}')
on conflict do nothing;

-- ---------- الكذاب بيننا / Liar words --------------------------------
-- body = the real word, metadata.decoy = the word given to the liar
insert into public.questions (game_key, locale, region, difficulty, body, metadata) values
  ('liar','ar','yemen',1,'المندي','{"category":"أكلات","decoy":"الكبسة"}'),
  ('liar','ar','yemen',1,'صنعاء','{"category":"مدن","decoy":"تعز"}'),
  ('liar','ar','yemen',2,'الجنبية','{"category":"تراث","decoy":"العمامة"}'),
  ('liar','ar','arab',1,'القهوة','{"category":"مشروبات","decoy":"الشاي"}'),
  ('liar','ar','arab',1,'المدرسة','{"category":"أماكن","decoy":"الجامعة"}'),
  ('liar','ar','arab',2,'الطائرة','{"category":"مواصلات","decoy":"القطار"}'),
  ('liar','ar','global',1,'كرة القدم','{"category":"رياضة","decoy":"كرة السلة"}'),
  ('liar','ar','global',2,'الهاتف','{"category":"أجهزة","decoy":"الحاسوب"}'),
  ('liar','ar','arab',1,'رمضان','{"category":"مناسبات","decoy":"العيد"}'),
  ('liar','ar','yemen',2,'البن اليمني','{"category":"منتجات","decoy":"التمر"}')
on conflict do nothing;

-- ---------- القصة الجماعية / Group story openings -----------------------
insert into public.questions (game_key, locale, region, difficulty, body) values
  ('group_story','ar','yemen',1,'في زقاق قديم من أزقة صنعاء، فتح رجلٌ بابًا لم يُفتح منذ أربعين سنة…'),
  ('group_story','ar','arab',1,'وصلت رسالة إلى هاتف الجميع في اللحظة نفسها، وكان مكتوبًا فيها سطر واحد…'),
  ('group_story','ar','global',1,'استيقظ سكان المدينة ذات صباح فوجدوا أن الساعات كلها توقفت عند الرقم نفسه…'),
  ('group_story','ar','yemen',1,'في سوق الملح، باع تاجرٌ صندوقًا مغلقًا واشترط ألا يُفتح قبل الغروب…'),
  ('group_story','ar','arab',1,'قرر أصدقاء الطفولة أن يجتمعوا بعد عشرين عامًا، لكن أحدهم لم يأتِ…')
on conflict do nothing;

