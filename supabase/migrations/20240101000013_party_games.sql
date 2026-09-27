-- ============================================================
-- لمّتنا / Lametna — 0013 ألعاب اللمّة والتفاعل (18 ← 25 لعبة)
--
--   😉 الغمزة            wink              ← محرك المافيا (غمّاز واحد)
--   🕵️‍♀️ الجاسوس          spy               ← محرك الكذاب (مكان بدل كلمة)
--   🤫 من صاحب الاعتراف؟ confessions       ← منطق جديد: كتابة ثم تخمين
--   👉 مين فينا؟         most_likely       ← منطق جديد: تصويت على لاعب
--   🙋 أنا ما سويت قط    never_have_i      ← منطق جديد: كشف الاختيارات
--   🤷 لو خيّروك          would_you_rather  ← منطق جديد: كشف الاختيارات
--   💬 صراحة             truth             ← منطق جديد: كرسي الاعتراف ثم تقييم
--
-- الترحيل يعيد تعريف: start_game · send_message · _begin_round · resolve_round
-- ============================================================

-- ============================================================
--  ألعاب اللمّة والتفاعل (7) — المجموع يصبح 25
-- ============================================================
insert into public.games (key, name_ar, name_en, description_ar, description_en, icon,
                          categories, min_players, max_players, default_rounds, round_seconds, sort_order) values
  ('wink','الغمزة','Wink Murder',
   'غمّاز واحد بينكم يغمز سرًا فيُخرج لاعبًا كل جولة، والباقون يكشفونه بالتصويت.',
   'One secret winker eliminates a player each round — the rest must unmask them.',
   '😉', '{arabic,family,competitive}', 4, 16, 12, 90, 19),

  ('spy','الجاسوس','The Spy',
   'الجميع يعرفون المكان إلا الجاسوس. تحدّثوا عنه دون كشفه، ثم صوّتوا.',
   'Everyone knows the location except the spy. Talk about it without revealing it.',
   '🕵️‍♀️', '{arabic,global,competitive}', 4, 12, 4, 75, 20),

  ('confessions','من صاحب الاعتراف؟','Whose Confession?',
   'كل لاعب يكتب اعترافًا سريًا، ثم يُعرض واحد ويخمّن الجميع صاحبه.',
   'Everyone writes a secret confession, then you guess whose it is.',
   '🤫', '{family,arabic,global}', 3, 12, 5, 75, 21),

  ('most_likely','مين فينا؟','Most Likely To',
   '«مين فينا أكثر واحد ينسى؟» — صوّتوا على بعضكم واضحكوا على النتيجة.',
   'Vote for the friend who fits the statement best.',
   '👉', '{family,arabic,fast}', 3, 16, 8, 45, 22),

  ('never_have_i','أنا ما سويت قط','Never Have I Ever',
   'عبارة تظهر، وكل واحد يعترف: سويتها أم لا؟ ثم تُكشف إجابات الجميع.',
   'A statement appears — did you do it or not? Then all answers are revealed.',
   '🙋', '{family,arabic,fast}', 3, 16, 10, 35, 23),

  ('would_you_rather','لو خيّروك','Would You Rather',
   'خياران صعبان، اختر واحدًا، ثم شاهد كيف انقسمت اللمّة.',
   'Two tough options — choose one and see how the group splits.',
   '🤷', '{family,global,fast}', 2, 16, 10, 35, 24),

  ('truth','صراحة','Truth Seat',
   'كل جولة لاعب على كرسي الاعتراف يجيب بصراحة، والباقون يقيّمون جوابه.',
   'Each round one player answers honestly and the rest rate the answer.',
   '💬', '{family,arabic}', 3, 12, 8, 75, 25)
on conflict (key) do update set
  name_ar = excluded.name_ar, name_en = excluded.name_en,
  description_ar = excluded.description_ar, description_en = excluded.description_en,
  icon = excluded.icon, categories = excluded.categories,
  min_players = excluded.min_players, max_players = excluded.max_players,
  default_rounds = excluded.default_rounds, round_seconds = excluded.round_seconds,
  sort_order = excluded.sort_order;

-- ============================================================
--  بنك المحتوى
-- ============================================================
-- ملاحظة: «الغمزة» لا تحتاج محتوى — الأدوار تُوزَّع في start_game.

