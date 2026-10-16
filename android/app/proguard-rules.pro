# Reglas ProGuard para MusiQuest

# Mantener clases de Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# Google Play Core (para evitar errores de R8)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Mantener clases de audio
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.just_audio.** { *; }

# Mantener clases de permisos
-keep class com.baseflow.permissionhandler.** { *; }

# Mantener clases nativas
-keepclasseswithmembernames class * {
    native <methods>;
}

# Optimización de recursos
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-dontpreverify
-verbose

# Mantener anotaciones
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable

# Drift/SQLite
-keep class * extends com.drift.** { *; }
-keepclassmembers class * extends com.drift.** { *; }

# Riverpod
-keep class * extends dev.riverpod.** { *; }
-keepclassmembers class * extends dev.riverpod.** { *; }

