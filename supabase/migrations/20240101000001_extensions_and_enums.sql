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
