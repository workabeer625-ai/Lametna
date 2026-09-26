# ============================================================
#  لمّتنا / Lametna — قواعد R8/ProGuard
# ============================================================
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# flutter_secure_storage / androidx.security
-keep class androidx.security.crypto.** { *; }

# لا نستخدم الانعكاس في كود التطبيق، لذا التصغير الكامل آمن.
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
