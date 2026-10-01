-- ============================================================
--  لمّتنا / Lametna — اختبارات RLS وقواعد اللعب
--
--  التشغيل محليًا (يحتاج Supabase CLI و Docker):
--     supabase start
--     supabase db reset            # migrations + seed
--     psql "$(supabase status -o env | grep DB_URL | cut -d= -f2-)" \
--          -v ON_ERROR_STOP=1 -f supabase/tests/rls_and_rules_test.sql
--
--  أو على مشروع مرحلي (staging) عبر SQL Editor.
--  ⚠️ لا تشغّله على قاعدة إنتاج: يُنشئ مستخدمين وهميين ثم يحذفهم.
-- ============================================================
begin;

create or replace function pg_temp.assert(p_condition boolean, p_label text)
returns void language plpgsql as $$
begin
  if p_condition then
    raise notice '  ✅ %', p_label;
  else
    raise exception '  ❌ FAILED: %', p_label;
  end if;
end $$;

-- ينتحل شخصية مستخدم مصادق عليه كما يفعل PostgREST
create or replace function pg_temp.act_as(p_user uuid)
returns void language plpgsql as $$
begin
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', p_user, 'role', 'authenticated')::text, true);
end $$;

create or replace function pg_temp.act_as_service()
returns void language plpgsql as $$
begin
  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims', '', true);
end $$;

-- ---------- تجهيز لاعبين وهميين -----------------------------
do $$
declare
  v_ids uuid[] := array[
    '11111111-1111-1111-1111-111111111111'::uuid,
    '22222222-2222-2222-2222-222222222222'::uuid,
    '33333333-3333-3333-3333-333333333333'::uuid,
    '44444444-4444-4444-4444-444444444444'::uuid,
    '55555555-5555-5555-5555-555555555555'::uuid,
    '66666666-6666-6666-6666-666666666666'::uuid
  ];
  v_id uuid;
  v_i int := 0;
begin
  foreach v_id in array v_ids loop
    v_i := v_i + 1;
    insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data,
                            created_at, updated_at)
    values (v_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
            'test' || v_i || '@lametna.test',
            json_build_object('nickname', 'تجربة' || v_i, 'is_guest', false)::jsonb,
            now(), now())
    on conflict (id) do nothing;
  end loop;
end $$;

\echo '--- 1) إنشاء غرفة والانضمام إليها ---'
do $$
declare
  v_host uuid := '11111111-1111-1111-1111-111111111111';
  v_p2   uuid := '22222222-2222-2222-2222-222222222222';
  v_room public.rooms;
  v_code text;
begin
  perform pg_temp.act_as(v_host);
  v_room := public.create_room('animal_plant_object', true, null, 'غرفة اختبار', 8);
  perform pg_temp.assert(v_room.code ~ '^[A-Z0-9]{6}$', 'رمز الغرفة من 6 خانات');
  perform pg_temp.assert(v_room.host_id = v_host, 'المنشئ هو المضيف');
  v_code := v_room.code;

  perform pg_temp.act_as(v_p2);
  perform public.join_room(v_code);
  perform pg_temp.assert(public.is_room_member(v_room.id, v_p2), 'اللاعب الثاني انضم');

  -- كلمة مرور خاطئة تُرفض
  perform pg_temp.act_as(v_host);
  declare v_private public.rooms;
  begin
    v_private := public.create_room('liar', false, 'secret123', 'خاصة', 8);
    perform pg_temp.act_as('33333333-3333-3333-3333-333333333333');
    begin
      perform public.join_room(v_private.code, 'wrong');
      perform pg_temp.assert(false, 'كان يجب رفض كلمة المرور الخاطئة');
    exception when others then
      perform pg_temp.assert(sqlerrm like '%WRONG_PASSWORD%', 'رفض كلمة المرور الخاطئة');
    end;
    perform public.join_room(v_private.code, 'secret123');
    perform pg_temp.assert(public.is_room_member(v_private.id), 'قبول كلمة المرور الصحيحة');
  end;
end $$;

\echo '--- 2) العميل لا يستطيع الكتابة مباشرة في الجداول ---'
do $$
begin
  perform pg_temp.act_as('22222222-2222-2222-2222-222222222222');
  begin
    insert into public.scores (user_id, game_key, points)
    values ('22222222-2222-2222-2222-222222222222', 'mafia', 999999);
    perform pg_temp.assert(false, 'كان يجب منع إدراج النقاط من العميل');
  exception when insufficient_privilege or others then
    perform pg_temp.assert(true, 'العميل لا يستطيع إدراج نقاط');
  end;

  begin
    update public.profiles set total_points = 999999
     where id = '22222222-2222-2222-2222-222222222222';
    perform pg_temp.assert(
      (select total_points from public.profiles
        where id = '22222222-2222-2222-2222-222222222222') <> 999999,
      'المُشغّل يمنع تعديل النقاط حتى لو مرّ التحديث');
  exception when others then
    perform pg_temp.assert(true, 'تعديل النقاط مرفوض');
  end;
end $$;

