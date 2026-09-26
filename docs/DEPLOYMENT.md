<div dir="rtl">

# النشر · Deployment

من مستودع فارغ إلى تطبيق على متجر Play ولوحة تحكم على الإنترنت — بلا بطاقة بنكية.

## 0. المتطلبات

| الأداة | النسخة | ملاحظة |
|--------|--------|--------|
| Flutter SDK | 3.22 فأعلى | `flutter doctor` بلا أخطاء حمراء |
| Java JDK | 17 | مطلوب لـ Gradle الحديث |
| Android SDK | API 34+ | عبر Android Studio |
| Supabase CLI | أحدث | `npm i -g supabase` |
| Node.js | 18+ | للـ CLI ونشر لوحة التحكم |
| حساب Google Play | 25 دولارًا مرة واحدة | فقط إن أردت النشر في المتجر |

---

## 1. تهيئة المشروع

```bash
git clone https://github.com/workabeer625-ai/Lametna.git
cd Lametna
bash tool/bootstrap.sh
```

السكربت ينفّذ `flutter create --platforms=android,ios .` ثم ينسخ `tool/android_overrides/`
فوق `android/` ويشغّل `flutter pub get` وتوليد الصور الرمزية.

> مجلدا `android/` و `ios/` مُولَّدان عمدًا ولا يُحفظان في Git: هذا يتجنّب تعارضات نسخ Gradle،
> وكل تخصيصاتنا محفوظة في `tool/android_overrides/`.

---

## 2. Supabase

### 2.1 المشروع

