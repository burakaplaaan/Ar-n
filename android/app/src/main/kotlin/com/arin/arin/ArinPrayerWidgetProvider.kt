package com.arin.arin

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject

/**
 * Namaz vakitleri widget: `arin_prayer_*` anahtarları.
 * API 24+: [Chronometer] (layout-v24) ile sistem içi saniye saniye geri sayım.
 * API 23: [ACTION_TICK] + düşük frekans AlarmManager fallback.
 */
class ArinPrayerWidgetProvider : HomeWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_TICK || intent.action == ACTION_DEADLINE_REFRESH) {
            val awm = AppWidgetManager.getInstance(context)
            val cn = ComponentName(context, ArinPrayerWidgetProvider::class.java)
            val ids = awm.getAppWidgetIds(cn)
            if (ids.isNotEmpty()) {
                val update = Intent(context, ArinPrayerWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                }
                super.onReceive(context, update)
            }
            return
        }
        super.onReceive(context, intent)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        recordFirstUse(widgetData, "prayer")
        val locked = isWidgetLocked(widgetData, "prayer")
        val scheduled = readScheduledPrayer(widgetData, System.currentTimeMillis())
        val loc = widgetData.getString(KEY_LOCATION, null)?.trim().orEmpty()
        val localeCode = widgetData.getString(KEY_LOCALE, null)?.trim()?.lowercase().orEmpty()
        val forceTurkish = !localeCode.startsWith("tr")
        val displayLocation = scheduled?.location ?: loc.ifEmpty {
            "Konum ayarlanmadı"
        }
        val scheduleExpired = scheduled?.expired == true
        val nextName = scheduled?.name
            ?: widgetData.getString(KEY_NEXT_NAME, null)?.trim().orEmpty()
        val countdownStatic = if (scheduleExpired) {
            "Uygulamayı aç"
        } else {
            widgetData.getString(KEY_COUNTDOWN, null)?.trim().orEmpty()
        }

        val epochMs = if (scheduleExpired) {
            null
        } else {
            scheduled?.epochMs
                ?: widgetData.getString(KEY_NEXT_EPOCH, null)?.trim()?.toLongOrNull()
        }
        val nowMs = System.currentTimeMillis()
        val rawRemMs = if (epochMs != null && epochMs > 0L) epochMs - nowMs else null
        val remMs = rawRemMs?.coerceAtLeast(0L)
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val countdown = if (remMs != null) {
            formatHms(remMs)
        } else {
            sanitizeCountdownLabel(countdownStatic)
        }

        val canUseChronometer =
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.N &&
                remMs != null &&
                remMs > DEADLINE_GUARD_MS

        val openApp = Intent(context, MainActivity::class.java).apply {
            // SINGLE_TOP: arka plandaki singleTop MainActivity'ye yeni intent
            // onNewIntent ile ulaşsın (güncel kind/lock iletilsin).
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(MainActivity.EXTRA_WIDGET_KIND, "prayer")
            if (locked) {
                putExtra(MainActivity.EXTRA_WIDGET_LOCK, "1")
            }
        }
        val piFlags =
            PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_IMMUTABLE
                } else {
                    0
                }
        val contentPi = PendingIntent.getActivity(context, 1, openApp, piFlags)

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.arin_prayer_widget)
            if (locked) {
                views.setViewVisibility(R.id.widget_prayer_content, View.GONE)
                views.setViewVisibility(R.id.widget_lock_overlay, View.VISIBLE)
                views.setOnClickPendingIntent(R.id.widget_prayer_root, contentPi)
                ArinWidgetTheme.apply(
                    views,
                    widgetData,
                    R.id.widget_prayer_root,
                    intArrayOf(
                        R.id.widget_prayer_next_name,
                        R.id.widget_prayer_countdown,
                        R.id.widget_prayer_location,
                        R.id.widget_lock_note,
                    ),
                )
                appWidgetManager.updateAppWidget(widgetId, views)
                continue
            }
            views.setViewVisibility(R.id.widget_lock_overlay, View.GONE)
            views.setViewVisibility(R.id.widget_prayer_content, View.VISIBLE)
            val safeNextName = if (scheduleExpired) {
                "Güncelle"
            } else if (forceTurkish) {
                "İmsak"
            } else {
                toTurkishPrayerName(nextName)
            }
            val safeLocation = displayLocation.ifEmpty { "Konum" }
            views.setTextViewText(R.id.widget_prayer_next_name, safeNextName.ifEmpty { "—" })
            if (canUseChronometer) {
                val base = SystemClock.elapsedRealtime() + remMs!!
                views.setChronometer(R.id.widget_prayer_countdown, base, null, true)
                // OEM launcher farklılıklarında XML'deki countDown flag'i kaybolabiliyor.
                // Koddan da zorlayarak "-" ile negatif geri sayımı engelleriz.
                views.setChronometerCountDown(R.id.widget_prayer_countdown, true)
            } else {
                views.setTextViewText(
                    R.id.widget_prayer_countdown,
                    if (scheduleExpired) "Uygulamayı aç" else countdown.ifEmpty { "0:00:00" },
                )
            }
            views.setTextViewText(R.id.widget_prayer_location, safeLocation)
            views.setOnClickPendingIntent(R.id.widget_prayer_root, contentPi)
            ArinWidgetTheme.apply(
                views,
                widgetData,
                R.id.widget_prayer_root,
                intArrayOf(
                    R.id.widget_prayer_next_name,
                    R.id.widget_prayer_countdown,
                    R.id.widget_prayer_location,
                    R.id.widget_lock_note,
                ),
            )
            appWidgetManager.updateAppWidget(widgetId, views)
        }

        val gateRefresh = gateRefreshMs(widgetData, "prayer")
        if (canUseChronometer) {
            cancelTickAlarm(context)
            val prayerRefresh = epochMs!! + 1_000L
            scheduleDeadlineRefresh(
                context,
                listOfNotNull(prayerRefresh, gateRefresh).minOrNull() ?: prayerRefresh,
                alarmManager,
                alreadyOffset = true,
            )
        } else if (epochMs != null && epochMs > System.currentTimeMillis()) {
            cancelDeadlineRefresh(context)
            if (gateRefresh != null && gateRefresh < System.currentTimeMillis() + TICK_INTERVAL_MS) {
                cancelTickAlarm(context)
                scheduleDeadlineRefresh(context, gateRefresh, alarmManager, alreadyOffset = true)
            } else {
                scheduleTicks(context)
            }
        } else if (gateRefresh != null) {
            cancelTickAlarm(context)
            scheduleDeadlineRefresh(context, gateRefresh, alarmManager, alreadyOffset = true)
        } else {
            cancelDeadlineRefresh(context)
            cancelTickAlarm(context)
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            scheduleTicks(context)
        }
    }

    override fun onDisabled(context: Context) {
        cancelTickAlarm(context)
        cancelDeadlineRefresh(context)
        super.onDisabled(context)
    }

    private fun scheduleTicks(context: Context) {
        cancelTickAlarm(context)
        val awm = AppWidgetManager.getInstance(context)
        val component = ComponentName(context, ArinPrayerWidgetProvider::class.java)
        val ids = awm.getAppWidgetIds(component)
        if (ids.isEmpty()) return

        val intent = Intent(context, ArinPrayerWidgetProvider::class.java).apply {
            action = ACTION_TICK
        }
        val pi = PendingIntent.getBroadcast(
            context,
            REQUEST_CODE_TICK,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_IMMUTABLE
                } else {
                    0
                },
        )
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val triggerAt = SystemClock.elapsedRealtime() + TICK_INTERVAL_MS
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                am.setAndAllowWhileIdle(
                    AlarmManager.ELAPSED_REALTIME_WAKEUP,
                    triggerAt,
                    pi,
                )
            } else {
                @Suppress("DEPRECATION")
                am.set(AlarmManager.ELAPSED_REALTIME_WAKEUP, triggerAt, pi)
            }
        } catch (_: Exception) {
            @Suppress("DEPRECATION")
            am.set(AlarmManager.ELAPSED_REALTIME_WAKEUP, triggerAt, pi)
        }
    }

    private fun cancelTickAlarm(context: Context) {
        val intent = Intent(context, ArinPrayerWidgetProvider::class.java).apply {
            action = ACTION_TICK
        }
        val pi = PendingIntent.getBroadcast(
            context,
            REQUEST_CODE_TICK,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_IMMUTABLE
                } else {
                    0
                },
        )
        (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(pi)
    }

    private fun scheduleDeadlineRefresh(
        context: Context,
        epochMs: Long,
        am: AlarmManager,
        alreadyOffset: Boolean = false,
    ) {
        cancelDeadlineRefresh(context)
        val now = System.currentTimeMillis()
        val triggerAt = (if (alreadyOffset) epochMs else epochMs + 1_000L)
            .coerceAtLeast(now + 200L)
        val intent = Intent(context, ArinPrayerWidgetProvider::class.java).apply {
            action = ACTION_DEADLINE_REFRESH
        }
        val pi = PendingIntent.getBroadcast(
            context,
            REQUEST_CODE_DEADLINE_REFRESH,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_IMMUTABLE
                } else {
                    0
                },
        )
        try {
            val canExact =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    am.canScheduleExactAlarms()
                } else {
                    true
                }
            if (canExact) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
                } else {
                    @Suppress("DEPRECATION")
                    am.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pi)
                }
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
            } else {
                @Suppress("DEPRECATION")
                am.set(AlarmManager.RTC_WAKEUP, triggerAt, pi)
            }
        } catch (_: Exception) {
            @Suppress("DEPRECATION")
            am.set(AlarmManager.RTC_WAKEUP, triggerAt, pi)
        }
    }

    private fun cancelDeadlineRefresh(context: Context) {
        val intent = Intent(context, ArinPrayerWidgetProvider::class.java).apply {
            action = ACTION_DEADLINE_REFRESH
        }
        val pi = PendingIntent.getBroadcast(
            context,
            REQUEST_CODE_DEADLINE_REFRESH,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_IMMUTABLE
                } else {
                    0
                },
        )
        (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(pi)
    }

    private fun formatHms(ms: Long): String {
        val totalSec = (ms / 1000L).toInt().coerceAtLeast(0)
        val h = totalSec / 3600
        val m = (totalSec % 3600) / 60
        val s = totalSec % 60
        return "$h:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}"
    }

    private fun sanitizeCountdownLabel(raw: String): String {
        val t = raw.trim()
        if (t.isEmpty() || t == "—") return t
        val noMinus = if (t.startsWith("-")) t.removePrefix("-") else t
        val hms = Regex("""^\d+:\d{2}:\d{2}$""")
        return if (hms.matches(noMinus)) noMinus else "0:00:00"
    }

    private fun recordFirstUse(widgetData: SharedPreferences, kind: String) {
        val key = "arin_widget_first_use_ms_$kind"
        val existing = widgetData.getString(key, null)?.toLongOrNull() ?: 0L
        val now = System.currentTimeMillis().toString()
        val editor = widgetData.edit()
            .putString("arin_widget_home_last_render_ms_$kind", now)
        if (existing <= 0L) editor.putString(key, now)
        editor.apply()
    }

    private fun firstUseMs(widgetData: SharedPreferences, kind: String): Long {
        return widgetData.getString("arin_widget_first_use_ms_$kind", null)
            ?.toLongOrNull() ?: 0L
    }

    private fun isWidgetLocked(widgetData: SharedPreferences, kind: String): Boolean {
        if (widgetData.getString(KEY_GATE_PREMIUM, null) == "1") return false
        if (widgetData.getString(KEY_GATE_GLOBAL_LOCKED, null) == "1") return true
        val now = System.currentTimeMillis()
        val unlockUntil = widgetData.getString("arin_widget_gate_${kind}_unlock_until_ms", null)
            ?.toLongOrNull() ?: 0L
        if (unlockUntil > now) return false
        if (widgetData.getString(KEY_GATE_LOCKED, null) == "1") return true
        val firstUse = firstUseMs(widgetData, kind)
        if (firstUse <= 0L) return false
        val trialEnd = firstUse + WIDGET_TRIAL_DURATION_MS
        return now >= trialEnd
    }

    private fun gateRefreshMs(widgetData: SharedPreferences, kind: String): Long? {
        if (widgetData.getString(KEY_GATE_PREMIUM, null) == "1") return null
        val now = System.currentTimeMillis()
        val firstUse = firstUseMs(widgetData, kind)
        val trialEnd = if (firstUse > 0L) firstUse + WIDGET_TRIAL_DURATION_MS else 0L
        val unlockUntil = widgetData.getString("arin_widget_gate_${kind}_unlock_until_ms", null)
            ?.toLongOrNull() ?: 0L
        return listOf(trialEnd, unlockUntil).filter { it > now }.minOrNull()?.plus(1_000L)
    }

    private fun readScheduledPrayer(
        widgetData: SharedPreferences,
        nowMs: Long,
    ): ScheduledPrayer? {
        val raw = widgetData.getString(KEY_PRAYER_SCHEDULE, null)?.trim().orEmpty()
        if (raw.isEmpty()) return null
        return try {
            val root = JSONObject(raw)
            val location = root.optString("location", "").trim()
            val entries = root.optJSONArray("entries") ?: return null
            for (i in 0 until entries.length()) {
                val obj = entries.optJSONObject(i) ?: continue
                val epoch = obj.optLong("epochMs", 0L)
                val name = obj.optString("name", "").trim()
                if (epoch > nowMs && name.isNotEmpty()) {
                    return ScheduledPrayer(
                        name = name,
                        epochMs = epoch,
                        location = location.ifEmpty { null },
                        expired = false,
                    )
                }
            }
            ScheduledPrayer(
                name = "Güncelle",
                epochMs = null,
                location = location.ifEmpty { null },
                expired = true,
            )
        } catch (_: Exception) {
            null
        }
    }

    private fun containsArabic(s: String): Boolean = s.any { ch ->
        ch.code in 0x0600..0x06FF
    }

    private fun toTurkishPrayerName(raw: String): String {
        val t = raw.trim()
        if (t.isEmpty()) return "İmsak"
        if (containsArabic(t)) return "İmsak"
        // Türkçe 'İ' düzeltmesi: lowercase() "İkindi" -> "i̇kindi" (birleşik
        // noktalı i) ürettiği için "ikindi" ile eşleşmiyordu; İ/I önce elle
        // Türkçe kurala göre indirilir.
        return when (t.replace('İ', 'i').replace('I', 'ı').lowercase()) {
            "fajr" -> "İmsak"
            "sunrise" -> "Güneş"
            "dhuhr" -> "Öğle"
            "asr" -> "İkindi"
            "maghrib" -> "Akşam"
            "isha" -> "Yatsı"
            "imsak" -> "İmsak"
            "güneş" -> "Güneş"
            "öğle" -> "Öğle"
            "ikindi" -> "İkindi"
            "akşam" -> "Akşam"
            "yatsı" -> "Yatsı"
            else -> "Vakit"
        }
    }

    private data class ScheduledPrayer(
        val name: String,
        val epochMs: Long?,
        val location: String?,
        val expired: Boolean,
    )

    companion object {
        private const val KEY_LOCATION = "arin_prayer_location"
        private const val KEY_NEXT_NAME = "arin_prayer_next_name"
        private const val KEY_COUNTDOWN = "arin_prayer_countdown"
        private const val KEY_NEXT_EPOCH = "arin_prayer_next_epoch_ms"
        private const val KEY_PRAYER_SCHEDULE = "arin_prayer_schedule_json"
        private const val KEY_LOCALE = "arin_widget_locale"
        private const val KEY_GATE_LOCKED = "arin_widget_gate_prayer_locked"
        private const val KEY_GATE_PREMIUM = "arin_widget_gate_premium"
        private const val KEY_GATE_GLOBAL_LOCKED = "arin_widget_gate_global_locked"
        private const val WIDGET_TRIAL_DURATION_MS = 24L * 60L * 60L * 1000L

        private const val ACTION_TICK = "com.arin.arin.action.PRAYER_WIDGET_TICK"
        private const val ACTION_DEADLINE_REFRESH =
            "com.arin.arin.action.PRAYER_WIDGET_DEADLINE_REFRESH"
        private const val REQUEST_CODE_TICK = 19021
        private const val REQUEST_CODE_DEADLINE_REFRESH = 19022
        /** Kronometreyi sıfır sınırına sokmadan önce statik moda geçiş tamponu. */
        private const val DEADLINE_GUARD_MS = 1500L
        /** API 23 / chronometer fallback: dakikalık coarse güncelleme. */
        private const val TICK_INTERVAL_MS = 60_000L

        fun requestUpdate(context: Context) {
            val awm = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, ArinPrayerWidgetProvider::class.java)
            val ids = awm.getAppWidgetIds(component)
            if (ids.isEmpty()) return
            val update = Intent(context, ArinPrayerWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
            context.sendBroadcast(update)
        }
    }
}

class ArinWidgetRestoreReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            action == Intent.ACTION_TIME_CHANGED ||
            action == Intent.ACTION_TIMEZONE_CHANGED ||
            action == Intent.ACTION_LOCALE_CHANGED ||
            action == "android.intent.action.QUICKBOOT_POWERON" ||
            action == "com.htc.intent.action.QUICKBOOT_POWERON"
        ) {
            val appContext = context.applicationContext
            ArinPrayerWidgetProvider.requestUpdate(appContext)
            ArinQuoteWidgetProvider.requestUpdate(appContext)
            ArinComboWidgetProvider.requestUpdate(appContext)
            ArinTrackingWidgetProvider.requestUpdate(appContext)
            ArinZikirWidgetProvider.requestUpdate(appContext)
            // Kilit ekranı bildirimleri AppWidgetProvider'a bağlı değil; boot/saat/
            // dil değişiminde kendi alarm'larını da burada yeniden kurmamız gerekir.
            ArinLockNotifications.syncAll(appContext)
        }
    }
}
