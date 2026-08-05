plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Patch wakelock_plus 1.5.x — 3 files perlu diperbaiki agar kompatibel dgn Kotlin compiler.
// Hapus block ini jika wakelock_plus >=1.6.
val pubCache = file("${System.getProperty("user.home")}/.pub-cache/hosted/pub.dev")
val files = fileTree(pubCache).matching {
    include("wakelock_plus-1.5.*/android/src/main/kotlin/dev/fluttercommunity/plus/wakelock/*.kt")
}.files
if (files.isNotEmpty()) {
    val dir = files.first().parentFile
    val patchDir = file("${rootDir}/patches")
    listOf("WakelockPlusMessages.g.kt", "Wakelock.kt", "WakelockPlusPlugin.kt").forEach { name ->
        val target = file("${dir}/${name}")
        val patch = file("${patchDir}/${name}")
        if (target.exists() && patch.exists()) {
            val tContent = target.readText()
            val pContent = patch.readText()
            if (tContent != pContent) {
                target.writeText(pContent)
                project.logger.lifecycle("✓ Patched wakelock_plus/${name}")
            }
        }
    }
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
