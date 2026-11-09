# Arın — R8 kuralları
# Amaç: Play Console kod karartma oranını yükseltmek.
# R8 tam mod, küçültme ve optimizasyon açık kalır. Bu dosya optimizasyonu
# kapatmaz; yalnızca gerçekten ismiyle durması gereken sınıfları kilitler.
# Geniş `-keep class com.google.firebase.**` / `com.google.android.gms.**`
# kuralları kütüphanenin kendi kurallarını eziyor ve karartmayı %25 barının
# altına düşürüyordu.

# ---- Gson + flutter_local_notifications ----
# Ölçülen kırılma (Samsung A34, OneUI 8, API 36): Signature düşünce
# `TypeToken<NotificationDetails>` deserialize
# `TypeToken must be created with a type argument` fırlatır ve alarm
# bildirimi çizilmez. Attribute tutmak isim karartmasını engellemez.
-keepattributes Signature,InnerClasses,EnclosingMethod,*Annotation*

-dontwarn com.google.gson.**
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-keep,allowobfuscation class * extends com.google.gson.TypeAdapter
-keep,allowobfuscation class * implements com.google.gson.TypeAdapterFactory
-keep,allowobfuscation class * implements com.google.gson.JsonSerializer
-keep,allowobfuscation class * implements com.google.gson.JsonDeserializer
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

# Modeller ve alarm alıcıları zaten @Keep. Manifestteki alıcı adları
# Android Gradle tarafından ayrıca korunur.

# ---- Play Core ----
# Uygulama deferred component kullanmıyor. Embedding referansı için uyarıyı
# sustur; sınıfları ismiyle kilitleme (kullanılmayan kod küçülebilsin).
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication

# ---- Flutter motoru (JNI) ----
# libflutter.so bu sınıfları isimle arar. Üye adları da JNI ile çağrılır.
# Geri kalan embedding ve eklenti sınıflarını R8 yeniden adlandırabilir.
# Flutter eklenti arayüzleri Flutter Gradle kuralıyla allowobfuscation korunur.
-keep class io.flutter.embedding.engine.FlutterJNI { *; }
-keep class io.flutter.embedding.engine.FlutterOverlaySurface { *; }
-keep class io.flutter.embedding.engine.mutatorsstack.FlutterMutatorsStack { *; }
-keep class io.flutter.embedding.engine.renderer.SurfaceTextureWrapper { *; }
-keep class io.flutter.view.FlutterCallbackInformation { *; }
-keep class io.flutter.view.TextureRegistry$ImageConsumer { *; }

# ---- Kotlin ----
-dontwarn kotlin.reflect.jvm.internal.**
-keepclassmembers class kotlin.Metadata { public <methods>; }

# ---- Firebase / FlutterFire ----
# Kütüphaneler kendi consumer kurallarını getirir. Burada yalnızca manifest
# meta-data dizgisinden yansıma ile yüklenen kayıt sınıfları kilitlenir.
-keep class * implements com.google.firebase.components.ComponentRegistrar
-keep class io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService { *; }
-keep class io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingBackgroundService { *; }
-keep class io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingReceiver { *; }
-keep class io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingInitProvider { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ---- Meta Audience Network ----
-dontwarn com.facebook.infer.annotation.**

# ---- Timezone / Desugar ----
-dontwarn org.threeten.**
