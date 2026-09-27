<div dir="rtl">

# واجهة البرمجة · API

لا يوجد خادم REST مكتوب بخط اليد. كل شيء عبر **PostgREST** الذي يكشف دوال Postgres
كنقاط نهاية `POST /rest/v1/rpc/<function>`، ومن Flutter عبر `supabase.rpc('name', params: {...})`.

كل الدوال أدناه `SECURITY DEFINER` وتتحقق من `auth.uid()` بنفسها، وممنوحة لدور `authenticated`
فقط (باستثناء ما هو معلَّم بـ 🌐 فمتاح لـ `anon` أيضًا).

> الاستدعاء من Flutter مركزيّ في `lib/services/supabase_service.dart`، وتحويل الأخطاء في
> `lib/core/errors/error_mapper.dart`.

---

## 1. الغرف

### `create_room` → `rooms`

| المعامل | النوع | الافتراضي |
|---------|------|-----------|
| `p_game_key` | text | — |
| `p_is_public` | boolean | `true` |
| `p_password` | text | `null` (يُخزَّن bcrypt) |
| `p_title` | text | `''` (≤ 48 حرفًا) |
| `p_max_players` | int | حد اللعبة |
| `p_settings` | jsonb | `{}` |
| `p_locale` | text | `'ar'` |

ينشئ الغرفة برمز فريد، ويضيف المنشئ مضيفًا وجاهزًا.
أخطاء: `AUTH_REQUIRED` · `USER_BANNED` · `GAME_NOT_FOUND` · `TOO_MANY_ROOMS` · `ROOM_CODE_EXHAUSTED`

### `join_room(p_code, p_password, p_as_spectator)` → `rooms`

الرمز غير حسّاس لحالة الأحرف. المتفرّج ينضم حتى أثناء اللعب.
أخطاء: `ROOM_NOT_FOUND` · `ROOM_CLOSED` · `ROOM_BANNED` · `WRONG_PASSWORD` · `ROOM_FULL` · `GAME_IN_PROGRESS` · `USER_BANNED`

### `leave_room(p_room)` → void

يضع `left_at`، وينقل الاستضافة تلقائيًا إن كان المغادر هو المضيف، ويغلق الغرفة إن فرغت.

### `heartbeat(p_room)` → void

كل 20 ثانية. يحدّث `last_seen_at` و `last_activity_at`.

### `set_ready(p_room, p_ready)` → void

### `transfer_host(p_room, p_new_host)` → void
أخطاء: `NOT_HOST` · `TARGET_NOT_MEMBER`

### `list_public_rooms(p_game_key, p_limit)` → جدول

يعيد: `id, code, title, game_key, status, player_count, max_players, has_password, host_nickname, created_at`.
**لا يعيد `password_hash` إطلاقًا** — فقط العلم المنطقي `has_password`.

## 2. الدردشة والإشراف

### `send_message(p_room, p_body, p_channel)` → `messages`

`p_channel` ∈ `public | mafia | dead`. الطول 1–300. يفرض: كتم، حجب روابط، قاموس الألفاظ،
وحدّ معدّل (رسالة كل ثانيتين تقريبًا).
أخطاء: `NOT_A_MEMBER` · `MUTED` · `BAD_LENGTH` · `LINKS_NOT_ALLOWED` · `BLOCKED_CONTENT` · `RATE_LIMITED` · `BAD_CHANNEL` · `DEAD_CANNOT_SPEAK` · `NOT_MAFIA`

### `kick_player(p_room, p_user)` · `ban_player(p_room, p_user, p_reason)` · `mute_player(p_room, p_user, p_muted)`

للمضيف أو المشرف. كلها تكتب في `audit_logs`.
أخطاء: `NOT_HOST` · `CANNOT_KICK_SELF` · `CANNOT_BAN_SELF` · `TARGET_NOT_MEMBER`

### `block_user(p_user, p_blocked)` → void

