# ============================================================
#  Lametna - build a shareable release APK (Windows / PowerShell)
#
#  NOTE: this file is intentionally ASCII-only. Windows PowerShell 5.1
#  reads .ps1 files as ANSI, so non-ASCII text (Arabic, arrows) breaks
#  the parser. Keep it ASCII.
#
#  Usage from the project root:
#     powershell -ExecutionPolicy Bypass -File tool\build_apk.ps1
#
#  Options:
#     -Split   build one APK per ABI (smaller, for advanced users)
#     -Clean   clean the previous build first
# ============================================================
param(
    [switch]$Split,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

Write-Host ""
Write-Host "==== Lametna - release build ====" -ForegroundColor Cyan
Write-Host ""

# ---- 1) env.json ------------------------------------------------
if (-not (Test-Path "env.json")) {
    Write-Host "[X] env.json not found in the project root." -ForegroundColor Red
    Write-Host "    Create it with your Supabase values (Settings -> API):" -ForegroundColor Yellow
    Write-Host '    {'
    Write-Host '      "SUPABASE_URL": "https://YOUR-REF.supabase.co",'
    Write-Host '      "SUPABASE_ANON_KEY": "YOUR_PUBLIC_ANON_KEY",'
    Write-Host '      "APP_ENV": "prod"'
    Write-Host '    }'
    exit 1
}
Write-Host "[OK] env.json found" -ForegroundColor Green

# ---- 2) signing key ---------------------------------------------
if (Test-Path "android\key.properties") {
    Write-Host "[OK] release signing key found (android\key.properties)" -ForegroundColor Green
} else {
    Write-Host "[!] android\key.properties missing - the build will be signed with the DEBUG key." -ForegroundColor Yellow
    Write-Host "    Fine for testing, but do not distribute it: future updates will not install over it." -ForegroundColor Yellow
    Write-Host "    See docs/SHARE_APK.md" -ForegroundColor Yellow
}
Write-Host ""

# ---- 3) build ----------------------------------------------------
if ($Clean) {
    Write-Host "==> flutter clean" -ForegroundColor Cyan
    flutter clean
}

Write-Host "==> flutter pub get" -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) { Write-Host "[X] pub get failed." -ForegroundColor Red; exit $LASTEXITCODE }

$buildArgs = @("build", "apk", "--release", "--dart-define-from-file=env.json")
if ($Split) { $buildArgs += "--split-per-abi" }

Write-Host "==> flutter $($buildArgs -join ' ')" -ForegroundColor Cyan
Write-Host "    (the first build can take 5-15 minutes)" -ForegroundColor DarkGray
& flutter @buildArgs
if ($LASTEXITCODE -ne 0) { Write-Host "[X] build failed." -ForegroundColor Red; exit $LASTEXITCODE }

# ---- 4) result ---------------------------------------------------
Write-Host ""
Write-Host "[DONE] APK files ready to share:" -ForegroundColor Green
Get-ChildItem "build\app\outputs\flutter-apk\*.apk" |
    Where-Object { $_.Name -notlike "*debug*" } |
    ForEach-Object {
        $mb = [math]::Round($_.Length / 1MB, 1)
        Write-Host ("   " + $_.FullName + "   (" + $mb + " MB)")
    }
Write-Host ""
Write-Host "Send app-release.apk as a DOCUMENT (WhatsApp / Telegram / download link)." -ForegroundColor Cyan
Write-Host "On the receiving phone: open the file -> allow install from this source -> Install." -ForegroundColor Cyan
Write-Host ""
