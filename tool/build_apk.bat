@echo off
REM ============================================================
REM  Lametna - double-click this file to build a shareable APK.
REM  ASCII only on purpose (see build_apk.ps1).
REM ============================================================
cd /d "%~dp0.."
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build_apk.ps1" %*
echo.
pause
