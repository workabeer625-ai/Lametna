# ============================================================
#  لمّتنا / Lametna — بناء APK جاهز للمشاركة (Windows / PowerShell)
#
#  الاستخدام من جذر المشروع:
#     powershell -ExecutionPolicy Bypass -File tool\build_apk.ps1
#
#  خيارات:
#     -Split     يبني APK منفصلًا لكل معمارية (أصغر حجمًا، للمتقدمين)
#     -Clean     ينظّف البناء السابق قبل البدء
# ============================================================
param(
    [switch]$Split,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

Write-Host ""
Write-Host "==== لمّتنا — بناء نسخة الإصدار ====" -ForegroundColor Cyan
Write-Host ""

# ── 1) التحقق من env.json ───────────────────────────────────
if (-not (Test-Path "env.json")) {
    Write-Host "✗ لا يوجد ملف env.json في جذر المشروع." -ForegroundColor Red
    Write-Host "  أنشئه بهذا الشكل (القيم من Supabase → Settings → API):" -ForegroundColor Yellow
    Write-Host '  {'
    Write-Host '    "SUPABASE_URL": "https://YOUR-REF.supabase.co",'
    Write-Host '    "SUPABASE_ANON_KEY": "YOUR_PUBLIC_ANON_KEY",'
    Write-Host '    "APP_ENV": "prod"'
    Write-Host '  }'
    exit 1
}

# ── 2) التحقق من مفتاح التوقيع ──────────────────────────────
if (Test-Path "android\key.properties") {
    Write-Host "✓ مفتاح توقيع الإصدار موجود (android\key.properties)" -ForegroundColor Green
} else {
    Write-Host "⚠ لا يوجد android\key.properties — سيُوقَّع البناء بمفتاح debug." -ForegroundColor Yellow
    Write-Host "  يعمل للتجربة، لكن لا توزّعه: كل تحديث لاحق سيفشل تثبيته فوق القديم." -ForegroundColor Yellow
    Write-Host "  الطريقة في docs\SHARE_APK.md" -ForegroundColor Yellow
    Write-Host ""
}

# ── 3) البناء ───────────────────────────────────────────────
if ($Clean) {
    Write-Host "==> تنظيف البناء السابق..." -ForegroundColor Cyan
    flutter clean
}

Write-Host "==> جلب الحزم..." -ForegroundColor Cyan
flutter pub get

$args = @("build", "apk", "--release", "--dart-define-from-file=env.json")
if ($Split) { $args += "--split-per-abi" }

Write-Host "==> flutter $($args -join ' ')" -ForegroundColor Cyan
& flutter @args
if ($LASTEXITCODE -ne 0) { Write-Host "✗ فشل البناء." -ForegroundColor Red; exit $LASTEXITCODE }

# ── 4) النتيجة ──────────────────────────────────────────────
Write-Host ""
Write-Host "✅ تمّ البناء. الملفات الجاهزة للمشاركة:" -ForegroundColor Green
Get-ChildItem "build\app\outputs\flutter-apk\*.apk" |
    Where-Object { $_.Name -notlike "*debug*" } |
    ForEach-Object {
        $mb = [math]::Round($_.Length / 1MB, 1)
        Write-Host ("   {0}   ({1} MB)" -f $_.FullName, $mb)
    }
Write-Host ""
Write-Host "أرسل ملف app-release.apk عبر واتساب/تيليجرام/رابط تحميل." -ForegroundColor Cyan
Write-Host "على جهاز المستلم: افتح الملف ← اسمح بالتثبيت من مصادر غير معروفة ← تثبيت." -ForegroundColor Cyan
Write-Host ""
