# Flutter — keep all native entry points
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# Keep plugin registrar methods
-keep class * extends io.flutter.embedding.engine.plugins.FlutterPlugin { *; }
-keep class * implements io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }
-keep class * implements io.flutter.plugin.common.EventChannel$StreamHandler { *; }

# geolocator
-keep class com.baseflow.geolocator.** { *; }

# flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# shared_preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# http (OkHttp / Dart http uses Java's HttpURLConnection — no keep needed)
-dontwarn okhttp3.**
-dontwarn okio.**

# General: keep all public classes referenced via reflection
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