حجب شخصي: لا أرى رسائله ولا يراني في القوائم العامة. لا يحتاج صلاحية.

### `report_user(p_reported, p_reason, p_room, p_message_id, p_details)` → void

`p_reason` ∈ `abuse | racism | sectarian | bullying | incitement | profanity | doxxing | impersonation | spam | other`.
فهرس فريد يمنع تكرار البلاغ نفسه وهو `open`.
أخطاء: `CANNOT_REPORT_SELF` · `BAD_LENGTH`

## 3. اللعب

### `start_game(p_room, p_rounds, p_config)` → `game_sessions`

للمضيف فقط. يتحقق من العدد والجاهزية، ينشئ الجلسة، **يوزّع أدوار المافيا على الخادم**،
ويبدأ الجولة الأولى بـ `ends_at` محسوب.
أخطاء: `NOT_HOST` · `ALREADY_STARTED` · `NOT_ENOUGH_PLAYERS` · `PLAYERS_NOT_READY` · `NO_CONTENT_FOR_GAME` · `UNKNOWN_GAME`

### `submit_answer(p_round, p_payload)` → void

`p_payload` حسب اللعبة:

```jsonc
// جماد حيوان نبات
{ "name": "أحمد", "animal": "أسد", "plant": "نعناع", "object": "طاولة", "country": "اليمن" }

// صح/خطأ · خمّن الكلمة · المثل · من أنا؟ · وصف الكذاب · سطر القصة
{ "value": "الذهب" }
```

يسجّل `elapsed_ms` لحساب مكافأة السرعة. إجابة واحدة لكل جولة ولا تُعدَّل.
**لا يُرجِع نقاطًا** — النقاط تُحسب عند الحسم فقط.
أخطاء: `ROUND_NOT_FOUND` · `TIME_OVER` · `NOT_ALIVE` · `SPECTATOR` · `ANSWER_TOO_LONG` · `ALREADY_SUBMITTED` · `NOT_IN_GAME`

### `cast_vote(p_round, p_kind, p_target_user, p_target_key, p_value)` → void

`p_kind` ∈ `lynch | best_answer | validate_answer | liar | story_line`.
أخطاء: `DEAD_CANNOT_VOTE` · `CANNOT_VOTE_SELF` · `TARGET_DEAD` · `TIME_OVER` · `SPECTATOR`

### `submit_mafia_action(p_round, p_action, p_target)` → jsonb

`p_action` ∈ `kill | heal | investigate | protect`. ليلًا فقط.
يعيد نتيجة التحقيق للمحقق فقط: `{"result":"mafia"}` أو `{"result":"citizen"}`، وغير ذلك `{}`.
أخطاء: `NOT_NIGHT` · `DEAD_CANNOT_ACT` · `ACTION_NOT_ALLOWED` · `TARGET_NOT_ALIVE` · `CANNOT_KILL_SELF` · `CANNOT_INVESTIGATE_SELF` · `ACTION_ALREADY_SUBMITTED`

### `resolve_round(p_round)` → jsonb

**قلب النظام.** ذاتية التكرار: إن كانت الجولة محسومة تعيد النتيجة المخزّنة دون إعادة حساب.
تحسب النقاط، تُطبّق نتائج المافيا، تمنح الشارات، تبدأ الجولة التالية أو تنهي المباراة.
يستدعيها: أول عميل يرى الوقت انتهى، أو `tick-rounds` كل 10 ثوانٍ.

### `abort_game(p_room)` · `play_again(p_room)` → void

للمضيف. `play_again` يعيد الغرفة إلى `waiting` ويصفّر الجاهزية.

### `my_mafia_role(p_room)` → jsonb

```json
{ "role": "mafia", "is_alive": true,
  "partners": [{ "user_id": "…", "nickname": "سالم" }] }
```
`partners` تُملأ للمافيا فقط. لا يمكن لأي لاعب قراءة دور غيره.

