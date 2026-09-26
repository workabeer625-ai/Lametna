<div dir="rtl">

# قاعدة البيانات · Database

Postgres على Supabase. **24 جدولًا**، كلها في مخطط `public`، وكلها مفعّل عليها RLS.

ملفات الترحيل في `supabase/migrations/` وتُطبَّق بالترتيب:

| الملف | المحتوى |
|-------|---------|
| `0001_extensions_and_enums` | الامتدادات + 10 أنواع تعدادية |
| `0002_core_tables` | countries · avatars · profiles · guest_sessions · games · achievements · user_achievements |
| `0003_rooms` | rooms · room_players · messages |
| `0004_gameplay` | game_sessions · rounds · questions · answers · votes · mafia_roles · mafia_actions · scores |
| `0005_moderation` | reports · bans · user_blocks · notifications · audit_logs · banned_words |
| `0006_helpers` | دوال مساعدة (is_admin, is_room_member, normalize_ar, …) + مشغّلات |
| `0007_rpc_rooms` | دوال الغرف والدردشة والإشراف |
| `0008_rpc_gameplay` | بدء المباراة، الإجابات، التصويت، أفعال المافيا |
| `0009_rpc_resolve` | حسم الجولات واحتساب النقاط (قلب اللعبة) |
| `0010_rls` | سياسات RLS + سحب صلاحيات الأعمدة + منح تنفيذ الدوال |
| `0011_leaderboards_realtime` | المتصدّرون · إحصاءات الإدارة · النشر اللحظي · `server_now` |

---

## 1. الأنواع التعدادية

```sql
app_role          player | moderator | admin
room_status       waiting | starting | playing | paused | finished | cancelled
player_state      connected | disconnected | ready | not_ready | alive | dead | spectator | banned
session_status    pending | running | finished | aborted
round_phase       pending | collecting | voting | resolved
vote_kind         lynch | best_answer | validate_answer | liar | story_line
mafia_role        citizen | mafia | doctor | detective | guard
mafia_action_kind kill | heal | investigate | protect
report_status     open | reviewing | resolved | rejected
ban_scope         room | global
game_category     word | social | trivia | creative | deduction
```

## 2. خريطة العلاقات

```
auth.users ──1:1──▶ profiles ──┬──▶ room_players ──▶ rooms ──▶ games
                               ├──▶ messages
                               ├──▶ scores ──▶ game_sessions ──▶ rounds ──┬─▶ answers
                               ├──▶ user_achievements ──▶ achievements    ├─▶ votes
                               ├──▶ reports / bans / user_blocks          └─▶ mafia_actions
                               ├──▶ notifications                 mafia_roles ──▶ game_sessions
                               └──▶ guest_sessions
countries ◀── profiles.country_code      avatars ◀── profiles.avatar_key
questions ──▶ games
```

## 3. الجداول الأساسية

### `profiles` — الهوية

| العمود | النوع | ملاحظة |
|--------|------|--------|
| `id` | uuid PK | = `auth.users.id`، حذف متتالٍ |
| `nickname` | text | 2–24 حرفًا |
| `nickname_lower` | مُولَّد | للبحث غير الحسّاس لحالة الأحرف |
| `avatar_key` | FK → avatars | يطابق `assets/avatars/<key>.png` |
| `country_code` | FK → countries | **اختياري** |
| `show_country` | bool | افتراضيًا `false` |
| `role` | app_role | يحدّد صلاحية لوحة التحكم |
| `is_guest` | bool | حساب مجهول |
| `total_points` `games_played` `games_won` `win_streak` `best_streak` | int | **الخادم وحده يكتبها** |
| `level` | مُولَّد | `greatest(1, total_points/500 + 1)` |
| `deleted_at` | timestamptz | حذف ناعم |

يُنشأ تلقائيًا بمشغّل `tg_handle_new_user` على `auth.users`.
ويحميه `tg_protect_profile_stats`: أي محاولة من العميل لتعديل النقاط أو الدور تُرَدّ للقيمة القديمة.

