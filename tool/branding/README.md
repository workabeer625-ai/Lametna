<div dir="rtl">

# هوية «لمّتنا» البصرية

| الملف | الاستخدام |
|-------|-----------|
| `app_icon.png` (1024×1024) | مصدر أيقونة التطبيق وأيقونة المتجر |

هذا المجلد **غير مضمَّن في حزمة التطبيق** (ليس ضمن `assets:` في `pubspec.yaml`)
حتى لا نزيد حجم الـ APK بلا داعٍ. شعار شاشة البداية مرسوم بالكود في
`LametnaLogo` داخل `lib/features/auth/presentation/splash_screen.dart`.

## توليد أيقونات المنصات

بعد `bash tool/bootstrap.sh`:

```bash
flutter pub add --dev flutter_launcher_icons
```

ثم أضف إلى `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "tool/branding/app_icon.png"
  adaptive_icon_background: "#6F4E37"
  adaptive_icon_foreground: "tool/branding/app_icon.png"
  remove_alpha_ios: true
```

وشغّل:

```bash
dart run flutter_launcher_icons
```

بدلًا من ذلك يدويًا: صدّر المقاسات 48/72/96/144/192 إلى
`android/app/src/main/res/mipmap-*/ic_launcher.png`.

## الألوان الرسمية

| الاسم | القيمة | الاستخدام |
|-------|--------|-----------|
| بُنّي القهوة | `#6F4E37` | اللون الأساسي |
| أخضر | `#1F6F5B` | اللون الثانوي / الإجراءات |
| ذهبي | `#D9A441` | التمييز والتوكيد |
| بيج | `#F7F0E5` | خلفية الوضع الفاتح |

</div>
