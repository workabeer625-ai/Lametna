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
