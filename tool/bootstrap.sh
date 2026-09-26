#!/usr/bin/env bash
# ============================================================
#  لمّتنا / Lametna — تهيئة المشروع بعد الاستنساخ
#  Generates the native platform folders, then applies the
#  project's Android customisations on top of them.
# ============================================================
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> 1/4  توليد مجلدات المنصات (android/ios) إن لم تكن موجودة"
flutter create \
  --platforms=android,ios \
  --org app.lametna \
  --project-name lametna \
  --overwrite \
  .

echo "==> 2/4  تطبيق تخصيصات Android الخاصة بلمّتنا"
cp -R tool/android_overrides/. android/

echo "==> 3/4  تثبيت الحزم"
flutter pub get

echo "==> 4/4  توليد الصور الرمزية (إن كانت ناقصة)"
python3 tool/generate_avatars.py || true

cat <<'MSG'

✅ جاهز.

الخطوة التالية: أنشئ ملف env.json (غير مُتتبَّع في Git) بالمحتوى:

{
  "SUPABASE_URL": "https://YOUR-PROJECT-REF.supabase.co",
  "SUPABASE_ANON_KEY": "YOUR_PUBLIC_ANON_KEY",
  "APP_ENV": "dev"
}

ثم شغّل:
  flutter run --dart-define-from-file=env.json

MSG
