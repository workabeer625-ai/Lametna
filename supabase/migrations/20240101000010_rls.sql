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
