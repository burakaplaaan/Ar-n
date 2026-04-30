package com.arin.arin

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

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
        val loc = widgetData.getString(KEY_LOCATION, null)?.trim().orEmpty()
        val localeCode = widgetData.getString(KEY_LOCALE, null)?.trim()?.lowercase().orEmpty()
        val forceTurkish = !localeCode.startsWith("tr")
        val displayLocation = loc.ifEmpty {
            "Konum ayarlanmadı"
        }
        val nextName = widgetData.getString(KEY_NEXT_NAME, null)?.trim().orEmpty()
        val countdownStatic = widgetData.getString(KEY_COUNTDOWN, null)?.trim().orEmpty()

        val epochMs = widgetData.getString(KEY_NEXT_EPOCH, null)?.trim()?.toLongOrNull()
        val nowMs = System.currentTimeMillis()
        val rawRemMs = if (epochMs != null && epochMs > 0L) epochMs - nowMs else null
        val remMs = rawRemMs?.coerceAtLeast(0L)
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val exactAlarmCapable =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                alarmManager.canScheduleExactAlarms()
            } else {
                true
            }

        val countdown = if (remMs != null) {
            formatHms(remMs)
        } else {
            sanitizeCountdownLabel(countdownStatic)
        }

        val canUseChronometer =
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.N &&
                remMs != null &&
                remMs > DEADLINE_GUARD_MS &&
                exactAlarmCapable

        val openApp = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
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
            val safeNextName = if (forceTurkish) "İmsak" else toTurkishPrayerName(nextName)
            val safeLocation = "Konum"
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
                    countdown.ifEmpty { "0:00:00" },
                )
            }
            views.setTextViewText(R.id.widget_prayer_location, safeLocation)
            views.setOnClickPendingIntent(R.id.widget_prayer_root, contentPi)
            appWidgetManager.updateAppWidget(widgetId, views)
        }

        if (canUseChronometer) {
            cancelTickAlarm(context)
            scheduleDeadlineRefresh(context, epochMs!!, alarmManager)
        } else {
            cancelDeadlineRefresh(context)
            scheduleTicks(context)
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
                am.setExactAndAllowWhileIdle(
                    AlarmManager.ELAPSED_REALTIME_WAKEUP,
                    triggerAt,
                    pi,
                )
            } else {
                @Suppress("DEPRECATION")
                am.setExact(AlarmManager.ELAPSED_REALTIME_WAKEUP, triggerAt, pi)
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

    private fun scheduleDeadlineRefresh(context: Context, epochMs: Long, am: AlarmManager) {
        cancelDeadlineRefresh(context)
        val now = System.currentTimeMillis()
        val triggerAt = (epochMs - DEADLINE_GUARD_MS).coerceAtLeast(now + 200L)
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
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
            } else {
                @Suppress("DEPRECATION")
                am.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pi)
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

    private fun containsArabic(s: String): Boolean = s.any { ch ->
        ch.code in 0x0600..0x06FF
    }

    private fun toTurkishPrayerName(raw: String): String {
        val t = raw.trim()
        if (t.isEmpty()) return "İmsak"
        if (containsArabic(t)) return "İmsak"
        return when (t.lowercase()) {
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

    companion object {
        private const val KEY_LOCATION = "arin_prayer_location"
        private const val KEY_NEXT_NAME = "arin_prayer_next_name"
        private const val KEY_COUNTDOWN = "arin_prayer_countdown"
        private const val KEY_NEXT_EPOCH = "arin_prayer_next_epoch_ms"
        private const val KEY_LOCALE = "arin_widget_locale"

        private const val ACTION_TICK = "com.arin.arin.action.PRAYER_WIDGET_TICK"
        private const val ACTION_DEADLINE_REFRESH =
            "com.arin.arin.action.PRAYER_WIDGET_DEADLINE_REFRESH"
        private const val REQUEST_CODE_TICK = 19021
        private const val REQUEST_CODE_DEADLINE_REFRESH = 19022
        /** Kronometreyi sıfır sınırına sokmadan önce statik moda geçiş tamponu. */
        private const val DEADLINE_GUARD_MS = 1500L
        /** API 23 fallback: 15 sn adımlı güncelleme, pil tüketimini dengeler. */
        private const val TICK_INTERVAL_MS = 15_000L
    }
}
