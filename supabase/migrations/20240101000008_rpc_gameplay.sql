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
