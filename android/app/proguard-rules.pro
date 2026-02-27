# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Ignore missing Play Core classes (not used, but referenced by Flutter)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Ignore missing javax.xml.stream (not used on Android)
-dontwarn javax.xml.stream.**

# Go backend (gobackend.aar) - CRITICAL for release builds
-keep class gobackend.** { *; }
-keep class go.** { *; }
-keep interface gobackend.** { *; }
-keepclassmembers class gobackend.** { *; }

# Go mobile binding internals
-keep class org.golang.** { *; }
-dontwarn org.golang.**

# FFmpeg Kit
-keep class com.arthenica.ffmpegkit.** { *; }
-keep class com.arthenica.smartexception.** { *; }
# FFmpeg Kit (new fork package)
-keep class com.antonkarpenko.ffmpegkit.** { *; }
-keep class com.antonkarpenko.smartexception.** { *; }

# Apache Tika (if used by FFmpeg)
-dontwarn org.apache.tika.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Kotlin coroutines - expanded rules
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembers class kotlinx.coroutines.** {
    volatile <fields>;
}
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}
-dontwarn kotlinx.coroutines.**

# Kotlin serialization
-keepattributes RuntimeVisibleAnnotations,AnnotationDefault
-dontwarn kotlin.**
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }

# Keep MainActivity and related classes
-keep class com.zarz.spotiflac.** { *; }

# Prevent R8 from removing metadata
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# JSON parsing (used by Go backend responses)
-keep class org.json.** { *; }

# Shared Preferences
-keep class androidx.datastore.** { *; }
-dontwarn androidx.datastore.**

# Flutter Plugins - CRITICAL: Prevent R8 from removing plugin implementations
# Path Provider
-keep class io.flutter.plugins.pathprovider.** { *; }
-keep class dev.flutter.pigeon.** { *; }

# Audio Service (media playback notification) - CRITICAL for release builds
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.audio_session.** { *; }
-keep class com.ryanheise.just_audio.** { *; }

# AndroidX Media / MediaSession (used by audio_service)
-keep class androidx.media.** { *; }
-keep class android.support.v4.media.** { *; }
-dontwarn android.support.v4.media.**

# Local Notifications
-keep class com.dexterous.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Receive Sharing Intent
-keep class com.kasem.receive_sharing_intent.** { *; }

# Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }

# File Picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# URL Launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# Share Plus
-keep class dev.fluttercommunity.plus.share.** { *; }

# Device Info Plus
-keep class dev.fluttercommunity.plus.device_info.** { *; }

# Open File
-keep class com.crazecoder.openfile.** { *; }

# Sqflite
-keep class com.tekartik.sqflite.** { *; }

# Dynamic Color
-keep class io.material.** { *; }

# Keep all Flutter plugin registrants
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
-keep class ** extends io.flutter.embedding.engine.plugins.FlutterPlugin { *; }