### `my_round_secret(p_round)` → jsonb

الجزء الذي يخصّني من `secret_data` — كلمة «الكذاب بيننا» مثلًا. للكذاب تعود `{"word": null, "is_liar": true}`.

## 4. المتصدّرون والملف الشخصي

### 🌐 `leaderboard(p_scope, p_period, p_game_key, p_limit)` → جدول

`p_scope` ∈ `global | arab | yemen` · `p_period` ∈ `week | month | all`.
يعيد: `rank, user_id, nickname, avatar_key, country_code, points, wins, games, level`.
النطاق «arab/yemen» يعتمد على `countries.region` ولا يمنع أحدًا من اللعب أو من الترتيب العالمي.

### `my_rank(p_scope, p_period)` → jsonb

### `delete_my_account()` → void

يغادر الغرف، يضع `deleted_at`، يُخفي الاسم والصورة والدولة، ويحذف الرسائل الشخصية.
سجلات النقاط تبقى مجهولة الهوية لسلامة الترتيب التاريخي.

### 🌐 `server_now()` → timestamptz

الساعة الموثوقة. ينادى عند الاتصال وبعد كل إعادة اتصال.

## 5. الإدارة

### `admin_stats()` → jsonb

`users_total, users_guests, users_new_7d, rooms_open, rooms_playing, sessions_24h, messages_24h, reports_open, bans_global, questions_total`
أخطاء: `FORBIDDEN`

### `admin_resolve_report(p_report, p_status, p_ban_days)` → void

`p_ban_days`: `null` بلا حظر · `0` حظر دائم · `n` حظر n يومًا.
أخطاء: `FORBIDDEN` · `NOT_FOUND`

## 6. دوال الحافة (Edge Functions)

| الدالة | من يستدعيها | ماذا تفعل |
|--------|-------------|-----------|
| `tick-rounds` | pg_cron كل 10 ثوانٍ | تحسم كل جولة تجاوزت `ends_at` |
| `cleanup-rooms` | pg_cron كل 15 دقيقة | تغلق الغرف الخاملة وتحذف الرسائل القديمة |
| `resolve-round` | العميل (اختياريًا) | حسم مبكّر عندما يجيب الجميع |

المهام المجدولة تتطلب الترويسة `x-cron-secret: $CLEANUP_CRON_SECRET` وإلا تعيد `401`.

## 7. الاستدعاء من Flutter

```dart
// إنشاء غرفة
final Room room = await supabaseService.createRoom(
  gameKey: GameKeys.mafia, isPublic: true, maxPlayers: 10,
);

// الانضمام
final Room room = await supabaseService.joinRoom(code: 'ABC123');

// إرسال إجابة
await supabaseService.submitAnswer(roundId: round.id,
    payload: <String, dynamic>{'value': text});

// حسم متفائل عند انتهاء الوقت
await supabaseService.resolveRound(round.id);
```

## 8. معالجة الأخطاء

الخادم يرفع `raise exception 'CODE'` وتصل إلى العميل كـ `PostgrestException`.
`ErrorMapper` يحوّل الكود إلى رسالة مترجمة؛ وأي كود غير معروف يصبح رسالة عامة
مع تسجيله في السجل. القائمة الكاملة للأكواد في `lib/core/errors/error_mapper.dart`
وتشمل: `AUTH_REQUIRED`, `USER_BANNED`, `ROOM_NOT_FOUND`, `ROOM_FULL`, `WRONG_PASSWORD`,
`GAME_IN_PROGRESS`, `NOT_HOST`, `MUTED`, `RATE_LIMITED`, `LINKS_NOT_ALLOWED`,
`BLOCKED_CONTENT`, `TIME_OVER`, `ALREADY_SUBMITTED`, `DEAD_CANNOT_VOTE`, `NOT_NIGHT`,
`FORBIDDEN` … إلخ.

</div>
