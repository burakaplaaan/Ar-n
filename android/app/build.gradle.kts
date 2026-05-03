import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // Crashlytics Gradle eklentisi: release build'lerde ProGuard/R8 mapping
    // dosyasını Firebase'e otomatik yükler, böylece sembolikleşmiş stack trace
    // kod isimleri Console'da okunabilir olur.
    id("com.google.firebase.crashlytics")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Upload keystore yapılandırması. `android/key.properties` mevcutsa release
// build bu keystore ile imzalanır (Play Console upload key). Dosya yoksa
// release build debug keystore'a düşer → `flutter run --release` lokalde
// çalışmaya devam eder, ama AAB mağazaya yüklenemez (debug-signed red).
// Bu katman sayesinde CI/fresh clone key.properties olmadan da build eder.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.arin.arin"
    // native_device_orientation vb. eklentiler için (geriye dönük uyumlu)
    compileSdk = 36
    // Eklentiler (qiblah, geolocator vb.) ile uyum; uyarıyı kaldırır
    ndkVersion = "27.0.12077973"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.arin.arin"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["adMobAppId"] = "ca-app-pub-3940256099942544~3347511713"
        manifestPlaceholders["firebaseAnalyticsEnabled"] = "false"
        manifestPlaceholders["firebaseCrashlyticsEnabled"] = "false"
    }

    signingConfigs {
        // Release imzalaması: `android/key.properties` mevcutsa upload keystore
        // kullanılır. Play App Signing aktif olduğu için bu "upload key"dir; kayıp
        // durumunda Play Console üzerinden reset edilebilir. Dosya yoksa aşağıdaki
        // buildType release debug keystore'a fallback yapar.
        create("release") {
            if (hasReleaseKeystore) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // key.properties varsa upload key, yoksa debug key (flutter run --release
            // dev akışını korumak için). Mağaza build'i her zaman key.properties ile.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // Release'de R8 aktif → proguard-rules.pro generic signature’ı
            // korur, flutter_local_notifications Gson hatasını önler.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            manifestPlaceholders["adMobAppId"] = "ca-app-pub-1679454938492660~5175629616"
            manifestPlaceholders["firebaseAnalyticsEnabled"] = "false"
            manifestPlaceholders["firebaseCrashlyticsEnabled"] = "false"
        }
        debug {
            // Debug'da minify kapalı (hızlı iteration). DEBUGGABLE flag'ı
            // explicit açıyoruz ki `adb run-as` / logcat filtreleri çalışsın.
            // Flutter'ın `--debug` build'i bazen manifest'e `android:debuggable`
            // eklemiyor → run-as "package not debuggable" hatası alıyorduk.
            isDebuggable = true
            isMinifyEnabled = false
            // NOT: Plugin AAR `consumer-rules.pro` sağlamıyor, Gson
            // `TypeToken<ArrayList<NotificationDetails>>` generic signature'ını
            // korumak için debug'da da KEEP kuralları uygulamak istiyoruz.
            // (shrink kapalı, sadece `-keep` direktifleri etkili.)
            proguardFiles(
                getDefaultProguardFile("proguard-android.txt"),
                "proguard-rules.pro"
            )
            manifestPlaceholders["adMobAppId"] = "ca-app-pub-3940256099942544~3347511713"
            // Debug build'de Firebase Analytics/Crashlytics native collection
            // kapalı. Release/Profile'da da app açılışında kapalı başlıyor;
            // Dart tarafı onboarding sonrası gerekli servisleri açıyor.
            manifestPlaceholders["firebaseAnalyticsEnabled"] = "false"
            manifestPlaceholders["firebaseCrashlyticsEnabled"] = "false"
        }
    }
}

flutter {
    source = "../.."
}

// Namaz bildirimi sesleri: flutter_local_notifications `RawResourceAndroidNotificationSound`
// için dosyaların `res/raw` altında olması gerekir. Kaynak tekilleştirmesi: Flutter asset
// klasöründen her derlemede kopyalanır (APK’da `R.raw.prayer_ntf_*` bulunmasını garanti eder).
val copyPrayerNotificationSounds = tasks.register<Copy>("copyPrayerNotificationSounds") {
    val src = rootProject.projectDir.resolve("../assets/sounds/prayer")
    from(src)
    include("prayer_ntf_*.wav")
    into(layout.projectDirectory.dir("src/main/res/raw"))
}

tasks.named("preBuild").configure {
    dependsOn(copyPrayerNotificationSounds)
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
