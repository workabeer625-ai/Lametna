#!/usr/bin/env bash
# ============================================================
#  لمّتنا — تنزيل خط Cairo للعمل دون اتصال (اختياري)
#
#  التطبيق يستخدم google_fonts افتراضيًا، وهو ينزّل الخط عند أول
#  تشغيل ثم يخزّنه مؤقتًا. إن أردت تضمين الخط داخل الحزمة (يعمل
#  فورًا وبلا إنترنت، مقابل ~1 ميغابايت إضافية):
#
#     bash tool/fetch_fonts.sh
#     # ثم أزل التعليق عن قسم fonts في pubspec.yaml
#     flutter pub get
# ============================================================
set -euo pipefail
cd "$(dirname "$0")/.."

DEST="assets/fonts"
BASE="https://raw.githubusercontent.com/google/fonts/main/ofl/cairo/static"

mkdir -p "$DEST"

for weight in Regular Medium SemiBold Bold; do
  file="Cairo-${weight}.ttf"
  if [ -f "$DEST/$file" ]; then
    echo "✓ موجود: $file"
    continue
  fi
  echo "⬇ تنزيل $file"
  curl -fsSL "$BASE/$file" -o "$DEST/$file"
done

cat <<'MSG'

✅ تم. أضف إلى pubspec.yaml تحت flutter::

  fonts:
    - family: Cairo
      fonts:
        - asset: assets/fonts/Cairo-Regular.ttf
          weight: 400
        - asset: assets/fonts/Cairo-Medium.ttf
          weight: 500
        - asset: assets/fonts/Cairo-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Cairo-Bold.ttf
          weight: 700

ثم في lib/app/theme/app_theme.dart استبدل GoogleFonts.cairoTextTheme(...)
بـ  base.textTheme.apply(fontFamily: 'Cairo')  .

الخط Cairo مرخّص بـ SIL Open Font License 1.1 — حرّ للاستخدام التجاري.
MSG