-- ---------- الجاسوس (محرك الكذاب: body = المكان، decoy فارغ) ----------
insert into public.questions (game_key, locale, region, difficulty, body, metadata) values
  ('spy','ar','arab',1,'المدرسة','{"category":"أماكن","decoy":""}'),
  ('spy','ar','arab',1,'المستشفى','{"category":"أماكن","decoy":""}'),
  ('spy','ar','yemen',1,'سوق شعبي','{"category":"أماكن","decoy":""}'),
  ('spy','ar','yemen',2,'مقهى قهوة يمنية','{"category":"أماكن","decoy":""}'),
  ('spy','ar','arab',1,'المطار','{"category":"أماكن","decoy":""}'),
  ('spy','ar','arab',2,'حفل زفاف','{"category":"مناسبات","decoy":""}'),
  ('spy','ar','arab',1,'الشاطئ','{"category":"أماكن","decoy":""}'),
  ('spy','ar','arab',2,'محطة قطار','{"category":"أماكن","decoy":""}'),
  ('spy','ar','arab',1,'مطعم','{"category":"أماكن","decoy":""}'),
  ('spy','ar','yemen',2,'جبل حراز','{"category":"أماكن","decoy":""}'),
  ('spy','ar','arab',2,'مكتبة عامة','{"category":"أماكن","decoy":""}'),
  ('spy','ar','arab',3,'محطة فضاء','{"category":"أماكن","decoy":""}'),
  ('spy','ar','arab',2,'ملعب كرة قدم','{"category":"أماكن","decoy":""}'),
  ('spy','ar','arab',2,'صالون حلاقة','{"category":"أماكن","decoy":""}')
on conflict do nothing;

-- ---------- من صاحب الاعتراف؟ ------------------------------------
insert into public.questions (game_key, locale, region, difficulty, body) values
  ('confessions','ar','arab',1,'اكتب أطرف موقف محرج حصل لك ولم يعرفه أحد.'),
  ('confessions','ar','arab',1,'اكتب عادة غريبة تفعلها وأنت وحدك.'),
  ('confessions','ar','arab',1,'اكتب شيئًا كذبت فيه كذبة بيضاء.'),
  ('confessions','ar','yemen',2,'اكتب أكلة يحبها الجميع وأنت لا تطيقها.'),
  ('confessions','ar','arab',1,'اكتب أغبى شيء اشتريته في حياتك.'),
  ('confessions','ar','arab',2,'اكتب مهارة تظن أنك سيئ فيها جدًا.'),
  ('confessions','ar','arab',1,'اكتب شيئًا تخاف منه ولا تعترف به عادة.'),
  ('confessions','ar','arab',2,'اكتب أغرب حلم رأيته وتتذكره.'),
  ('confessions','ar','arab',1,'اكتب عذرًا اخترعته للهروب من موقف.'),
  ('confessions','ar','yemen',2,'اكتب شيئًا فعلته في المدرسة ولم يكتشفه المعلم.')
on conflict do nothing;

-- ---------- مين فينا؟ ---------------------------------------------
insert into public.questions (game_key, locale, region, difficulty, body) values
  ('most_likely','ar','arab',1,'مين فينا أكثر واحد ينسى مواعيده؟'),
  ('most_likely','ar','arab',1,'مين فينا يضحك في أسوأ وقت ممكن؟'),
  ('most_likely','ar','arab',1,'مين فينا ينام متأخر أكثر من الكل؟'),
  ('most_likely','ar','yemen',1,'مين فينا ما يقدر يعيش بدون قهوة؟'),
  ('most_likely','ar','arab',1,'مين فينا يرد على الرسائل بعد ثلاثة أيام؟'),
  ('most_likely','ar','arab',2,'مين فينا ممكن يضيع في مدينة يعرفها؟'),
  ('most_likely','ar','arab',1,'مين فينا يشتري أشياء ما يحتاجها؟'),
  ('most_likely','ar','arab',2,'مين فينا يصير مشهور أول واحد؟'),
  ('most_likely','ar','arab',1,'مين فينا أكثر واحد يتكلم في الجلسة؟'),
  ('most_likely','ar','yemen',2,'مين فينا يعرف كل مطاعم المدينة؟'),
  ('most_likely','ar','arab',1,'مين فينا يبكي في الأفلام؟'),
  ('most_likely','ar','arab',2,'مين فينا يقدر يسكت أطول وقت؟'),
  ('most_likely','ar','arab',1,'مين فينا يتأخر على كل موعد؟'),
  ('most_likely','ar','arab',2,'مين فينا يقدر ياكل حار جدًا بدون ماء؟')
