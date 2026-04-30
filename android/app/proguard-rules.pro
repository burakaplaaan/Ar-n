# ==============================================================
# Arın — R8/ProGuard keep rules
# Kritik: flutter_local_notifications 17.x Android tarafı Gson ile
# pending notification listesini serialize ediyor. R8 generic
# signature'ları silerse `TypeToken<List<...>>` deserialize’ı
# `IllegalStateException: TypeToken must be created with a type
# argument` fırlatır → zonedSchedule/cancel komple kopar.
# (Ölçüldü: Samsung Galaxy A34 / OneUI 8 / Android 16, API 36)
# ==============================================================

# ---- Genel (Gson + reflection) ----
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# ---- Gson ----
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep public class * implements java.lang.reflect.Type
# Plugin içindeki anonymous TypeToken alt sınıfları (FlutterLocalNotificationsPlugin$1,
# ScheduledNotificationReceiver$1 vb.) — Gson runtime'da `getClass().getGenericSuperclass()`
# çağırıyor, Signature attribute'u düşerse patlıyor. Anonymous inner class'ları
# da tutacak şekilde EnclosingMethod + InnerClasses + Signature zorunlu.
-keepclassmembers,allowobfuscation,includedescriptorclasses class * extends com.google.gson.reflect.TypeToken {
    *;
}
-keep class com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin$* { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver$* { *; }
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
-dontwarn com.google.gson.**

# ---- flutter_local_notifications ----
-keep class com.dexterous.** { *; }
-keep interface com.dexterous.** { *; }
-dontwarn com.dexterous.**

# ---- Timezone / Desugar ----
-dontwarn org.threeten.**

# ---- Play Core (deferred components) ----
# Arın deferred component KULLANMIYOR; Flutter embedding yine de referans veriyor.
# Runtime’da hiç çağrılmıyor, sadece R8 static analiz için gerekli.
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication

# ---- Flutter engine ----
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ---- Kotlin reflection ----
-dontwarn kotlin.reflect.jvm.internal.**
-keepclassmembers class kotlin.Metadata { public <methods>; }
