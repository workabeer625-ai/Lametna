<div dir="rtl">

# البنية المعمارية · Architecture

## 1. المبدأ الحاكم: الخادم هو الحَكَم

القاعدة التي بُني عليها كل شيء:

> **العميل يعرض ويطلب. الخادم يقرّر ويُعلن.**

لا يستطيع التطبيق — حتى لو عُدِّل أو أُعيدت هندسته — أن:

| الشيء | أين يُقرَّر | لماذا |
|-------|------------|-------|
| توزيع أدوار المافيا | `start_game()` في Postgres | العميل لا يرى إلا دوره هو (RLS) |
| احتساب النقاط | `resolve_round()` + `_award()` | جداول النقاط لا تقبل كتابة من `authenticated` |
| نتيجة التصويت | `resolve_round()` | العميل يرى الأصوات بعد الحسم فقط |
| انتهاء وقت الجولة | `rounds.ends_at` + `server_now()` | مؤقّت الجهاز عرض فقط |
| كلمة مرور الغرفة | bcrypt في `rooms.password_hash` | `REVOKE SELECT` على العمود |
| الكلمة السرية للكذاب | `rounds.secret_data` | تُقرأ فقط عبر `my_round_secret()` |

## 2. المخطط العام

```
┌──────────────────────── الهاتف ────────────────────────┐
│  Flutter · Material 3 · RTL/LTR                         │
│                                                          │
│  features/  ← شاشات وودجات (لا منطق أعمال)              │
│      ↕                                                   │
│  providers/ ← Riverpod: حالة + تنسيق                     │
│      ↕                                                   │
│  services/  ← supabase · realtime · connectivity        │
│      ↕                                                   │
│  models/    ← تحويل JSON ↔ كائنات (بلا توليد كود)        │
└───────────────┬──────────────────────┬───────────────────┘
                │ RPC (HTTPS)          │ WebSocket
                ▼                      ▼
┌──────────────────────── Supabase ───────────────────────┐
│  PostgREST  →  دوال SECURITY DEFINER  →  Postgres + RLS  │
│  Realtime   →  بث تغييرات الجداول (يحترم RLS)            │
│  Auth       →  بريد/كلمة مرور + مجهول (ضيف)              │
│  Edge Funcs →  tick-rounds · cleanup-rooms · resolve     │
│  pg_cron    →  يستدعي دوال الحافة كل 10 ثوانٍ / 15 دقيقة │
└──────────────────────────────────────────────────────────┘
```

## 3. طبقات التطبيق

### `lib/core/` — لا يعتمد على أي شيء

- `constants/app_constants.dart` — اسم التطبيق، الشعار، مفاتيح الألعاب، الفئات، الصور الرمزية.
- `network/env.dart` — يقرأ `SUPABASE_URL` / `SUPABASE_ANON_KEY` من `--dart-define`، ويكشف `isConfigured`.
- `errors/` — `AppException` + `ErrorMapper` الذي يحوّل أكواد الخادم (`ROOM_FULL`, `MUTED`, …) إلى نص مترجم.
- `storage/` — `LocalPrefs` (تفضيلات) و `SecureStore` (لا يُستخدم لأسرار الخادم).
- `utils/` — `Validators`، `ContentFilter` (تصفية مبدئية في العميل، والخادم يعيدها)، `ServerClock`.
- `widgets/` — `AppAvatar`، `CountdownBar`، `StateViews`، `ConnectionBanner`، `SectionCard`.

### `lib/models/` — بيانات فقط

12 نموذجًا غير قابل للتعديل مع `fromMap`. لا `freezed` ولا `json_serializable`:
لا خطوة توليد، لا ملفات `.g.dart`، بناء أسرع، وقراءة أوضح لمن يفتح المشروع لأول مرة.

نقطة مهمة: `Profile.toUpdateMap()` **لا يُضمِّن** `total_points` أو `games_won` أو `role` —
حتى لو حاول العميل، فمشغّل `tg_protect_profile_stats` يعيد القيم القديمة.

### `lib/services/` — الحدود مع العالم الخارجي

- `SupabaseService` — غلاف رقيق فوق `supabase_flutter`: كل استدعاء RPC في مكان واحد، مع تحويل الأخطاء.
- `RealtimeService` — إدارة قنوات الغرفة، إعادة الاشتراك بعد الانقطاع، و`presence` لحالة الاتصال.
- `ConnectivityService` — مراقبة الشبكة لإظهار `ConnectionBanner` و `/no-internet`.

### `lib/providers/` — الحالة

Riverpod فقط. أهمها:

| الموفّر | المسؤولية |
|---------|-----------|
| `authStateProvider` | جلسة Supabase + الملف الشخصي |
| `settingsProvider` | اللغة، الثيم، الإشعارات، إظهار الدولة (محفوظة محليًا) |
| `roomProvider(roomId)` | الغرفة + اللاعبون + الرسائل، مُحدَّثة لحظيًا |
| `gameProvider(roomId)` | الجلسة + الجولة الحالية + إجاباتي + دوري |
| `leaderboardProvider` | المتصدّرون حسب النطاق والمدة |
| `serverClockProvider` | فارق ساعة الجهاز عن الخادم |

### `lib/features/` — الشاشات

كل ميزة مجلد مستقل تحته `presentation/`. لا شاشة وهمية ولا زر بلا وظيفة.