on conflict do nothing;

-- ---------- أنا ما سويت قط ------------------------------------------
insert into public.questions (game_key, locale, region, difficulty, body, choices) values
  ('never_have_i','ar','arab',1,'نمت وأنا في مكالمة مع أحدهم.','["سويتها","ما سويتها"]'),
  ('never_have_i','ar','arab',1,'أكلت شيئًا سقط على الأرض.','["سويتها","ما سويتها"]'),
  ('never_have_i','ar','arab',1,'تظاهرت أنني مشغول لأتجنب موقفًا.','["سويتها","ما سويتها"]'),
  ('never_have_i','ar','yemen',1,'شربت أكثر من خمسة أكواب قهوة في يوم.','["سويتها","ما سويتها"]'),
  ('never_have_i','ar','arab',1,'نسيت اسم شخص وأنا أتحدث معه.','["سويتها","ما سويتها"]'),
  ('never_have_i','ar','arab',2,'أرسلت رسالة لشخص خطأ.','["سويتها","ما سويتها"]'),
  ('never_have_i','ar','arab',1,'سهرت الليل كله بدون نوم.','["سويتها","ما سويتها"]'),
  ('never_have_i','ar','arab',2,'ضحكت في موقف يُفترض أن يكون جادًا.','["سويتها","ما سويتها"]'),
  ('never_have_i','ar','arab',1,'بحثت عن اسمي في الإنترنت.','["سويتها","ما سويتها"]'),
  ('never_have_i','ar','arab',2,'وعدت بشيء ونسيته تمامًا.','["سويتها","ما سويتها"]'),
  ('never_have_i','ar','yemen',2,'ضعت في سوق ولم أجد المخرج.','["سويتها","ما سويتها"]'),
  ('never_have_i','ar','arab',1,'تكلمت مع نفسي بصوت عالٍ.','["سويتها","ما سويتها"]')
on conflict do nothing;

-- ---------- لو خيّروك -------------------------------------------------
insert into public.questions (game_key, locale, region, difficulty, body, choices) values
  ('would_you_rather','ar','arab',1,'لو خيّروك…','["تعيش بلا إنترنت شهرًا","تعيش بلا قهوة سنة"]'),
  ('would_you_rather','ar','arab',1,'لو خيّروك…','["تقرأ أفكار الناس","تختفي متى شئت"]'),
  ('would_you_rather','ar','arab',1,'لو خيّروك…','["تسافر للماضي","تسافر للمستقبل"]'),
  ('would_you_rather','ar','yemen',1,'لو خيّروك…','["مندي كل يوم","سلتة كل يوم"]'),
  ('would_you_rather','ar','arab',2,'لو خيّروك…','["تعرف موعد كل شيء","تغيّر أي قرار مرة واحدة"]'),
  ('would_you_rather','ar','arab',1,'لو خيّروك…','["تعيش في مدينة كبيرة","تعيش في قرية هادئة"]'),
  ('would_you_rather','ar','arab',2,'لو خيّروك…','["تكون أذكى إنسان","تكون أسعد إنسان"]'),
  ('would_you_rather','ar','arab',1,'لو خيّروك…','["صيف دائم","شتاء دائم"]'),
  ('would_you_rather','ar','arab',2,'لو خيّروك…','["تتكلم كل اللغات","تعزف كل الآلات"]'),
  ('would_you_rather','ar','arab',1,'لو خيّروك…','["تستيقظ مبكرًا دائمًا","تسهر متأخرًا دائمًا"]'),
  ('would_you_rather','ar','arab',2,'لو خيّروك…','["شهرة بلا مال","مال بلا شهرة"]'),
  ('would_you_rather','ar','arab',1,'لو خيّروك…','["تفقد هاتفك أسبوعًا","تفقد صوتك يومًا"]')