\echo '--- 3) سرية أدوار المافيا ---'
do $$
declare
  v_host uuid := '11111111-1111-1111-1111-111111111111';
  v_room public.rooms;
  v_session public.game_sessions;
  v_players uuid[] := array[
    '22222222-2222-2222-2222-222222222222'::uuid,
    '33333333-3333-3333-3333-333333333333'::uuid,
    '44444444-4444-4444-4444-444444444444'::uuid,
    '55555555-5555-5555-5555-555555555555'::uuid
  ];
  v_p uuid;
  v_visible int;
begin
  perform pg_temp.act_as(v_host);
  v_room := public.create_room('mafia', true, null, 'مافيا اختبار', 10);

  foreach v_p in array v_players loop
    perform pg_temp.act_as(v_p);
    perform public.join_room(v_room.code);
    perform public.set_ready(v_room.id, true);
  end loop;

  perform pg_temp.act_as(v_host);
  v_session := public.start_game(v_room.id);
  perform pg_temp.assert(v_session.status = 'running', 'بدأت مباراة المافيا');

  perform pg_temp.act_as_service();
  perform pg_temp.assert(
    (select count(*) from public.mafia_roles where session_id = v_session.id) = 5,
    'وُزِّع دور لكل لاعب على الخادم');
  perform pg_temp.assert(
    (select count(*) from public.mafia_roles
      where session_id = v_session.id and role = 'mafia') >= 1,
    'يوجد مافيا واحد على الأقل');

  -- لاعب عادي لا يرى إلا دوره
  perform pg_temp.act_as(v_players[1]);
  select count(*) into v_visible from public.mafia_roles where session_id = v_session.id;
  perform pg_temp.assert(v_visible = 1, 'اللاعب يرى دوره فقط (RLS)');
  perform pg_temp.assert(
    (select user_id from public.mafia_roles where session_id = v_session.id) = v_players[1],
    'الدور الظاهر هو دوره هو');

  -- الميت لا يصوّت
  perform pg_temp.act_as_service();
  update public.room_players set is_alive = false
   where room_id = v_room.id and user_id = v_players[2];
  update public.mafia_roles set is_alive = false
   where session_id = v_session.id and user_id = v_players[2];

  perform pg_temp.act_as(v_players[2]);
  begin
    perform public.cast_vote(
      (select id from public.rounds where session_id = v_session.id order by round_index desc limit 1),
      'lynch', v_players[1]);
    perform pg_temp.assert(false, 'كان يجب منع تصويت اللاعب الميت');
  exception when others then
    perform pg_temp.assert(sqlerrm like '%DEAD_CANNOT_VOTE%', 'الميت لا يصوّت');
  end;
end $$;

\echo '--- 4) الدردشة: الطول والروابط والكلمات الممنوعة ---'
do $$
declare
  v_host uuid := '11111111-1111-1111-1111-111111111111';
  v_room public.rooms;
begin
  perform pg_temp.act_as(v_host);
  v_room := public.create_room('proverbs', true, null, 'دردشة', 6);

  begin
    perform public.send_message(v_room.id, 'تفضلوا https://spam.example.com');
    perform pg_temp.assert(false, 'كان يجب منع الروابط');
  exception when others then
    perform pg_temp.assert(sqlerrm like '%LINKS_NOT_ALLOWED%', 'الروابط ممنوعة');
  end;

  begin
    perform public.send_message(v_room.id, 'يا غَبِي');
    perform pg_temp.assert(false, 'كان يجب منع الكلمة المسيئة');
  exception when others then
    perform pg_temp.assert(sqlerrm like '%BLOCKED_CONTENT%', 'الكلمات المسيئة محجوبة');
  end;

  begin
    perform public.send_message(v_room.id, repeat('ا', 400));
    perform pg_temp.assert(false, 'كان يجب رفض الرسالة الطويلة');
  exception when others then
    perform pg_temp.assert(true, 'حد طول الرسالة مُطبَّق');
  end;

  perform pg_temp.assert(
    (public.send_message(v_room.id, 'أهلًا بالجميع 👋')).id is not null,
    'الرسالة النظيفة تمر');
end $$;

\echo '--- 5) التطبيع العربي ومطابقة الإجابات ---'
do $$
begin
  perform pg_temp.assert(public.normalize_ar('أَحْمَــد') = 'احمد', 'تطبيع التشكيل والتطويل');
  perform pg_temp.assert(public.answer_matches('الضيقة', 'الضيق', array['الضيقة']),
                         'قبول رواية بديلة للمثل');
  perform pg_temp.assert(public.answer_matches('الذهب', 'ذهب', '{}', true),
                         'المطابقة المرنة تقبل الفروق البسيطة');
  perform pg_temp.assert(not public.answer_matches('', 'ذهب', '{}'), 'الإجابة الفارغة خاطئة');
end $$;

\echo '--- 6) الغرف غير النشطة تُغلق ---'
do $$
declare v_report jsonb;
begin
  perform pg_temp.act_as_service();
  update public.rooms set last_activity_at = now() - interval '5 hours',
                          expires_at = now() - interval '1 hour'
   where closed_at is null;
  v_report := public.cleanup_stale_rooms();
  perform pg_temp.assert((v_report ->> 'rooms_closed')::int > 0, 'تنظيف الغرف الخاملة يعمل');
end $$;

\echo ''
\echo '✅ كل الاختبارات نجحت — سيتم التراجع عن كل التغييرات (rollback).'

rollback;