```
auth/        splash · language · welcome · sign_in · sign_up · profile_setup
home/        home_shell (شريط سفلي) · home · games_list
rooms/       create_room · join_room · public_rooms · room (اللوبي + اللعب)
games/       engine/ · shared/ · 8 واجهات لعب · presentation/ (نتيجة الجولة + نهاية المباراة)
profile/     profile_screen
leaderboard/ leaderboard_screen
settings/    settings_screen
legal/       privacy · terms · rules
common/      no_internet · disconnected · error · not_found · missing_config
```

## 4. محرّك الألعاب (Game Engine)

الفكرة: `room_screen.dart` واحد يشغّل **كل** الألعاب. ما يختلف هو `GameDefinition`.

```dart
abstract class GameDefinition {
  String get key;                      // 'mafia'
  int get minPlayers;
  int get maxPlayers;
  bool get usesVoting;

  /// واجهة الجولة الحالية بحسب prompt.stage
  Widget buildPlayView(GameViewContext ctx);

  /// لوحة نتيجة مخصّصة (اختياري — وإلا تُستخدم اللوحة الافتراضية)
  Widget? buildResultView(GameViewContext ctx) => null;
}
```

`GameViewContext` يحمل: الغرفة، اللاعبين، الجلسة، الجولة، إجابتي، دوري، المتبقّي من الوقت،
ودوالّ الإجراءات (`submitAnswer`, `castVote`, `submitMafiaAction`).

إضافة لعبة تاسعة = ثلاث خطوات:

1. صف في `games` + محتوى في `questions` (SQL).
2. فرع في `_begin_round()` و `resolve_round()` (SQL) — القواعد والنقاط.
3. ملف `GameDefinition` جديد مع واجهته، وتسجيله في السجل.

لا تغيير في الراوتر ولا في `room_screen`.

### مراحل الجولة (`prompt.stage`)

`answer` · `describe` · `write` · `vote` · `night` · `day`

الواجهة تختار الودجت بحسب المرحلة، والخادم هو من ينقل المرحلة عند `resolve_round()`.

## 5. دورة حياة الغرفة

```
create_room ──▶ waiting ──(start_game)──▶ starting ──▶ playing
                  ▲                                      │
                  │                        resolve_round │ (لكل جولة)
                  │                                      ▼
              play_again ◀────── finished ◀── آخر جولة / شرط فوز
                                    │
                        abort_game / خمول ──▶ cancelled
```

- الغرفة تُغلق تلقائيًا بعد 3 ساعات خمول أو عبر `cleanup_stale_rooms()`.
- انسحاب المضيف ينقل الاستضافة لأقدم لاعب متصل (`transfer_host` ضمنيًا).
- `heartbeat(room)` كل 20 ثانية يحدّث `last_seen_at`؛ من ينقطع يُعلَّم `disconnected` ولا يُطرد فورًا.

## 6. الساعة الموثوقة

مشكلة: ساعة الهاتف قد تكون خاطئة بدقائق.

الحل:

1. الخادم يكتب `rounds.ends_at` (timestamptz).
2. العميل ينادي `server_now()` عند الاتصال وبعد كل إعادة اتصال، ويحفظ الفارق في `ServerClock`.
3. `CountdownBar` يعرض `endsAt - (now + offset)`، بحد أدنى صفر.
4. **العميل لا ينهي الجولة.** `tick-rounds` (كل 10 ثوانٍ عبر pg_cron) ينهيها على الخادم حتى لو
   أغلق كل اللاعبين التطبيق.
5. تفاؤليًا: أول عميل يرى الوقت انتهى ينادي `resolve_round()`؛ الدالة ذاتية التكرار (idempotent)
   فلا ضرر من نداءات متزامنة.

## 7. الوقت الحقيقي

قناة واحدة لكل غرفة: `room:{roomId}`، تشترك في تغييرات `rooms`, `room_players`, `messages`,
`game_sessions`, `rounds`, `answers`, `votes` المقيّدة بـ `room_id` / `session_id`.

Realtime يحترم RLS: اللاعب لا يستقبل صفًا لا يحق له قراءته — لذلك أدوار المافيا وإجابات
الآخرين قبل الحسم لا تصل إليه أصلًا عبر السلك. التفاصيل في [REALTIME.md](REALTIME.md).

## 8. الترجمة

`AppLocalizations` يدوي فوق خريطتي `Map<String, String>` (`strings_ar.dart` / `strings_en.dart`)
بأكثر من 300 مفتاح متطابقة. سبب تجنّب `gen_l10n`: لا خطوة توليد، واختبار واحد
(`test/unit/localization_test.dart`) يضمن تطابق المفاتيح وعدم وجود قيمة فارغة.

الاتجاه يُشتق من اللغة: `ar → rtl`, `en → ltr`، ويُطبَّق على مستوى `MaterialApp`.

## 9. قرارات ومقايضات

| القرار | البديل المرفوض | السبب |
|--------|----------------|-------|
| Supabase وحده | Supabase + Firebase | خلط المنصّات يضاعف التعقيد والكلفة والمخاطر |
| منطق اللعب في SQL | منطق في Edge Functions | أقرب للبيانات، معاملات ذرّية، بلا زمن بارد (cold start) |
| بلا توليد كود | freezed + json_serializable | لا `build_runner`، بناء أسرع، مشروع أسهل على المبتدئ |
| صور رمزية محلية | رفع صور إلى Storage | مجاني، سريع، وخصوصية أعلى (ولا حاجة لفحص محتوى الصور) |
| ترجمة يدوية | gen_l10n | خطوة أقل، واختبار يحمي التطابق |
| `android/` مُولَّد لا مُتتبَّع | حفظ المجلد في Git | يتجنّب تعارضات نسخ Gradle، والتخصيصات في `tool/android_overrides/` |

</div>
