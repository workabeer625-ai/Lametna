-- ============================================================
-- لمّتنا / Lametna — 0006 Helper functions & triggers
-- ============================================================

-- ---------- updated_at trigger ------------------------------
create or replace function public.tg_set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at before update on public.profiles
  for each row execute function public.tg_set_updated_at();

-- ---------- auth helpers ------------------------------------
create or replace function public.current_uid()
returns uuid language sql stable as $$ select auth.uid() $$;

create or replace function public.is_admin(p_user uuid default auth.uid())
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles p where p.id = p_user and p.role in ('admin','moderator'));
$$;

create or replace function public.is_room_member(p_room uuid, p_user uuid default auth.uid())
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.room_players rp
    where rp.room_id = p_room and rp.user_id = p_user and rp.left_at is null
  );
$$;

create or replace function public.is_room_host(p_room uuid, p_user uuid default auth.uid())
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.rooms r where r.id = p_room and r.host_id = p_user);
$$;

create or replace function public.session_room(p_session uuid)
returns uuid language sql stable security definer set search_path = public as $$
  select room_id from public.game_sessions where id = p_session;
$$;

create or replace function public.round_room(p_round uuid)
returns uuid language sql stable security definer set search_path = public as $$
  select gs.room_id from public.rounds r join public.game_sessions gs on gs.id = r.session_id where r.id = p_round;
$$;

create or replace function public.is_globally_banned(p_user uuid default auth.uid())
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.bans b
    where b.user_id = p_user and b.scope = 'global'
      and (b.expires_at is null or b.expires_at > now())
  );
$$;

-- ---------- audit -------------------------------------------
create or replace function public.log_audit(p_action text, p_entity text, p_entity_id text, p_meta jsonb default '{}'::jsonb)
returns void language sql security definer set search_path = public as $$
  insert into public.audit_logs (actor_id, action, entity, entity_id, metadata)
  values (auth.uid(), p_action, p_entity, p_entity_id, coalesce(p_meta,'{}'::jsonb));
$$;

-- ---------- room code generator -----------------------------
create or replace function public.generate_room_code()
returns text language plpgsql security definer set search_path = public, extensions as $$
declare
  alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- no I,O,0,1
  v_code text;
  i int;
begin
  for attempt in 1..20 loop
    v_code := '';
    for i in 1..6 loop
      v_code := v_code || substr(alphabet, 1 + floor(random() * length(alphabet))::int, 1);
    end loop;
    if not exists (select 1 from public.rooms where code = v_code and closed_at is null) then
      return v_code;
    end if;
  end loop;
  raise exception 'ROOM_CODE_EXHAUSTED';
end $$;

-- ---------- text moderation ---------------------------------
-- Normalises Arabic (removes tashkeel/tatweel, unifies alef/yaa) then screens.
create or replace function public.normalize_ar(p_text text)
returns text language sql immutable as $$
  select lower(trim(regexp_replace(
    translate(
      regexp_replace(coalesce(p_text,''), '[\u064B-\u0652\u0640]', '', 'g'),
      'أإآىةؤئ', 'اااهةوي'
    ), '\s+', ' ', 'g')));
$$;

create or replace function public.contains_banned_word(p_text text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.banned_words bw
    where position(public.normalize_ar(bw.word) in public.normalize_ar(p_text)) > 0
  );
$$;

create or replace function public.contains_link(p_text text)
returns boolean language sql immutable as $$
  select coalesce(p_text,'') ~* '(https?://|www\.|t\.me/|wa\.me/|[a-z0-9-]+\.(com|net|org|xyz|ru|top|link|click|info)(/|\s|$))';
$$;

-- Answers must not be empty/abusive/link-spam.
create or replace function public.is_clean_text(p_text text)
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(p_text,'') <> ''
     and not public.contains_link(p_text)
     and not public.contains_banned_word(p_text);
$$;

-- ---------- room activity touch ------------------------------
create or replace function public.touch_room(p_room uuid)
returns void language sql security definer set search_path = public as $$
  update public.rooms
     set last_activity_at = now(),
         expires_at = now() + interval '3 hours'
   where id = p_room;
$$;

-- ---------- profile bootstrap on signup ----------------------
create or replace function public.tg_handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_nick text;
  v_guest boolean;
begin
  v_guest := coalesce((new.raw_user_meta_data ->> 'is_guest')::boolean, new.email is null);
  v_nick  := nullif(trim(new.raw_user_meta_data ->> 'nickname'), '');
  if v_nick is null then
    v_nick := case when v_guest then 'ضيف-' else 'لاعب-' end || substr(replace(new.id::text,'-',''), 1, 5);
  end if;
  -- guarantee uniqueness
  while exists (select 1 from public.profiles p where p.nickname_lower = lower(v_nick)) loop
    v_nick := v_nick || floor(random()*10)::int::text;
  end loop;

  insert into public.profiles (id, nickname, is_guest, avatar_key, locale)
  values (
    new.id,
    v_nick,
    v_guest,
    (select key from public.avatars where is_active order by random() limit 1),
    coalesce(new.raw_user_meta_data ->> 'locale', 'ar')
  )
  on conflict (id) do nothing;

  if v_guest then
    insert into public.guest_sessions (user_id) values (new.id);
  end if;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.tg_handle_new_user();
