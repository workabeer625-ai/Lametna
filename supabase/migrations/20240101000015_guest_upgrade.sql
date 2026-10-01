-- ============================================================
--  لمّتنا — ترقية حساب الضيف إلى حساب كامل
--
--  عند ربط الضيف بريدًا وكلمة مرور بحسابه (auth.updateUser) يبقى
--  profiles.is_guest = true لأن المشغّل tg_protect_profile_stats يجمّده.
--  هذا الترحيل يسمح باستبدال العلم مرة واحدة فقط: من ضيف إلى غير ضيف،
--  وبشرط أن يحمل رمز الجلسة بريدًا فعليًا.
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

-- يستدعيها التطبيق بعد نجاح ربط البريد.
create or replace function public.link_guest_account()
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  if nullif(auth.jwt() ->> 'email', '') is null then
    return;   -- لم يُربط بريد بعد: لا شيء نفعله
  end if;
  update public.profiles
     set is_guest = false
   where id = auth.uid()
     and is_guest;
  delete from public.guest_sessions where user_id = auth.uid();
end $$;

revoke all on function public.link_guest_account() from public;
grant execute on function public.link_guest_account() to authenticated;
