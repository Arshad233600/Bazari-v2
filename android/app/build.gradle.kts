// android/app/build.gradle.kts
plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // ✔ نام‌اسپیس پروژه (با پکیج دلخواه شما هماهنگ باشد)
    namespace = "com.example.bazari_8656"

    // ✔ از مقادیر پیشنهادی Flutter استفاده کن
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.bazari_8656"

        // اگر می‌خواهید حتماً 21 باشد، همین را نگه دارید
        minSdk = 21
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // در صورت نیاز به چند-دکسی (safe)
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // برای تست؛ بعداً با keystore خودتان امضا کنید
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }
}

// در صورت فعال بودن multiDex بهتره این وابستگی هم باشد
dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}
