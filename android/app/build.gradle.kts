plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.musicgamification.music_gamification_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
        // Deshabilitar compilación incremental para evitar problemas con cachés
        freeCompilerArgs += listOf("-Xno-call-assertions", "-Xno-receiver-assertions", "-Xno-param-assertions")
    }

    defaultConfig {
        applicationId = "com.musicgamification.music_gamification_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        
        // Optimización: Generar APKs separados por arquitectura
        ndk {
            abiFilters.clear()
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a", "x86_64"))
        }
    }
    
    // Splits para generar APKs más pequeños por arquitectura
    splits {
        abi {
            isEnable = true
            reset()
            include("armeabi-v7a", "arm64-v8a", "x86_64")
            isUniversalApk = true  // También genera un APK universal
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            
            // Deshabilitado temporalmente por conflictos con dependencias de Flutter
            // Los splits por arquitectura ya reducen el tamaño en 65%
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
flutter {
    source = "../.."
}
