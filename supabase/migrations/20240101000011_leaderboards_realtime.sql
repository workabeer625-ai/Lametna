-- ============================================================
-- لمّتنا / Lametna — 0011 Leaderboards + Realtime publication
-- ============================================================

-- ---------- leaderboard ---------------------------------------
-- scope : 'global' | 'arab' | 'yemen'
-- period: 'week'   | 'month' | 'all'
create or replace function public.leaderboard(
  p_scope text default 'global',
  p_period text default 'all',
  p_game_key text default null,
  p_limit int default 50
) returns table (
  rank bigint, user_id uuid, nickname text, avatar_key text,
  country_code text, points bigint, wins bigint, games bigint, level int
) language sql stable security definer set search_path = public as $$
  with since as (
    select case p_period
             when 'week'  then now() - interval '7 days'
             when 'month' then now() - interval '30 days'
             else '-infinity'::timestamptz end as ts
  ),
  agg as (
    select s.user_id,
           sum(s.points)::bigint as points,
           count(*) filter (where s.is_win)::bigint as wins,
           count(*)::bigint as games
      from public.scores s, since
     where s.created_at >= since.ts
       and (p_game_key is null or s.game_key = p_game_key)
     group by s.user_id
  )
  select row_number() over (order by a.points desc, a.wins desc) as rank,
         p.id, p.nickname, p.avatar_key,
         case when p.show_country then p.country_code else null end,
         a.points, a.wins, a.games, p.level
    from agg a
    join public.profiles p on p.id = a.user_id
   where p.deleted_at is null
     and case p_scope
           when 'yemen' then p.show_country and p.country_code = 'YE'
           when 'arab'  then p.show_country and p.country_code in
                (select code from public.countries where region = 'arab')
           else true
         end
   order by a.points desc, a.wins desc
   limit greatest(1, least(coalesce(p_limit,50), 100));
$$;

create or replace function public.my_rank(p_scope text default 'global', p_period text default 'all')
returns jsonb language sql stable security definer set search_path = public as $$
  select coalesce((
    select to_jsonb(l) from public.leaderboard(p_scope, p_period, null, 100) l
     where l.user_id = auth.uid() limit 1), '{}'::jsonb);
$$;

grant execute on function public.leaderboard(text, text, text, int) to authenticated, anon;
grant execute on function public.my_rank(text, text) to authenticated;

-- ---------- admin statistics ------------------------------------
create or replace function public.admin_stats()
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  return jsonb_build_object(
    'users_total',      (select count(*) from public.profiles where deleted_at is null),
    'users_guests',     (select count(*) from public.profiles where is_guest and deleted_at is null),
    'users_new_7d',     (select count(*) from public.profiles where created_at > now() - interval '7 days'),
    'rooms_open',       (select count(*) from public.rooms where closed_at is null),
    'rooms_playing',    (select count(*) from public.rooms where status = 'playing'),
    'sessions_24h',     (select count(*) from public.game_sessions where started_at > now() - interval '24 hours'),
    'messages_24h',     (select count(*) from public.messages where created_at > now() - interval '24 hours'),
    'reports_open',     (select count(*) from public.reports where status = 'open'),
    'bans_global',      (select count(*) from public.bans where scope = 'global'),
    'questions_total',  (select count(*) from public.questions where is_active),
    'top_games',        (select coalesce(jsonb_agg(t), '[]'::jsonb) from
                          (select game_key, count(*) as plays from public.game_sessions
                            where started_at > now() - interval '30 days'
                            group by game_key order by plays desc limit 10) t)
  );
end $$;
grant execute on function public.admin_stats() to authenticated;

create or replace function public.admin_resolve_report(p_report bigint, p_status report_status, p_ban_days int default null)
returns void language plpgsql security definer set search_path = public as $$
declare v_r public.reports;
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  select * into v_r from public.reports where id = p_report;
  if not found then raise exception 'NOT_FOUND'; end if;
  update public.reports set status = p_status, handled_by = auth.uid(), handled_at = now()
   where id = p_report;
  if p_ban_days is not null then
    insert into public.bans (user_id, scope, reason, created_by, expires_at)
    values (v_r.reported_id, 'global', 'report#' || p_report,
            auth.uid(), case when p_ban_days = 0 then null else now() + make_interval(days => p_ban_days) end);
  end if;
  perform public.log_audit('report.resolve','report', p_report::text,
                           jsonb_build_object('status', p_status, 'ban_days', p_ban_days));
end $$;
grant execute on function public.admin_resolve_report(bigint, report_status, int) to authenticated;

-- ---------- Realtime publication ----------------------------------
-- Realtime respects RLS, so subscribers only receive rows they may read.
do $$
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    create publication supabase_realtime;
  end if;
end $$;

alter publication supabase_realtime add table public.rooms;
alter publication supabase_realtime add table public.room_players;
alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.game_sessions;
alter publication supabase_realtime add table public.rounds;
alter publication supabase_realtime add table public.answers;
alter publication supabase_realtime add table public.votes;
alter publication supabase_realtime add table public.notifications;

-- REPLICA IDENTITY FULL lets clients diff old/new rows on UPDATE.
alter table public.room_players replica identity full;
alter table public.rooms        replica identity full;
alter table public.rounds       replica identity full;

-- ---------- account deletion (GDPR-style) ----------------------------
create or replace function public.delete_my_account()
returns void language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception 'AUTH_REQUIRED'; end if;
  perform public.leave_room(rp.room_id) from public.room_players rp
    where rp.user_id = v_uid and rp.left_at is null;
  update public.profiles
     set deleted_at = now(),
         nickname = 'حساب-محذوف-' || substr(replace(v_uid::text,'-',''),1,6),
         avatar_key = null, country_code = null, show_country = false
   where id = v_uid;
  update public.messages set is_hidden = true, body = '[محذوف]' where user_id = v_uid;
  perform public.log_audit('account.delete','profile', v_uid::text, '{}'::jsonb);
end $$;
grant execute on function public.delete_my_account() to authenticated;

-- ---------- authoritative clock for clients ---------------------------
-- Devices must never trust their own clock for round timers. They call
-- this once on connect (and on reconnect) and keep a local offset.
create or replace function public.server_now()
returns timestamptz language sql stable as $$ select now() $$;
grant execute on function public.server_now() to anon, authenticated;
