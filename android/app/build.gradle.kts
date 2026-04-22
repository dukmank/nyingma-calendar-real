plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "org.vajralotusfoundation.nyingmapacalendar"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Enable core library desugaring for java.time APIs on API < 26
        // (required by the timezone package on older Android devices)
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "org.vajralotusfoundation.nyingmapacalendar"
        // flutter_local_notifications requires minSdk 21 (Android 5.0).
        // Exact alarms (SCHEDULE_EXACT_ALARM) require API 31+;
        // USE_EXACT_ALARM is API 33+ — both declared in AndroidManifest.xml.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Enable R8 code shrinking + resource stripping for smaller APK.
            // R8 removes dead Java/Kotlin plugin code; shrinkResources removes
            // unused drawables and layouts from native plugin libraries.
            isMinifyEnabled   = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring: backports java.time to Android API < 26
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.3")
}
