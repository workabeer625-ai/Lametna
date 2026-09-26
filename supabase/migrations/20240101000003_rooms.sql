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
