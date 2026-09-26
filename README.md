<div dir="rtl">

# لمّتنا · Lametna

> **لمّتنا تجمعنا… واللعبة تبدأ هنا**

تطبيق ألعاب جماعية نصية بالوقت الحقيقي — للأصدقاء والعائلة في اليمن والوطن العربي والعالم.
تكتب، تصوّت، تخمّن، تضحك. **بدون كاميرا، بدون ميكروفون، بدون صوت أو فيديو — إطلاقًا.**

[![Flutter](https://img.shields.io/badge/Flutter-3.22%2B-blue)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Free%20Tier-3ecf8e)](https://supabase.com)
[![License](https://img.shields.io/badge/license-MIT-green)](#الرخصة)

---

## المحتويات

- [ما هو لمّتنا؟](#ما-هو-لمتنا)
- [الألعاب الثماني عشرة](#الألعاب-الثماني-عشرة)
- [لماذا نصي فقط؟](#لماذا-نصي-فقط)
- [التقنيات](#التقنيات)
- [البدء السريع](#البدء-السريع)
- [إعداد Supabase](#إعداد-supabase)
- [التشغيل](#التشغيل)
- [بناء الإصدار](#بناء-الإصدار)
- [الاختبارات](#الاختبارات)
- [هيكل المشروع](#هيكل-المشروع)
- [الوثائق](#الوثائق)
- [الخصوصية والأمان](#الخصوصية-والأمان)
- [حدود الخطة المجانية](#حدود-الخطة-المجانية)

---

## ما هو لمّتنا؟

«لمّتنا» تطبيق جوال (Android أولًا، iOS جاهز) يجمع من 3 إلى 12 لاعبًا في **غرفة** لها رمز من ست خانات.
يختار المضيف لعبة، ويلعب الجميع في جولات محسوبة الوقت على الخادم، مع دردشة نصية ولوحة نقاط
ومتصدّرين وشارات إنجاز.

- **العربية أولًا** بواجهة RTL كاملة، والإنجليزية LTR بضغطة زر.
- اسم مستعار + صورة رمزية جاهزة. **لا رفع صور شخصية، ولا بيانات حساسة.**
- الدولة والعَلَم اختياريان تمامًا، ولا يترتب على اختيارهما أي تمييز في اللعب أو الترتيب.
- دخول كضيف بنقرة واحدة، أو حساب بالبريد لحفظ النقاط عبر الأجهزة.

## الألعاب الثماني عشرة

| # | اللعبة | المفتاح | اللاعبون | الفكرة |
|---|--------|---------|----------|--------|
| 1 | جماد حيوان نبات | `animal_plant_object` | 2–12 | حرف عشوائي وفئات، والأسرع والأندر يكسب أكثر |
| 2 | المافيا | `mafia` | 5–12 | ليل ونهار، أدوار سرية يوزّعها الخادم، تصويت وإقصاء |
| 3 | من أنا؟ | `who_am_i` | 2–12 | تلميحات متتابعة وأول من يخمّن الشخصية يفوز |
| 4 | صح أم خطأ | `true_false` | 2–12 | عبارات سريعة، والسرعة تعطي نقاطًا إضافية |
| 5 | خمّن الكلمة | `guess_word` | 2–12 | تعريف أو لغز، والمطابقة المرنة تقبل الفروق البسيطة |
| 6 | الكذاب بيننا | `liar` | 4–12 | الجميع لديهم كلمة، إلا واحدًا؛ صِفوا ثم صوّتوا |
| 7 | أكمل المثل | `proverbs` | 2–12 | أمثال عربية ويمنية، ورواياتها البديلة مقبولة |
| 8 | القصة الجماعية | `group_story` | 3–12 | كل لاعب يكتب سطرًا، ثم تصويت على أفضل سطر |
| 9 | عواصم ودول | `capitals` | 2–16 | اختيار من متعدد عن عواصم العالم والوطن العربي |
| 10 | أعلام الدول | `flags` | 2–16 | شاهد العَلَم واختر الدولة |
| 11 | ألغاز وفوازير | `riddles` | 2–12 | فوازير شعبية بتلميحات تظهر تدريجيًا |
| 12 | معلومات دينية | `islamic` | 2–16 | القرآن والسيرة والفقه المبسّط |
| 13 | رياضة | `sports` | 2–16 | كرة قدم وبطولات ولاعبون |
| 14 | تاريخ وحضارة | `history` | 2–16 | تاريخ اليمن والعرب والعالم |
| 15 | إيموجي ولّغز | `emoji_puzzle` | 2–12 | رموز تعبيرية تخفي كلمة أو مثلًا |
| 16 | حساب سريع | `fast_math` | 2–16 | عمليات بسيطة والأسرع يكسب |
| 17 | المهنة السرية | `secret_job` | 4–12 | كالكذاب، لكن بمهنة بدل كلمة |
| 18 | أفضل جواب | `best_answer` | 3–12 | سؤال مفتوح، ثم تصويت على أفضل إجابة |

التفاصيل الدقيقة للنقاط والمؤقتات في **[docs/GAME_RULES.md](docs/GAME_RULES.md)**.

## لماذا نصي فقط؟

قرار تصميمي مقصود، لا نقص في الميزات:

- **الخصوصية**: لا صوت ولا صورة يعني لا تسريب ولا إحراج ولا تسجيل.
- **الشمول**: يعمل على شبكات ضعيفة وهواتف قديمة — مهم جدًا في اليمن وأماكن كثيرة.
- **الكلفة**: النص أرخص ألف مرة من الوسائط، فيبقى التطبيق مجانيًا فعلًا.
- **السلامة**: تصفية النصوص آليًا ممكنة؛ تصفية الصوت الحي ليست كذلك.

ملف `AndroidManifest.xml` يطلب `INTERNET` و `ACCESS_NETWORK_STATE` فقط، ويُزيل صراحةً
أي صلاحية `CAMERA` أو `RECORD_AUDIO` قد تضيفها مكتبة تابعة.

## التقنيات

| الطبقة | الاختيار | لماذا |
|--------|----------|-------|
| الواجهة | Flutter 3.22+ · Material 3 | تطبيق واحد لأندرويد و iOS |
| إدارة الحالة | Riverpod | بسيط، قابل للاختبار، بلا توليد كود |
| التنقّل | GoRouter | مسارات معلنة + إعادة توجيه حسب الجلسة |
| الخلفية | **Supabase** (Postgres · Auth · Realtime · Edge Functions) | خطة مجانية سخية، ومنصّة واحدة بلا خلط |
| منطق اللعب | دوال Postgres بصلاحية `SECURITY DEFINER` | **الخادم هو الحَكَم** في كل شيء |
| المهام المجدولة | Edge Functions + pg_cron | إنهاء الجولات وتنظيف الغرف بلا اعتماد على العميل |
| التخزين المحلي | SharedPreferences + flutter_secure_storage | تفضيلات فقط؛ لا أسرار في الكود |

> **منصّة واحدة فقط.** لا يوجد Firebase في هذا الإصدار ولا خلط بين المنصّات.

## البدء السريع

```bash
git clone https://github.com/workabeer625-ai/Lametna.git
cd Lametna

# يولّد مجلدات android/ و ios/ ثم يطبّق تخصيصات لمّتنا ويثبت الحزم
bash tool/bootstrap.sh
```

`tool/bootstrap.sh` ينفّذ `flutter create --platforms=android,ios .` لتوليد مجلدات المنصات
إن كانت ناقصة (يحفظ `pubspec.yaml` وأخواته ويعيدها، ولا يمس `lib/` إطلاقًا)، ثم ينسخ فوق
`android/` ملفات `tool/android_overrides/`: المانيفست بلا صلاحيات وسائط، اسم التطبيق «لمّتنا»،
إعدادات التوقيع و R8، وشاشة الإقلاع. آمن للتشغيل أكثر من مرة.

## إعداد Supabase

1. أنشئ مشروعًا مجانيًا على [supabase.com](https://supabase.com) واختر أقرب منطقة (مثلًا Frankfurt).
2. ارفع المخطط والبيانات الأولية:

   ```bash
   npm i -g supabase
   supabase login
   supabase link --project-ref YOUR-PROJECT-REF
   supabase db push          # 11 ملف ترحيل
   psql "$DATABASE_URL" -f supabase/seed.sql   # أو: supabase db reset محليًا
   ```

3. انشر دوال الحافة:

   ```bash
   supabase secrets set CLEANUP_CRON_SECRET="$(openssl rand -hex 24)"
   supabase functions deploy cleanup-rooms
   supabase functions deploy tick-rounds
   supabase functions deploy resolve-round
   ```

4. فعّل الجدولة (SQL Editor) — راجع [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) للأوامر الكاملة.
5. انسخ `.env.example` إلى `env.json`:

   ```json
   {
     "SUPABASE_URL": "https://YOUR-PROJECT-REF.supabase.co",
     "SUPABASE_ANON_KEY": "YOUR_PUBLIC_ANON_KEY",
     "APP_ENV": "dev"
   }
   ```

   `env.json` مستثنى من Git. **المفتاح العام (anon) فقط** — لا تضع `service_role` في التطبيق أبدًا.

## التشغيل

```bash
flutter run --dart-define-from-file=env.json
```

## بناء الإصدار

```bash
# مفتاح التوقيع (مرة واحدة، واحتفظ به للأبد)
keytool -genkey -v -keystore ~/lametna-upload-keystore.jks \
        -keyalg RSA -keysize 2048 -validity 10000 -alias lametna

cp tool/android_overrides/key.properties.example android/key.properties
# عدّل المسار وكلمات المرور

flutter build apk --release      --dart-define-from-file=env.json --split-per-abi
flutter build appbundle --release --dart-define-from-file=env.json
```

المخرجات في `build/app/outputs/`. التفاصيل ومتجر Google Play في [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md).

## الاختبارات

```bash
flutter analyze
flutter test                     # وحدات + واجهات
flutter test integration_test/app_test.dart --dart-define-from-file=env.json

# اختبارات SQL/RLS (تحتاج Supabase CLI + Docker)
supabase db reset
psql "$(supabase status -o env | grep DB_URL | cut -d= -f2-)" \
     -v ON_ERROR_STOP=1 -f supabase/tests/rls_and_rules_test.sql
```

## هيكل المشروع

```
lib/
  app/            الثيم، الترجمة (ar/en يدويًا)، الراوتر، جذر التطبيق
  core/           الثوابت، الأخطاء، التخزين، الأدوات، الودجات المشتركة
  models/         12 نموذجًا بلا توليد كود
  services/       supabase · realtime · connectivity
  providers/      موفّرات Riverpod (auth · room · game · leaderboard · …)
  features/       auth · home · rooms · games · profile · leaderboard · settings · legal
supabase/
  migrations/     11 ملف ترحيل SQL
  functions/      3 دوال حافة (Deno)
  seed.sql        الألعاب، الدول، الصور الرمزية، الأسئلة، الشارات
  tests/          اختبارات RLS وقواعد اللعب
admin/            لوحة تحكم ثابتة (Vercel / Netlify / Cloudflare Pages)
tool/             bootstrap.sh · android_overrides/ · generate_avatars.py · branding/
test/             وحدات + واجهات        integration_test/  مسار كامل حقيقي
docs/             التوثيق الكامل
```

## الوثائق

| الملف | المحتوى |
|-------|---------|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | الطبقات، تدفّق البيانات، سلطة الخادم، محرّك الألعاب |
| [DATABASE.md](docs/DATABASE.md) | 24 جدولًا، العلاقات، الفهارس، المشغّلات، RLS |
| [API.md](docs/API.md) | كل دالة RPC بمعاملاتها وأخطائها |
| [REALTIME.md](docs/REALTIME.md) | القنوات، الاشتراكات، إعادة الاتصال، الساعة الموثوقة |
| [GAME_RULES.md](docs/GAME_RULES.md) | قواعد ونقاط ومؤقتات الألعاب |
| [SECURITY.md](docs/SECURITY.md) | نموذج التهديد، RLS، الإشراف، الخصوصية |
| [DEPLOYMENT.md](docs/DEPLOYMENT.md) | من الصفر إلى متجر Play |
| [FREE_HOSTING.md](docs/FREE_HOSTING.md) | البقاء ضمن المجاني ومتى تحتاج ترقية |

## الخصوصية والأمان

- **لا كاميرا، لا ميكروفون، لا موقع جغرافي، لا جهات اتصال.**
- الضيوف بلا بريد ولا هاتف؛ معرّف مجهول فقط.
- العميل لا يملك أبدًا: النقاط، أدوار المافيا، نتائج التصويت، توقيت الجولات. كلها على الخادم.
- كلمة مرور الغرفة تُخزَّن كـ bcrypt ولا تُرسل للعميل إطلاقًا (مُسحوبة الصلاحية على مستوى العمود).
- تصفية ألفاظ، منع روابط، حد طول الرسائل، تحديد معدل، بلاغات وحظر، وسجل عمليات كامل.
- «حذف حسابي» يعمل فعليًا عبر `delete_my_account()`.

راجع [SECURITY.md](docs/SECURITY.md) للتفاصيل.

## حدود الخطة المجانية

مبني ليعمل على المجاني بلا بطاقة بنكية: قاعدة 500 ميغابايت، 200 اتصال لحظي متزامن،
500 ألف استدعاء دالة حافة شهريًا. لذلك: الرسائل قصيرة ومحدودة المعدل، الصور الرمزية
ملفات محلية (Storage غير مستخدم أصلًا)، والغرف والرسائل القديمة تُنظَّف تلقائيًا.
متى تحتاج ترقية ولماذا: [FREE_HOSTING.md](docs/FREE_HOSTING.md).

## الرخصة

MIT — استخدمه وعدّله بحرية. شارك اللمّة. ☕

</div>