1. [supabase.com](https://supabase.com) → New project (خطة Free).
2. اختر أقرب منطقة (من اليمن والخليج: **Frankfurt (eu-central-1)** عادةً الأفضل).
3. احفظ كلمة مرور قاعدة البيانات في مكان آمن.
4. من Settings → API انسخ **Project URL** و **anon public key**.

### 2.2 المخطط والبيانات

```bash
supabase login
supabase link --project-ref YOUR-PROJECT-REF
supabase db push                # 11 ترحيلًا
```

ثم ارفع البيانات الأولية: افتح SQL Editor والصق محتوى `supabase/seed.sql`،
أو محليًا استخدم `supabase db reset` الذي يطبّق الترحيلات والبذور معًا.

### 2.3 المصادقة

Authentication → Providers:

- **Email**: مفعّل، مع «Confirm email» مفعّلًا.
- **Anonymous sign-ins**: مفعّل (لازم لوضع الضيف).

Authentication → URL Configuration → Redirect URLs:

```
io.lametna.app://login-callback
https://your-admin-domain.example/
```

### 2.4 دوال الحافة

```bash
supabase secrets set CLEANUP_CRON_SECRET="$(openssl rand -hex 24)"

supabase functions deploy cleanup-rooms
supabase functions deploy tick-rounds
supabase functions deploy resolve-round
```

### 2.5 الجدولة

SQL Editor:

```sql
create extension if not exists pg_cron;
create extension if not exists pg_net;

-- حسم الجولات المنتهية كل 10 ثوانٍ
select cron.schedule('lametna-tick', '10 seconds', $$
  select net.http_post(
    url     := 'https://YOUR-PROJECT-REF.supabase.co/functions/v1/tick-rounds',
    headers := jsonb_build_object(
                 'Content-Type', 'application/json',
                 'x-cron-secret', 'YOUR_CLEANUP_CRON_SECRET')
  );
$$);

-- تنظيف الغرف الخاملة كل 15 دقيقة
select cron.schedule('lametna-cleanup', '*/15 * * * *', $$
  select net.http_post(
    url     := 'https://YOUR-PROJECT-REF.supabase.co/functions/v1/cleanup-rooms',
    headers := jsonb_build_object(
                 'Content-Type', 'application/json',
                 'x-cron-secret', 'YOUR_CLEANUP_CRON_SECRET')
  );
$$);

-- للتحقق
select * from cron.job;
```

> لو لم يتوفر `pg_cron` في مشروعك، استخدم بديلًا مجانيًا مثل GitHub Actions
> بجدول `*/1 * * * *` يستدعي نفس الرابط بالترويسة نفسها.

### 2.6 التحقق

```sql
select count(*) from public.games;          -- 8
select count(*) from public.questions;      -- > 100
select public.server_now();                 -- وقت الخادم
```

---

## 3. تشغيل التطبيق

```bash
cat > env.json <<'JSON'
{
  "SUPABASE_URL": "https://YOUR-PROJECT-REF.supabase.co",
  "SUPABASE_ANON_KEY": "YOUR_PUBLIC_ANON_KEY",
  "APP_ENV": "dev"
}
JSON

flutter run --dart-define-from-file=env.json
```

`env.json` مستثنى من Git. إن نسيت ضبطه، يعرض التطبيق شاشة «الإعداد ناقص» بدل الانهيار.

---

## 4. بناء الإصدار

### 4.1 مفتاح التوقيع

```bash
keytool -genkey -v \
  -keystore ~/lametna-upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias lametna
```

> ⚠️ **احتفظ بهذا الملف وكلمات مروره إلى الأبد.** فقدانه يعني عجزك عن تحديث التطبيق في المتجر.

```bash
cp tool/android_overrides/key.properties.example android/key.properties
# عدّل storeFile و storePassword و keyPassword
```

### 4.2 البناء

```bash
# APK للتوزيع المباشر (أصغر حجمًا بالتقسيم حسب المعمارية)
flutter build apk --release --dart-define-from-file=env.json --split-per-abi

# AAB لمتجر Play
flutter build appbundle --release --dart-define-from-file=env.json
```

المخرجات:

```
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
build/app/outputs/bundle/release/app-release.aab
```

### 4.3 فحص ما بعد البناء

```bash
# تأكد أنه لا توجد صلاحيات وسائط
$ANDROID_HOME/build-tools/34.0.0/aapt2 dump permissions \
  build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
# المتوقع: INTERNET و ACCESS_NETWORK_STATE فقط
```

---

## 5. متجر Google Play

1. Play Console → Create app: الاسم «لمّتنا»، اللغة الافتراضية العربية، مجاني.
2. ارفع `app-release.aab` في Internal testing أولًا.
3. **Data safety**: صرّح بجمع «البريد الإلكتروني» (للحسابات) و«معرّف المستخدم» فقط.
   لا موقع، لا جهات اتصال، لا وسائط. البيانات مشفّرة أثناء النقل، وتُحذف عند طلب المستخدم.
4. **Content rating**: استبيان قصير — تفاعل بين المستخدمين نعم، بلا عنف ولا محتوى جنسي.
5. **سياسة الخصوصية**: رابط عام إلزامي — انشر نص `PrivacyScreen` على صفحة ثابتة.
6. الأصول: أيقونة 512×512 (المصدر في `tool/branding/app_icon.png`)، لافتة 1024×500،
   و2–8 لقطات شاشة لكل جهاز. لتوليد أيقونات المنصات راجع `tool/branding/README.md`.
7. بعد نجاح الاختبار الداخلي: ترقية إلى Production.

### iOS (اختياري)

يحتاج حساب Apple Developer بـ 99 دولارًا سنويًا:

```bash
cd ios && pod install && cd ..
flutter build ipa --release --dart-define-from-file=env.json
```

الكود جاهز لـ iOS — لا يوجد استخدام لأي واجهة خاصة بأندرويد.

---

## 6. لوحة التحكم

```bash
cd admin
# عدّل config.js: SUPABASE_URL + SUPABASE_ANON_KEY (العام فقط!)

npx vercel deploy --prod                    # أو
npx netlify deploy --prod --dir=.           # أو
npx wrangler pages deploy . --project-name lametna-admin
```

ثم رقِّ حسابك إلى مدير:

```sql
update public.profiles set role = 'admin'
 where id = (select id from auth.users where email = 'you@example.com');
```

وأضف نطاق اللوحة إلى Redirect URLs في Supabase.

---

## 7. التحديثات

```bash
# pubspec.yaml
version: 1.1.0+2        # اسم الإصدار + رقم البناء (يجب أن يزيد دائمًا)

flutter build appbundle --release --dart-define-from-file=env.json
```

تغييرات قاعدة البيانات: أضف ملف ترحيل جديدًا في `supabase/migrations/` — **لا تعدّل ملفًا قديمًا** —
ثم `supabase db push`. اجعل الترحيلات متوافقة مع النسخة السابقة من التطبيق لأن المستخدمين
لا يحدّثون فورًا.

---

## 8. حلّ المشكلات

| العَرَض | السبب الغالب | الحل |
|---------|--------------|------|
| «الإعداد ناقص» عند الإقلاع | نسيت `--dart-define-from-file` | مرّر `env.json` |
| الغرف لا تتحدث لحظيًا | الجداول ليست في منشور Realtime | Database → Replication |
| الجولة لا تنتهي | `tick-rounds` غير مجدولة | راجع `cron.job` وسجلات الدالة |
| «FORBIDDEN» في اللوحة | دور الحساب ليس admin | حدّث `profiles.role` |
| فشل التوقيع | مسار خاطئ في `key.properties` | استخدم مسارًا مطلقًا |
| `Execution failed for task ':app:...'` | JDK غير 17 | `flutter config --jdk-dir` |
| فشل الترحيل عند `alter publication` | أُضيفت الجداول سابقًا | متوقّع؛ تجاهله |

</div>
