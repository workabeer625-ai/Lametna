-- ============================================================
--  لمّتنا — سكربت تشغيل واحد يُلصق في Supabase → SQL Editor
--  يُغني عن Supabase CLI (إن لم يكن مثبتًا على جهازك).
--
--  يحتوي:
--    الجزء 1: ترحيل 20240101000015 — ترقية حساب الضيف
--    الجزء 2: إنشاء/ترقية حساب المدير للوحة التحكم
--
--  آمن للتشغيل أكثر من مرة (idempotent).
-- ============================================================


-- ============================================================
--  الجزء 1 · ترقية حساب الضيف إلى حساب كامل
--  (نسخة طبق الأصل من supabase/migrations/20240101000015_guest_upgrade.sql)
-- ============================================================

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
  -- الضيف الذي ربط بريدًا يصبح لاعبًا كاملًا؛ العكس ممنوع.
  if old.is_guest and nullif(auth.jwt() ->> 'email', '') is not null then
    new.is_guest := false;
  else
    new.is_guest := old.is_guest;
  end if;
  return new;
end $$;

create or replace function public.link_guest_account()
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  if nullif(auth.jwt() ->> 'email', '') is null then
    return;
  end if;
  update public.profiles
     set is_guest = false
   where id = auth.uid()
     and is_guest;
  delete from public.guest_sessions where user_id = auth.uid();
end $$;

revoke all on function public.link_guest_account() from public;
grant execute on function public.link_guest_account() to authenticated;


-- ============================================================
--  الجزء 2 · حساب المدير
--
--  ⚠️ الطريقة الموصى بها لإنشاء الحساب:
--     Authentication → Users → Add user
--       Email: beeroali839@gmail.com
--       Password: (كلمة السر القوية التي لديك)
--       ✅ Auto Confirm User
--     ثم شغّل هذا الجزء لترقيته إلى admin.
--
--  إن كان الحساب موجودًا مسبقًا فلن يُنشأ من جديد؛ سيُرقّى فقط.
-- ============================================================

do $$
declare
  v_email text := 'beeroali839@gmail.com';   -- ← بريد المدير
  v_id    uuid;
begin
  select id into v_id from auth.users where lower(email) = lower(v_email) limit 1;

  if v_id is null then
    raise exception E'\n\n❌ لا يوجد مستخدم بالبريد %\n   أنشئه أولًا من: Authentication → Users → Add user (مع تفعيل Auto Confirm User)\n   ثم أعد تشغيل هذا السكربت.\n', v_email;
  end if;

  -- شبكة أمان: لو لم يُنشئ المشغّل ملفًا شخصيًا لأي سبب
  insert into public.profiles (id, nickname, is_guest)
  values (v_id, 'المدير-' || substr(replace(v_id::text, '-', ''), 1, 4), false)
  on conflict (id) do nothing;

  -- المشغّل يجمّد عمود role عمدًا، فنعطّله مؤقتًا لهذه العملية الإدارية فقط
  alter table public.profiles disable trigger profiles_protect_stats;

  update public.profiles
     set role     = 'admin',
         is_guest = false
   where id = v_id;

  alter table public.profiles enable trigger profiles_protect_stats;

  raise notice '✅ تمت ترقية % إلى مدير (id = %)', v_email, v_id;
end $$;

-- تحقّق نهائي: يجب أن يظهر صفّ واحد role = admin
select p.id, p.nickname, p.role, p.is_guest, u.email, u.email_confirmed_at
  from public.profiles p
  join auth.users u on u.id = p.id
 where lower(u.email) = lower('beeroali839@gmail.com');


-- ============================================================
--  (اختياري) إنشاء حساب المدير بالـ SQL بدل لوحة التحكم
--  استعمله فقط إن تعذّر Add user من الواجهة.
--  استبدل PUT_PASSWORD_HERE بكلمة السر قبل التشغيل، ولا تحفظ الملف بعدها.
-- ============================================================
-- do $$
-- declare
--   v_email text := 'beeroali839@gmail.com';
--   v_pass  text := 'PUT_PASSWORD_HERE';
--   v_id    uuid := gen_random_uuid();
-- begin
--   if exists (select 1 from auth.users where lower(email) = lower(v_email)) then
--     raise notice 'الحساب موجود مسبقًا'; return;
--   end if;
--
--   insert into auth.users (
--     instance_id, id, aud, role, email, encrypted_password,
--     email_confirmed_at, created_at, updated_at,
--     raw_app_meta_data, raw_user_meta_data
--   ) values (
--     '00000000-0000-0000-0000-000000000000', v_id, 'authenticated', 'authenticated',
--     lower(v_email), extensions.crypt(v_pass, extensions.gen_salt('bf')),
--     now(), now(), now(),
--     '{"provider":"email","providers":["email"]}'::jsonb,
--     jsonb_build_object('nickname', 'المدير', 'is_guest', false)
--   );
--
--   begin
--     insert into auth.identities (id, user_id, identity_data, provider, provider_id,
--                                  last_sign_in_at, created_at, updated_at)
--     values (gen_random_uuid(), v_id,
--             jsonb_build_object('sub', v_id::text, 'email', lower(v_email)),
--             'email', lower(v_email), now(), now(), now());
--   exception when others then
--     raise notice 'تعذّر إنشاء صفّ identities: % — سجّل الدخول وجرّب، وإن فشل أنشئ الحساب من اللوحة', sqlerrm;
--   end;
--
--   raise notice '✅ أُنشئ الحساب %، شغّل الآن الجزء 2 لترقيته', v_email;
-- end $$;
