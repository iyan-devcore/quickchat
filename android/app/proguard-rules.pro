# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# keep flutter classes
-keep class * implements io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }
-keep class * implements io.flutter.plugin.common.EventChannel$StreamHandler { *; }
-keep class * implements io.flutter.plugin.common.MessageCodec { *; }
-keep class * implements io.flutter.plugin.platform.PlatformViewFactory { *; }

# webrtc
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**

# socket.io
-keep class io.socket.** { *; }
-dontwarn io.socket.**

# Ignore warnings for google play core (common flutter issue with R8)
-dontwarn com.google.android.play.core.**
