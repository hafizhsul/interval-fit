plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Patch wakelock_plus 1.5.2 Pigeon-generated Kotlin (missing package declaration).
// Sumber: android/patches/WakelockPlusMessages.g.kt — copy ke pub cache sebelum compile.
// Hapus patch ini jika wakelock_plus dinaikkan ke >=1.6 (konflik rantai win32).
val patchWakelock by tasks.registering(Copy::class) {
    from("${rootDir}/patches/WakelockPlusMessages.g.kt")
    into("${System.getProperty("user.home")}/.pub-cache/hosted/pub.dev/wakelock_plus-1.5.2/android/src/main/kotlin/dev/fluttercommunity/plus/wakelock/")
}
tasks.matching { it.name.startsWith("compile") }.configureEach {
    dependsOn(patchWakelock)
}

android {
    namespace = "com.intervalfit.interval_fit"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.intervalfit.interval_fit"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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
