<div dir="rtl">

# الوقت الحقيقي · Realtime

الوقت الحقيقي في «لمّتنا» مبني على **Supabase Realtime** (WebSocket واحد لكل جهاز)،
مع ثلاث آليات متكاملة:

1. **Postgres Changes** — بث `INSERT/UPDATE/DELETE` للجداول المعنية.
2. **Presence** — من متصل الآن في الغرفة.
3. **الساعة الموثوقة** — `server_now()` + `rounds.ends_at`.

---

## 1. لماذا Postgres Changes لا الرسائل المخصّصة؟

لأن Realtime في Supabase **يحترم RLS**: المشترك لا يستلم إلا الصفوف التي يحق له قراءتها.
هذا يعني أن سرّية أدوار المافيا وإجابات الآخرين محفوظة **على مستوى السلك نفسه**، لا بإخفاء
في الواجهة. لو استخدمنا بثًا مخصصًا (broadcast) لكان علينا تصفية المحتوى يدويًا لكل مستلم،
وهو مصدر أخطاء أمنية.

## 2. قناة الغرفة

قناة واحدة لكل غرفة: `room:{roomId}`، يديرها `lib/services/realtime_service.dart`.

| الجدول | المرشّح | ما يصل |
|--------|---------|--------|
| `rooms` | `id=eq.{roomId}` | تغيّر الحالة، المضيف، الإعدادات |
| `room_players` | `room_id=eq.{roomId}` | انضمام، مغادرة، جاهزية، كتم، حياة/موت |
| `messages` | `room_id=eq.{roomId}` | الدردشة (والقنوات المسموحة لي فقط) |
| `game_sessions` | `room_id=eq.{roomId}` | بدء/انتهاء المباراة |
| `rounds` | `session_id=eq.{sessionId}` | جولة جديدة، تغيّر المرحلة، الحسم |
| `answers` | `round_id=eq.{roundId}` | إجابتي، وإجابات الآخرين بعد الحسم |
| `votes` | `round_id=eq.{roundId}` | الأصوات حسب سياسة اللعبة |

الاشتراك بـ `rounds` و `answers` و `votes` يُعاد ضبطه عند تغيّر الجلسة/الجولة، حتى لا تبقى
مرشّحات ميتة تستهلك اتصالات.

```dart
channel = supabase.channel('room:$roomId')
  ..onPostgresChanges(
      event: PostgresChangeEvent.all, schema: 'public', table: 'room_players',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq, column: 'room_id', value: roomId),
      callback: _onPlayersChanged)
  // …
  ..subscribe();
```

## 3. Presence — من متصل الآن

كل عميل يبثّ `{ user_id, nickname, joined_at }` على القناة نفسها.
الفائدة: معرفة الانقطاع خلال ثوانٍ بدل انتظار مهلة نبضة القلب.

مهم: Presence **تلميح واجهة فقط**. الحقيقة الرسمية هي `room_players.state` و `last_seen_at`
التي يكتبها `heartbeat()` على الخادم. لو اختلفا، الخادم هو المرجع.

## 4. الساعة الموثوقة والمؤقّت

المشكلة: ساعة الهاتف قد تنحرف دقائق، ولا يجوز أن تحدّد نهاية الجولة.

```
1) الخادم يكتب rounds.ends_at  (timestamptz، UTC)
2) العميل ينادي server_now() عند الإقلاع وبعد كل إعادة اتصال
3) offset = serverNow - deviceNow    ← يُحفظ في ServerClock
4) العرض: remaining = ends_at - (deviceNow + offset)، وبحد أدنى صفر
5) عند بلوغ الصفر: العميل يحاول resolve_round() (تفاؤليًا)
6) وبالتوازي: tick-rounds كل 10 ثوانٍ يحسم على الخادم
```

النقطة 6 هي الضمانة: لو أغلق **كل** اللاعبين التطبيق في منتصف الجولة، تُحسم الجولة وتنتهي
المباراة بشكل سليم، ولا تبقى غرفة معلّقة إلى الأبد.

`resolve_round()` ذاتية التكرار، فلا ضرر إن نادتها عشرة عملاء في اللحظة نفسها.

## 5. إعادة الاتصال

```
انقطاع الشبكة
   ↓
ConnectivityService يرفع العلم → ConnectionBanner يظهر أعلى الشاشة
   ↓
Realtime يعيد المحاولة تلقائيًا (تراجع أسّي)
   ↓
عند العودة:
   • server_now()      ← إعادة ضبط الفارق
   • إعادة جلب كاملة للغرفة والجلسة والجولة (لا نثق بالفجوة)
   • heartbeat()       ← أعود connected
   • إعادة الاشتراك بالقناة
```

القاعدة: **بعد أي انقطاع، أعد الجلب الكامل ثم استأنف البث.** الاعتماد على الأحداث وحدها
يترك ثغرات في الفترة المنقطعة.

اللاعب المنقطع لا يُطرد: يُعلَّم `disconnected` ويبقى مكانه ونقاطه حتى نهاية المباراة أو
حتى تُغلق الغرفة بالخمول.

## 6. حدود الخطة المجانية

| الحد | القيمة | كيف نلتزم به |
|------|--------|--------------|
| اتصالات لحظية متزامنة | 200 | قناة **واحدة** لكل جهاز لا واحدة لكل جدول |
| رسائل Realtime شهريًا | 2 مليون | مرشّحات ضيقة، وإلغاء الاشتراك فور مغادرة الشاشة |
| حجم القاعدة | 500 ميغابايت | حذف الرسائل الأقدم من 7 أيام والغرف المغلقة |

عمليًا: 200 اتصال ≈ 20–40 غرفة نشطة في اللحظة نفسها. تفاصيل التوسّع في
[FREE_HOSTING.md](FREE_HOSTING.md).

## 7. التفعيل في قاعدة البيانات

الترحيل `0011` يضيف الجداول إلى منشور `supabase_realtime`:

```sql
alter publication supabase_realtime add table public.rooms;
alter publication supabase_realtime add table public.room_players;
alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.game_sessions;
alter publication supabase_realtime add table public.rounds;
alter publication supabase_realtime add table public.answers;
alter publication supabase_realtime add table public.votes;
```

ويضبط `replica identity full` حيث يلزم لوصول القيم القديمة في أحداث التحديث.

> إعادة تشغيل هذا الترحيل على قاعدة مهيّأة سترفع خطأ «الجدول مضاف مسبقًا» — متوقّع وغير ضار.

## 8. تنقيح الأخطاء

```dart
// في main.dart أثناء التطوير
Supabase.initialize(url: …, anonKey: …, realtimeClientOptions:
    const RealtimeClientOptions(logLevel: RealtimeLogLevel.info));
```

- لوحة Supabase → Database → Replication: تأكد من وجود الجداول في المنشور.
- لا تصل أحداث؟ غالبًا RLS يمنع القراءة — جرّب نفس الاستعلام من التطبيق أولًا.
- تصل أحداث مكرّرة؟ اشتراك قديم لم يُلغَ — تحقق من `dispose()` في الموفّر.

</div>
