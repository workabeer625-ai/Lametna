-- ============================================================
-- لمّتنا / Lametna — 0014 إصلاح زر «أنا جاهز»
--
-- الخطأ:  column "state" is of type player_state but expression is of type text  (42804)
-- السبب:  تعبير case بفرعين نصيّين ينتج نوع text، وعمود state من نوع
--         player_state، وPostgres لا يحوّل تلقائيًا في هذه الحالة.
-- الحل:   تحويل صريح  ::player_state
-- ============================================================

create or replace function public.set_ready(p_room uuid, p_ready boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_room_member(p_room) then raise exception 'NOT_A_MEMBER'; end if;
  update public.room_players
     set is_ready = p_ready,
         state = (case when p_ready then 'ready' else 'not_ready' end)::player_state,
         last_seen_at = now()
   where room_id = p_room and user_id = auth.uid() and left_at is null and not is_spectator;
  perform public.touch_room(p_room);
end $$;