### `rooms` — الغرفة

`code` نصّي فريد `^[A-Z0-9]{6}$` يولّده `generate_room_code()` متجنّبًا الحروف الملتبسة.
`password_hash` **bcrypt**، ومسحوب الصلاحية عن العميل (انظر §6).
`expires_at` افتراضيًا ثلاث ساعات، و`last_activity_at` يُحدَّث بـ `touch_room()` مع كل فعل.

### `room_players` — العضوية

مفتاح مركّب `(room_id, user_id)`. يحمل `state`, `is_ready`, `is_spectator`, `is_muted`,
`is_alive`, `seat`, `score`, `last_seen_at`, `left_at`.
`heartbeat()` كل 20 ثانية يحدّث `last_seen_at`، ومن تجاوز المهلة يصبح `disconnected` دون طرد.

### `rounds` — الجولة (الأهم أمنيًا)

| العمود | ملاحظة |
|--------|--------|
| `round_index` | تسلسل داخل الجلسة، فريد مع `session_id` (سُمّي هكذا لأن `index` كلمة محجوزة) |
| `prompt` | jsonb **عام**: الحرف، السؤال، التلميحات، `stage` |
| `secret_data` | jsonb **سرّي**: كلمة الكذاب، الحلول… — `REVOKE SELECT` عن العميل |
| `ends_at` | **مصدر الحقيقة للمؤقّت** |
| `result` | ملخّص الحسم بعد `resolve_round()` |

### `questions` — المحتوى

`body` + `answer` + `alt_answers[]` (روايات ولهجات) + `choices` (للاختياري) + `hints[]`.
`region` ∈ `yemen | arab | global` لاختيار محتوى مناسب.
`answer` و `alt_answers` مسحوبتا الصلاحية عن العميل حتى لا تُقرأ الإجابات مسبقًا.

### `mafia_roles` — الأدوار السرّية

مفتاح مركّب `(session_id, user_id)`. سياسة RLS تسمح للاعب بقراءة **صفّه فقط**،
وبعد انتهاء المباراة يُرفع `revealed` فتظهر الأدوار للجميع.

## 4. الجداول المساعدة والإشراف

| الجدول | الوظيفة |
|--------|---------|
| `guest_sessions` | ربط الضيف بجهاز مجهول، صلاحية 30 يومًا |
| `messages` | 1–300 حرفًا، قنوات `public | mafia | dead`، `is_hidden` للإخفاء الإشرافي |
| `answers` | فريد لكل `(round_id, user_id)` — إجابة واحدة لا تُعدَّل |
| `votes` | فريد لكل `(round_id, voter_id, kind, target_key)` |
| `mafia_actions` | فريد لكل `(round_id, actor_id, action)` |
| `scores` | سجل النقاط لكل جلسة (مصدر المتصدّرين) |
| `achievements` / `user_achievements` | الشارات ومنحها |
| `reports` | بلاغات مع فهرس فريد يمنع التكرار أثناء `open` |
| `bans` | `room` أو `global`، مؤقّت أو دائم |
| `user_blocks` | حجب شخصي متبادل الاتجاه الواحد |
| `notifications` | إشعارات داخل التطبيق (ثنائية اللغة) |
| `audit_logs` | كل فعل إشرافي وحسّاس |
| `banned_words` | قاموس التصفية، قابل للتحديث بلا إصدار جديد |

## 5. الفهارس المهمة

```sql
rooms (code) unique                        -- الانضمام بالرمز
rooms (is_public, status, last_activity_at desc) where closed_at is null
room_players (user_id) where left_at is null
messages (room_id, created_at desc)
rounds (session_id, round_index) unique
answers (round_id, user_id) unique
votes (round_id, voter_id, kind, target_key) unique
scores (user_id, created_at desc) · scores (game_key, created_at desc)
reports (status, created_at desc)
audit_logs (created_at desc) · (actor_id, created_at desc)
```

## 6. الأمان على مستوى الصفوف والأعمدة

