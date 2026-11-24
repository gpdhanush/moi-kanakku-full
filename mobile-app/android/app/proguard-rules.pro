# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Play Core / Flutter deferred components compatibility
-dontwarn com.google.android.play.core.**

# ----- Reverse-engineering hardening -----
# Strip Android logging from the release binary so leftover Log.d/Log.v calls
# can't leak internals to logcat. (Dart-side logging is gated separately.)
-assumenosideeffects class android.util.Log {
    public static *** v(...);
    public static *** d(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}

# Hide original source file names and line numbers in stack traces, while
# keeping line numbers mapped so obfuscated crashes can still be read via the
# retrace mapping file (build/outputs/mapping/release/mapping.txt).
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
