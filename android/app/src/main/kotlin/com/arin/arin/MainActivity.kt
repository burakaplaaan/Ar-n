package com.arin.arin

import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.hardware.GeomagneticField
import android.media.RingtoneManager
import android.view.KeyEvent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        const val EXTRA_WIDGET_KIND = "widget_kind"
        const val EXTRA_WIDGET_LOCK = "widget_lock"
    }

    private var pendingWidgetLaunchKind: String? = null
    private var pendingWidgetLaunchLock: String? = null
    private var systemBackChannel: MethodChannel? = null
    private var systemBackDispatchPending = false
    private var systemBackGeneration = 0L
    private var systemBackRequestId = 0L
    private val mainHandler = Handler(Looper.getMainLooper())
    private var lastUiModeNight: Int = Configuration.UI_MODE_NIGHT_UNDEFINED

    override fun onCreate(savedInstanceState: Bundle?) {
        pendingWidgetLaunchKind = intent?.getStringExtra(EXTRA_WIDGET_KIND)
        pendingWidgetLaunchLock = intent?.getStringExtra(EXTRA_WIDGET_LOCK)
        lastUiModeNight =
            resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
        super.onCreate(savedInstanceState)
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        // configChanges içinde uiMode var; absolute kilit-bildirim renkleri
        // RemoteViews'e gömüldüğü için tema değişince yeniden sync gerekir.
        val night = newConfig.uiMode and Configuration.UI_MODE_NIGHT_MASK
        if (night != lastUiModeNight) {
            lastUiModeNight = night
            ArinLockNotifications.syncAll(applicationContext)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        pendingWidgetLaunchKind = intent.getStringExtra(EXTRA_WIDGET_KIND)
        pendingWidgetLaunchLock = intent.getStringExtra(EXTRA_WIDGET_LOCK)
    }

    @Suppress("DEPRECATION")
    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (event.keyCode == KeyEvent.KEYCODE_BACK) {
            if (event.action == KeyEvent.ACTION_UP && !event.isCanceled) {
                onBackPressed()
            }
            return true
        }
        return super.dispatchKeyEvent(event)
    }

    @Suppress("DEPRECATION")
    override fun onBackPressed() {
        val channel = systemBackChannel
        if (channel == null || systemBackDispatchPending) {
            if (channel == null) super.onBackPressed()
            return
        }
        systemBackDispatchPending = true
        val generation = systemBackGeneration
        val requestId = ++systemBackRequestId
        var completed = false
        lateinit var timeout: Runnable

        val complete: (Boolean) -> Unit = complete@{ handled ->
            if (completed) return@complete
            completed = true
            mainHandler.removeCallbacks(timeout)
            if (generation != systemBackGeneration || requestId != systemBackRequestId) {
                return@complete
            }
            systemBackDispatchPending = false
            if (!handled && !isFinishing && !isDestroyed) {
                super@MainActivity.onBackPressed()
            }
        }
        timeout = Runnable { complete(false) }
        mainHandler.postDelayed(timeout, 1_000L)

        try {
            channel.invokeMethod("handleBack", null, object : MethodChannel.Result {
                override fun success(result: Any?) {
                    complete(result == true)
                }

                override fun error(code: String, message: String?, details: Any?) {
                    complete(false)
                }

                override fun notImplemented() {
                    complete(false)
                }
            })
        } catch (_: RuntimeException) {
            complete(false)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        systemBackGeneration += 1
        systemBackChannel = MethodChannel(messenger, "com.arin.arin/system_back")

        MethodChannel(messenger, "com.arin.arin/widget_launch")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "consumeWidgetLaunch" -> {
                        val kind = pendingWidgetLaunchKind
                        val lock = pendingWidgetLaunchLock
                        pendingWidgetLaunchKind = null
                        pendingWidgetLaunchLock = null
                        if (kind != null) {
                            if (lock == "1") {
                                result.success("$kind?lock=1")
                            } else {
                                result.success(kind)
                            }
                        } else {
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(messenger, "com.arin.arin/notification_sound_uri")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "contentUriForFile" -> {
                        val path = call.arguments as? String
                        if (path.isNullOrEmpty()) {
                            result.error("bad_args", null, null)
                            return@setMethodCallHandler
                        }
                        try {
                            val f = File(path)
                            if (!f.exists()) {
                                result.error("not_found", path, null)
                                return@setMethodCallHandler
                            }
                            val uri = FileProvider.getUriForFile(
                                this,
                                applicationContext.packageName + ".fileprovider",
                                f
                            )
                            result.success(uri.toString())
                        } catch (e: Exception) {
                            result.error("error", e.message, null)
                        }
                    }
                    "defaultNotificationSoundUri" -> {
                        val actual = RingtoneManager.getActualDefaultRingtoneUri(
                            applicationContext,
                            RingtoneManager.TYPE_NOTIFICATION
                        )
                        val uri = actual
                            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                        result.success(uri?.toString())
                    }
                    "playDefaultNotificationSound" -> {
                        try {
                            val actual = RingtoneManager.getActualDefaultRingtoneUri(
                                applicationContext,
                                RingtoneManager.TYPE_NOTIFICATION
                            )
                            val uri = actual
                                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                            if (uri == null) {
                                result.success(false)
                                return@setMethodCallHandler
                            }
                            val ringtone = RingtoneManager.getRingtone(applicationContext, uri)
                            ringtone?.play()
                            result.success(ringtone != null)
                        } catch (e: Exception) {
                            result.error("error", e.message, null)
                        }
                    }
                    // Kullanıcının "Aramalar için zil sesi" olarak atadığı sesi döner.
                    // Namaz ses ayarlarındaki preview'da, bildirim shade'inde herhangi
                    // bir bildirim göstermeden doğrudan bu URI audioplayers ile
                    // çalınacak — kullanıcı telefonu çaldığında duyduğu sesi birebir
                    // dinler. getActualDefaultRingtoneUri, kullanıcı özel bir seçim
                    // yapmadıysa sistem varsayılanına (getDefaultUri) otomatik düşer.
                    "defaultRingtoneUri" -> {
                        val actual = RingtoneManager.getActualDefaultRingtoneUri(
                            applicationContext,
                            RingtoneManager.TYPE_RINGTONE
                        )
                        val uri = actual
                            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                        result.success(uri?.toString())
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(messenger, "com.arin.arin/prayer_notifications")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "schedule" -> {
                        @Suppress("UNCHECKED_CAST")
                        val args = call.arguments as? Map<*, *>
                        if (args == null) {
                            result.error("bad_args", "arguments missing", null)
                            return@setMethodCallHandler
                        }
                        try {
                            ArinPrayerNotificationScheduler.schedule(
                                applicationContext,
                                args
                            )
                            result.success(true)
                        } catch (e: SecurityException) {
                            result.error("security", e.message, null)
                        } catch (e: Exception) {
                            result.error("error", e.message, null)
                        }
                    }
                    "cancel" -> {
                        val id = (call.arguments as? Number)?.toInt()
                        if (id == null) {
                            result.error("bad_args", "id missing", null)
                            return@setMethodCallHandler
                        }
                        ArinPrayerNotificationScheduler.cancel(applicationContext, id)
                        result.success(true)
                    }
                    "cancelAll" -> {
                        ArinPrayerNotificationScheduler.cancelAll(applicationContext)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // ─────────────────────────────────────────────────────────────────
        // Keşfet PNG derin paylaşım kanalı.
        //
        // NOT: Standart "sharePng" artık Flutter tarafında `share_plus` ile
        // yapılıyor (sistem chooser'ı — Instagram, WhatsApp, FB vs.).
        // Bu kanal YALNIZCA derin Stories paylaşımı için:
        //   • shareToInstagramStories  — com.instagram.share.ADD_TO_STORY
        //   • shareToFacebookStories   — com.facebook.stories.ADD_TO_STORY
        //
        // Kritik fark: result.success(...) çağrısı startActivity SONRASINA
        // alındı. Eski handler'da tam tersi yapılmış ve Dart MethodChannel
        // tamamlayıcısında `LateInitializationError("Local 'result'")`
        // yarıyordu — kullanıcıya "Paylaşım şu an tamamlanamadı" olarak
        // yansıyordu. Bu sırayla artık tetiklenmiyor.
        // ─────────────────────────────────────────────────────────────────
        MethodChannel(messenger, "com.arin.arin/kesfet_share")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareToInstagramStories" -> {
                        val path = call.arguments as? String
                        handleStoriesShare(
                            result = result,
                            path = path,
                            intentAction = "com.instagram.share.ADD_TO_STORY",
                            targetPackage = "com.instagram.android",
                            mimeType = "image/png",
                            extras = { intent ->
                                intent.putExtra(
                                    "source_application",
                                    applicationContext.packageName
                                )
                            },
                        )
                    }
                    "shareToFacebookStories" -> {
                        val args = call.arguments as? Map<*, *>
                        val path = args?.get("path") as? String
                        val appId = (args?.get("appId") as? String).orEmpty()
                        handleStoriesShare(
                            result = result,
                            path = path,
                            intentAction = "com.facebook.stories.ADD_TO_STORY",
                            targetPackage = "com.facebook.katana",
                            mimeType = "image/png",
                            extras = { intent ->
                                if (appId.isNotEmpty()) {
                                    intent.putExtra(
                                        "com.facebook.platform.extra.APPLICATION_ID",
                                        appId
                                    )
                                }
                            },
                        )
                    }
                    else -> result.notImplemented()
                }
            }

        // Kilit ekranı bildirim widget'ları: toggle değişince veya
        // ArinWidgetSync bir push yapınca Flutter bu kanaldan native'i
        // tetikler (AppWidgetProvider instance'ına bağlı olmadığı için
        // widget update broadcast'lerine güvenemez).
        MethodChannel(messenger, "com.arin.arin/lock_notifications")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "syncAll" -> {
                        ArinLockNotifications.syncAll(applicationContext)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // OEM (Xiaomi/Huawei/Oppo/Vivo/Samsung) autostart + pil ayar deep-link.
        MethodChannel(messenger, ArinOemSettings.CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInfo" -> result.success(ArinOemSettings.info(applicationContext))
                    "openAutoStart" ->
                        result.success(ArinOemSettings.openAutoStart(applicationContext))
                    "openOemBattery" ->
                        result.success(ArinOemSettings.openOemBattery(applicationContext))
                    "openAppDetails" ->
                        result.success(ArinOemSettings.openAppDetails(applicationContext))
                    "openRequestIgnoreBattery" ->
                        result.success(
                            ArinOemSettings.openRequestIgnoreBattery(applicationContext),
                        )
                    else -> result.notImplemented()
                }
            }

        // ── Pusula (rotation-vector → heading + manyetik deklinasyon) ─────
        EventChannel(messenger, "com.arin.arin/rotation_compass")
            .setStreamHandler(RotationVectorCompassStream(this))

        MethodChannel(messenger, "com.arin.arin/compass_geomagnetic")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "update" -> {
                        @Suppress("UNCHECKED_CAST")
                        val args = call.arguments as? Map<*, *>
                        if (args == null) {
                            result.error("bad_args", null, null)
                            return@setMethodCallHandler
                        }
                        val lat = (args["latitude"]  as Number).toFloat()
                        val lon = (args["longitude"] as Number).toFloat()
                        val alt = (args["altitude"]  as? Number)?.toFloat() ?: 0f
                        val gf  = GeomagneticField(lat, lon, alt, System.currentTimeMillis())
                        val dec = gf.declination
                        CompassGeomagnetic.setDeclinationDegrees(dec)
                        result.success(dec.toDouble())
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        systemBackGeneration += 1
        systemBackRequestId += 1
        systemBackChannel = null
        systemBackDispatchPending = false
        super.cleanUpFlutterEngine(flutterEngine)
    }

    // ─────────────────────────────────────────────────────────────────────
    // Stories derin paylaşımı — ortak helper.
    //
    //  1) Dosya kontrol → FileProvider URI
    //  2) Hedef Intent (Instagram/Facebook Stories ADD_TO_STORY)
    //  3) Paket yüklü mü? (packageManager.resolveActivity)
    //  4) grantUriPermission → startActivity → result.success(true)
    //
    // "not_installed" kodu Dart tarafında kullanıcıya düzgün mesaj vermek
    // için özel olarak yakalanıyor.
    // ─────────────────────────────────────────────────────────────────────
    private fun handleStoriesShare(
        result: MethodChannel.Result,
        path: String?,
        intentAction: String,
        targetPackage: String,
        mimeType: String,
        extras: (Intent) -> Unit,
    ) {
        if (path.isNullOrEmpty()) {
            result.error("bad_args", "path missing", null)
            return
        }
        val f = File(path)
        if (!f.exists() || !f.isFile) {
            result.error("not_found", path, null)
            return
        }
        try {
            val uri = FileProvider.getUriForFile(
                this,
                applicationContext.packageName + ".fileprovider",
                f
            )
            val intent = Intent(intentAction).apply {
                setDataAndType(uri, mimeType)
                setPackage(targetPackage)
                flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or
                        Intent.FLAG_ACTIVITY_NEW_TASK
            }
            extras(intent)

            val resolved = packageManager.resolveActivity(
                intent,
                PackageManager.MATCH_DEFAULT_ONLY
            )
            if (resolved == null) {
                result.error("not_installed", targetPackage, null)
                return
            }

            try {
                grantUriPermission(
                    targetPackage,
                    uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION
                )
            } catch (_: Exception) {
                // Zaten verildiği için yutulabilir.
            }

            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            android.util.Log.e("KesfetStoriesShare", intentAction, e)
            result.error("share_failed", e.message, null)
        }
    }
}
