#!/usr/bin/env bash
# ============================================================
#  لمّتنا / Lametna — تهيئة المشروع بعد الاستنساخ
#
#  يولّد مجلدات المنصات (android/ios) ثم يطبّق تخصيصات لمّتنا.
#  آمن للتشغيل أكثر من مرة: لا يلمس lib/ ولا pubspec.yaml.
# ============================================================
set -euo pipefail

cd "$(dirname "$0")/.."

BACKUP="$(mktemp -d)"
KEEP=(pubspec.yaml analysis_options.yaml README.md .gitignore .metadata)

echo "==> 1/5  حفظ نسخة احتياطية من ملفات المشروع الحسّاسة"
for f in "${KEEP[@]}"; do
  [ -f "$f" ] && cp "$f" "$BACKUP/" || true
done

echo "==> 2/5  توليد مجلدات المنصات (android/ios)"
# بلا --overwrite: لا نريد أن يستبدل flutter create ملفاتنا.
flutter create \
  --platforms=android,ios \
  --org app.lametna \
  --project-name lametna \
  .

echo "==> 3/5  استرجاع ملفات المشروع وإزالة ما ولّده القالب زائدًا"
for f in "${KEEP[@]}"; do
  [ -f "$BACKUP/$f" ] && cp "$BACKUP/$f" "$f" || true
done
rm -rf "$BACKUP"

# قالب flutter ينشئ اختبارًا افتراضيًا يشير إلى MyApp غير الموجودة لدينا.
# اختباراتنا الحقيقية في test/unit و test/widget.
rm -f test/widget_test.dart

echo "==> 4/5  تطبيق تخصيصات Android الخاصة بلمّتنا"
cp -R tool/android_overrides/. android/

echo "==> 5/5  تثبيت الحزم وتوليد الصور الرمزية"
flutter pub get
python3 tool/generate_avatars.py || true

cat <<'MSG'

✅ جاهز.

تحقّق سريعًا أن القالب لم يغيّر شيئًا:
  git status --short        # يجب ألّا يظهر تعديل على lib/ أو pubspec.yaml

الخطوة التالية: أنشئ ملف env.json (غير مُتتبَّع في Git) بالمحتوى:

{
  "SUPABASE_URL": "https://YOUR-PROJECT-REF.supabase.co",
  "SUPABASE_ANON_KEY": "YOUR_PUBLIC_ANON_KEY",
  "APP_ENV": "dev"
}

ثم شغّل:
  flutter analyze
  flutter test
  flutter run --dart-define-from-file=env.json

MSG
