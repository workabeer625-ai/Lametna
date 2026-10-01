# ============================================================
#  Lametna - one-shot setup for invite deep links (Windows)
#
#  ASCII only on purpose: Windows PowerShell 5.1 reads .ps1 as ANSI.
#
#  What it does:
#    1) reads the SHA-256 fingerprint of your release signing key
#    2) writes it into landing\.well-known\assetlinks.json
#    3) writes your domain into android\app\src\main\res\values\strings.xml
#    4) adds APP_LINK_BASE to env.json
#
#  Usage (from the project root):
#    powershell -ExecutionPolicy Bypass -File tool\setup_links.ps1 -Domain lametna.vercel.app
#
#  Options:
#    -Domain       required, e.g. lametna.vercel.app
#    -PathPrefix   default "/r/"  (GitHub Pages project site: "/Lametna/r/")
#    -Keystore     default F:\lametna-keystore.jks
#    -Alias        default lametna
# ============================================================
param(
    [Parameter(Mandatory = $true)][string]$Domain,
    [string]$PathPrefix = "/r/",
    [string]$Keystore = "F:\lametna-keystore.jks",
    [string]$Alias = "lametna"
)

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

$Domain = $Domain -replace "^https?://", ""
$Domain = $Domain.TrimEnd("/")
if (-not $PathPrefix.StartsWith("/")) { $PathPrefix = "/" + $PathPrefix }
if (-not $PathPrefix.EndsWith("/")) { $PathPrefix = $PathPrefix + "/" }
$base = "https://" + $Domain + $PathPrefix.Substring(0, $PathPrefix.Length - 3)
$base = $base.TrimEnd("/")

Write-Host ""
Write-Host "==== Lametna - invite links setup ====" -ForegroundColor Cyan
Write-Host ("   domain      : " + $Domain)
Write-Host ("   path prefix : " + $PathPrefix)
Write-Host ("   link base   : " + $base)
Write-Host ""

# ---- 1) fingerprint ---------------------------------------------
$fp = $null
if (Test-Path $Keystore) {
    $keytool = "keytool"
    if ($env:JAVA_HOME -and (Test-Path (Join-Path $env:JAVA_HOME "bin\keytool.exe"))) {
        $keytool = Join-Path $env:JAVA_HOME "bin\keytool.exe"
    }
    Write-Host "==> reading SHA-256 from the keystore (you will be asked for the store password)" -ForegroundColor Cyan
    try {
        $out = & $keytool -list -v -keystore $Keystore -alias $Alias 2>&1 | Out-String
        $m = [regex]::Match($out, "SHA256:\s*([0-9A-Fa-f:]{95,})")
        if ($m.Success) { $fp = $m.Groups[1].Value.ToUpper() }
    } catch {
        Write-Host "[!] keytool failed - skipping the fingerprint step." -ForegroundColor Yellow
    }
    if ($fp) {
        Write-Host ("[OK] SHA-256: " + $fp.Substring(0, 23) + "...") -ForegroundColor Green
    } else {
        Write-Host "[!] could not read the fingerprint (wrong password or alias?)." -ForegroundColor Yellow
    }
} else {
    Write-Host ("[!] keystore not found: " + $Keystore) -ForegroundColor Yellow
    Write-Host "    Links will still work through the landing page, but Android will open" -ForegroundColor Yellow
    Write-Host "    the browser first instead of jumping straight into the app." -ForegroundColor Yellow
}

# ---- 2) assetlinks.json -----------------------------------------
$al = "landing\.well-known\assetlinks.json"
if ($fp -and (Test-Path $al)) {
    $json = @"
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "app.lametna.lametna",
      "sha256_cert_fingerprints": [
        "$fp"
      ]
    }
  }
]
"@
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText((Resolve-Path $al).Path, $json, $utf8NoBom)
    Write-Host "[OK] landing\.well-known\assetlinks.json updated" -ForegroundColor Green
}

# ---- 3) strings.xml ---------------------------------------------
$sx = "android\app\src\main\res\values\strings.xml"
if (Test-Path $sx) {
    $txt = Get-Content $sx -Raw -Encoding UTF8
    $txt = [regex]::Replace($txt,
        '(<string name="app_link_host" translatable="false">)[^<]*(</string>)',
        ('${1}' + $Domain + '${2}'))
    $txt = [regex]::Replace($txt,
        '(<string name="app_link_path_prefix" translatable="false">)[^<]*(</string>)',
        ('${1}' + $PathPrefix + '${2}'))
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText((Resolve-Path $sx).Path, $txt, $utf8NoBom)
    Write-Host "[OK] android strings.xml updated" -ForegroundColor Green
}

# ---- 4) env.json -------------------------------------------------
if (Test-Path "env.json") {
    try {
        $cfg = Get-Content "env.json" -Raw -Encoding UTF8 | ConvertFrom-Json
        $cfg | Add-Member -NotePropertyName APP_LINK_BASE -NotePropertyValue $base -Force
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText((Resolve-Path "env.json").Path,
            ($cfg | ConvertTo-Json -Depth 6), $utf8NoBom)
        Write-Host ("[OK] env.json -> APP_LINK_BASE = " + $base) -ForegroundColor Green
    } catch {
        Write-Host "[!] could not edit env.json automatically. Add this line yourself:" -ForegroundColor Yellow
        Write-Host ('    "APP_LINK_BASE": "' + $base + '"')
    }
} else {
    Write-Host "[!] env.json not found in the project root." -ForegroundColor Yellow
}

# ---- next steps --------------------------------------------------
Write-Host ""
Write-Host "NEXT STEPS" -ForegroundColor Cyan
Write-Host "  1) publish the landing folder:   cd landing ; npx vercel deploy --prod"
Write-Host ("  2) check it opens:               https://" + $Domain + "/.well-known/assetlinks.json")
Write-Host "  3) rebuild the app:              powershell -ExecutionPolicy Bypass -File tool\build_apk.ps1 -Clean"
Write-Host "  4) install the new APK on the PHONE, then tap the invite link there."
Write-Host ""
Write-Host "Deep links only work on the phone - never on a PC browser." -ForegroundColor Yellow
Write-Host ""