RLS مفعّل على **كل** الجداول. القاعدة العامة: العميل يقرأ ما يخصّه أو ما يخص غرفة هو عضو فيها،
ويكتب عبر الدوال فقط.

أمثلة:

```sql
-- لا أحد يرى دور غيره في المافيا قبل النهاية
create policy mafia_roles_self on public.mafia_roles for select
  using (user_id = auth.uid() or revealed or public.is_admin());

-- الرسائل: أعضاء الغرفة فقط، مع احترام القنوات والحجب الشخصي
create policy messages_read on public.messages for select
  using (public.is_room_member(room_id) and not is_hidden and ...);
```

RLS لا يخفي **أعمدة**، لذلك استُخدم سحب الصلاحية على مستوى العمود — و PostgREST يحترمه:

```sql
revoke select (password_hash) on public.rooms      from anon, authenticated;
revoke select (secret_data)   on public.rounds     from anon, authenticated;
revoke select (answer, alt_answers) on public.questions from anon, authenticated;
```

كما أن جداول `scores`, `answers.points`, `profiles.total_points` غير قابلة للكتابة من العميل إطلاقًا:
لا سياسة `insert/update` لها، والكتابة تتم داخل دوال `SECURITY DEFINER`.

## 7. المشغّلات والدوال المساعدة

| الاسم | الدور |
|-------|------|
| `tg_handle_new_user` | ينشئ ملفًا شخصيًا مع كل مستخدم جديد (بما فيهم الضيوف) |
| `tg_protect_profile_stats` | يمنع العميل من تعديل النقاط/الدور/الإحصاءات |
| `tg_set_updated_at` | يحدّث `updated_at` |
| `is_admin()` `is_room_member()` `is_room_host()` `is_globally_banned()` | فحوص الصلاحية |
| `normalize_ar(text)` | يزيل التشكيل والتطويل ويوحّد الألف والياء والتاء المربوطة |
| `answer_matches(given, answer, alt[], fuzzy)` | مطابقة الإجابات، وبالتشابه الثلاثي ≥ 0.72 عند `fuzzy` |
| `contains_link()` `contains_banned_word()` `is_clean_text()` | التصفية |
| `generate_room_code()` | رمز غرفة فريد |
| `touch_room()` | تحديث النشاط |
| `log_audit()` | كتابة سجل العمليات |
| `cleanup_stale_rooms()` | إغلاق الغرف الخاملة وحذف القديم (تُستدعى من دالة الحافة) |

## 8. البيانات الأولية (`seed.sql`)

- **18 لعبة** بأسمائها ووصفها بالعربية والإنجليزية وحدودها الافتراضية.
- **12 صورة رمزية** مطابقة لملفات `assets/avatars/`.
- **الدول** مع الأعلام، وعلامة `region = 'arab'` للدول العربية.
- **أسئلة** لكل لعبة: أمثال يمنية وعربية، عبارات صح/خطأ، كلمات للتخمين، شخصيات «من أنا؟».
- **الشارات**: أول فوز، ملك المافيا، الأسرع، كاتب القصة، كذّاب محترف… إلخ.
- **قاموس الكلمات الممنوعة** بالعربية والإنجليزية.

البيانات الأولية آمنة للتكرار (`on conflict do nothing / do update`).

## 9. أوامر التشغيل

```bash
supabase db push        # تطبيق الترحيلات على المشروع المرتبط
supabase db reset       # محليًا: إعادة البناء من الصفر + seed
supabase db diff -f name_of_change   # توليد ترحيل جديد من التغييرات المحلية
```

> ⚠️ `0011` يضيف الجداول إلى منشور `supabase_realtime` عبر `alter publication … add table`،
> وهذه العملية ليست ذاتية التكرار: إعادة تشغيلها على قاعدة مهيّأة سترفع خطأ «الجدول مضاف مسبقًا».
> هذا متوقّع وغير ضار؛ تجاهله أو احذف الجداول من المنشور قبل إعادة التشغيل.

</div>
