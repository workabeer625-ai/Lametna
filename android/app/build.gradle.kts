import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ── توقيع الإصدار ───────────────────────────────────────────────
// يُقرأ من android/key.properties (غير مُتتبَّع في Git).
// إن لم يوجد الملف نرجع لتوقيع debug حتى يبقى `flutter build apk` يعمل،
// لكن لا توزّع نسخة موقّعة بمفتاح debug على الناس.
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keystorePropertiesFile.exists()
val keystoreProperties = Properties()
if (hasReleaseSigning) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

android {
    namespace = "app.lametna.lametna"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "app.lametna.lametna"
        // 23 هو الحد الأدنى الذي تحتاجه flutter_secure_storage و supabase.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        // يؤخذ من pubspec.yaml (version: 1.0.0+1) — ارفع الرقم مع كل نسخة توزّعها.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // التصغير معطّل عمدًا: بناء أبسط وأقل عرضة للأعطال.
            // لتفعيله لاحقًا: isMinifyEnabled = true مع proguard-rules.pro.
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
        debug {
            // لاحقة مختلفة حتى تتعايش نسخة التطوير مع النسخة الموزّعة على الجهاز نفسه.
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
