plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.bookmydoc2"
    compileSdk = 35 // Updated to a recent stable version (Flutter uses 34 by default in newer versions)

    // Explicitly set NDK version to match plugin requirements
    ndkVersion = "27.0.12077973"

    compileOptions {
        // Enable core library desugaring for Java 8+ support
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8 // Changed to 1_8 for desugaring compatibility
        targetCompatibility = JavaVersion.VERSION_1_8 // Changed to 1_8 for desugaring compatibility
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString() // Match Java 8 for consistency
    }

    defaultConfig {
        applicationId = "com.example.bookmydoc2"
        minSdk = 23 // Flutter's default minSdk, supports most devices
        targetSdk = 35 // Match compileSdk
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Add desugaring library for core library desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8")
}

flutter {
    source = "../.."
}