on conflict do nothing;

-- ---------- صراحة ------------------------------------------------------
insert into public.questions (game_key, locale, region, difficulty, body) values
  ('truth','ar','arab',1,'ما أكثر قرار تفتخر به في حياتك؟'),
  ('truth','ar','arab',1,'ما الشيء الذي تتمنى لو غيّرته في نفسك؟'),
  ('truth','ar','arab',1,'من أكثر شخص أثّر فيك ولماذا؟'),
  ('truth','ar','yemen',2,'ما أجمل ذكرى لك في بلدك؟'),
  ('truth','ar','arab',1,'ما أكبر خوف تواجهه هذه الأيام؟'),
  ('truth','ar','arab',2,'لو اعتذرت لشخص واحد اليوم، لمن يكون؟'),
  ('truth','ar','arab',1,'ما الحلم الذي لم تخبر به أحدًا؟'),
  ('truth','ar','arab',2,'ما أصعب موقف تعلمت منه درسًا؟'),
  ('truth','ar','arab',1,'ما الشيء الذي يُسعدك ولو كان بسيطًا؟'),
  ('truth','ar','arab',2,'لو عاد بك الزمن خمس سنوات، بماذا تنصح نفسك؟'),
  ('truth','ar','arab',1,'ما أكثر شيء تشعر بالامتنان له؟'),
  ('truth','ar','yemen',2,'ما المكان الذي تشتاق إليه دائمًا؟')
on conflict do nothing;

-- ---------- إنجازات اللمّة ------------------------------------------------
insert into public.achievements (key, name_ar, name_en, description_ar, description_en, icon, points) values
  ('social_butterfly','روح اللمّة','Life of the Party','فزت في 5 مباريات من ألعاب اللمّة','Won 5 party-game matches','🎉',120),
  ('wink_master','عين الصقر','Hawk Eye','كشفت الغمّاز 3 مرات','Unmasked the winker 3 times','😉',100)
on conflict (key) do update set name_ar = excluded.name_ar;

