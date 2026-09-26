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
