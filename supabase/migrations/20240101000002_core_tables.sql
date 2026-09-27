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