-- ============================================================
--  الدوال المحدَّثة
-- ============================================================

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
  if v_room.game_key in ('mafia','wink') then
    if v_room.game_key = 'wink' then
      v_mafia_n := 1;                       -- غمّاز واحد فقط
    else
      v_mafia_n := greatest(1, floor(v_count / 3.5)::int);
    end if;
    v_roles := array_fill('citizen'::mafia_role, array[v_count]);
    for v_i in 1..v_mafia_n loop v_roles[v_i] := 'mafia'; end loop;
    if v_room.game_key = 'mafia' then     -- الأدوار الخاصة في المافيا فقط
      if v_count >= 5 then v_roles[v_mafia_n + 1] := 'doctor'; end if;
      if v_count >= 6 then v_roles[v_mafia_n + 2] := 'detective'; end if;
      if v_count >= 8 then v_roles[v_mafia_n + 3] := 'guard'; end if;
    end if;
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
                where gs.room_id = p_room and gs.status = 'running' and gs.game_key in ('mafia','wink'))
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
  v_spot     uuid;
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

  elsif v_s.game_key in ('mafia','wink') then
    if p_index % 2 = 1 then
      v_phase := 'night';
      v_seconds := coalesce((v_s.config ->> 'night_seconds')::int, 45);
      v_prompt := jsonb_build_object('stage','night','cycle', (p_index + 1) / 2);
    else
      v_phase := 'voting';
      v_seconds := coalesce((v_s.config ->> 'day_seconds')::int, 120);
      v_prompt := jsonb_build_object('stage','day','cycle', p_index / 2);
    end if;

  elsif v_s.game_key in ('true_false','guess_word','proverbs','who_am_i','capitals','flags','riddles','islamic','sports','history','emoji_puzzle','fast_math') then
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
      'hints', case when v_s.game_key in ('guess_word','riddles') then to_jsonb(v_q.hints) else '[]'::jsonb end,
      'metadata', v_q.metadata
    );
    v_secret := jsonb_build_object('answer', v_q.answer, 'alt', to_jsonb(v_q.alt_answers));

  elsif v_s.game_key in ('liar','secret_job','spy') then
    select * into v_q from public.questions where game_key = v_s.game_key and is_active
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

  elsif v_s.game_key in ('group_story','best_answer') then
    select * into v_q from public.questions where game_key = v_s.game_key and is_active
     order by random() limit 1;
    v_prompt := jsonb_build_object('stage','write',
                'opening', coalesce(v_q.body, 'كان يا ما كان…'));

  -- ---------- مين فينا؟ (تصويت على لاعب) ----------------------
  elsif v_s.game_key = 'most_likely' then
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
    v_phase  := 'voting';
    v_prompt := jsonb_build_object('stage','vote_player',
                  'question_id', v_q.id, 'body', v_q.body);

  -- ---------- أنا ما سويت قط / لو خيّروك ----------------------
  elsif v_s.game_key in ('never_have_i','would_you_rather') then
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
    v_prompt := jsonb_build_object('stage','answer',
                  'question_id', v_q.id, 'body', v_q.body,
                  'choices', coalesce(v_q.choices, '["نعم","لا"]'::jsonb));

  -- ---------- من صاحب الاعتراف؟ (كتابة ثم تخمين) --------------
  elsif v_s.game_key = 'confessions' then
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
    v_prompt := jsonb_build_object('stage','write',
                  'question_id', v_q.id, 'body', v_q.body);

  -- ---------- صراحة (كرسي الاعتراف بالتناوب) ------------------
  elsif v_s.game_key = 'truth' then
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
    v_spot := v_players[1 + ((p_index - 1) % array_length(v_players,1))];
    v_prompt := jsonb_build_object('stage','spotlight',
                  'question_id', v_q.id, 'body', v_q.body,
                  'spotlight', v_spot,
                  'spotlight_nickname',
                    (select nickname from public.profiles where id = v_spot));

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
  v_author  uuid;
  v_spot    uuid;
  v_likes   int;
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
    elsif v_stage = 'spotlight' then
      -- صراحة: لا ينتظر إلا صاحب كرسي الاعتراف
      select count(*) into v_submitted from public.answers
       where round_id = p_round and user_id = (v_round.prompt ->> 'spotlight')::uuid;
      v_alive := 1;
    elsif v_stage in ('vote','day','vote_player','guess','rate') then
      select count(distinct voter_id) into v_submitted from public.votes where round_id = p_round;
      if v_stage = 'rate' then v_alive := greatest(1, v_alive - 1); end if;
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
  elsif v_s.game_key in ('true_false','guess_word','proverbs','who_am_i','capitals','flags','riddles','islamic','sports','history','emoji_puzzle','fast_math') then
    v_fuzzy := v_s.game_key in ('proverbs','who_am_i','guess_word','riddles','emoji_puzzle');
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
  elsif v_s.game_key in ('liar','secret_job','spy') then
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
  elsif v_s.game_key in ('group_story','best_answer') then
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
  elsif v_s.game_key in ('mafia','wink') then
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

  -- =========================================================
  -- مين فينا؟  /  Most likely to
  -- =========================================================
  elsif v_s.game_key = 'most_likely' then
    select target_user, count(*) into v_accused, v_top from public.votes
     where round_id = p_round and kind = 'best_answer' and target_user is not null
     group by target_user order by count(*) desc, random() limit 1;

    update public.room_players set score = score + 3
     where room_id = v_room and not is_spectator and left_at is null
       and user_id in (select voter_id from public.votes
                        where round_id = p_round and kind = 'best_answer');
    if v_accused is not null then
      update public.room_players set score = score + 10
       where room_id = v_room and user_id = v_accused;
    end if;

    v_result := jsonb_build_object('stage','scored',
      'body', v_round.prompt ->> 'body',
      'winner', v_accused,
      'winner_nickname', (select nickname from public.profiles where id = v_accused),
      'votes', coalesce((
        select jsonb_agg(jsonb_build_object(
                 'user_id', t.target_user,
                 'nickname', (select nickname from public.profiles where id = t.target_user),
                 'count', t.c) order by t.c desc)
          from (select target_user, count(*) c from public.votes
                 where round_id = p_round and kind = 'best_answer' and target_user is not null
                 group by target_user) t), '[]'::jsonb));

  -- =========================================================
  -- أنا ما سويت قط / لو خيّروك  (كشف الاختيارات، بلا صواب وخطأ)
  -- =========================================================
  elsif v_s.game_key in ('never_have_i','would_you_rather') then
    for v_ans in select user_id from public.answers where round_id = p_round loop
      perform public._award(p_round, v_ans.user_id, 5);
    end loop;

    select jsonb_build_object('stage','scored',
             'body', v_round.prompt ->> 'body',
             'answers', coalesce(jsonb_agg(jsonb_build_object(
                'user_id', a.user_id, 'nickname', p.nickname,
                'value', a.payload ->> 'value')), '[]'::jsonb),
             'tally', coalesce((
                select jsonb_object_agg(t.v, t.c) from (
                  select coalesce(a2.payload ->> 'value','—') as v, count(*) as c
                    from public.answers a2 where a2.round_id = p_round group by 1) t),
                '{}'::jsonb))
      into v_result
      from public.answers a join public.profiles p on p.id = a.user_id
     where a.round_id = p_round;

  -- =========================================================
  -- من صاحب الاعتراف؟  (كتابة → تخمين)
  -- =========================================================
  elsif v_s.game_key = 'confessions' then
    if v_stage = 'write' then
      select a.user_id, a.payload ->> 'value' into v_author, v_val
        from public.answers a where a.round_id = p_round order by random() limit 1;
      if v_author is not null then
        update public.rounds
           set prompt = prompt || jsonb_build_object('stage','guess','confession', v_val),
               secret_data = secret_data || jsonb_build_object('author', v_author),
               ends_at = now() + interval '60 seconds'
         where id = p_round;
        perform public.touch_room(v_room);
        return jsonb_build_object('stage','guess','advanced', true);
      end if;
      v_result := jsonb_build_object('stage','scored','skipped', true);
    else
      v_author := (v_round.secret_data ->> 'author')::uuid;
      update public.room_players set score = score + 10
       where room_id = v_room
         and user_id in (select voter_id from public.votes
                          where round_id = p_round and kind = 'best_answer'
                            and target_user = v_author);
      if not exists (select 1 from public.votes
                      where round_id = p_round and kind = 'best_answer'
                        and target_user = v_author) then
        update public.room_players set score = score + 15
         where room_id = v_room and user_id = v_author;
      end if;
      v_result := jsonb_build_object('stage','scored',
        'author', v_author,
        'author_nickname', (select nickname from public.profiles where id = v_author),
        'confession', v_round.prompt ->> 'confession');
    end if;

  -- =========================================================
  -- صراحة  (كرسي الاعتراف → تقييم)
  -- =========================================================
  elsif v_s.game_key = 'truth' then
    v_spot := (v_round.prompt ->> 'spotlight')::uuid;
    if v_stage = 'spotlight' then
      update public.rounds
         set prompt = prompt || jsonb_build_object('stage','rate',
               'answer_text', coalesce((select a.payload ->> 'value' from public.answers a
                                         where a.round_id = p_round and a.user_id = v_spot limit 1), '')),
             ends_at = now() + interval '45 seconds'
       where id = p_round;
      perform public.touch_room(v_room);
      return jsonb_build_object('stage','rate','advanced', true);
    end if;

    select count(*) into v_likes from public.votes
     where round_id = p_round and kind = 'validate_answer' and coalesce(value, false);

    update public.room_players set score = score + 5 + (v_likes * 5)
     where room_id = v_room and user_id = v_spot;
    update public.room_players set score = score + 3
     where room_id = v_room
       and user_id in (select voter_id from public.votes
                        where round_id = p_round and kind = 'validate_answer');

    v_result := jsonb_build_object('stage','scored',
      'spotlight', v_spot,
      'spotlight_nickname', (select nickname from public.profiles where id = v_spot),
      'body', v_round.prompt ->> 'body',
      'answer_text', v_round.prompt ->> 'answer_text',
      'likes', v_likes);
  end if;

  -- ---------- close the round -------------------------------
  update public.rounds
     set resolved_at = now(), phase = 'revealed', result = v_result
   where id = p_round;
  perform public.touch_room(v_room);

  -- ---------- advance the session ----------------------------
  if v_s.game_key in ('mafia','wink') then
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
