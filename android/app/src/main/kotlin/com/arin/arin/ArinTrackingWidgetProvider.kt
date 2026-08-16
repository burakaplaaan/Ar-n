package com.arin.arin

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import java.util.Calendar
import java.util.concurrent.TimeUnit

/**
 * Tek seçili Gelişim/Arınma takibi: kısa sayaç + günlük motivasyon.
 */
class ArinTrackingWidgetProvider : HomeWidgetProvider() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_REFRESH) {
            requestUpdate(context.applicationContext)
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
        recordFirstUse(widgetData, "tracking")
        val locked = isWidgetLocked(widgetData, "tracking")
        val entry = if (locked) null else loadEntry(widgetData)
        val openApp = Intent(context, MainActivity::class.java).apply {
            // SINGLE_TOP: arka plandaki singleTop MainActivity'ye yeni intent
            // onNewIntent ile ulaşsın (güncel kind/lock iletilsin).
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(MainActivity.EXTRA_WIDGET_KIND, "tracking")
            if (locked) {
                putExtra(MainActivity.EXTRA_WIDGET_LOCK, "1")
            }
        }
        val piFlags =
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    android.app.PendingIntent.FLAG_IMMUTABLE
                } else {
                    0
                }
        val contentPi = android.app.PendingIntent.getActivity(context, 4, openApp, piFlags)

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.arin_tracking_widget)
            if (locked) {
                views.setViewVisibility(R.id.widget_tracking_content, View.GONE)
                views.setViewVisibility(R.id.widget_lock_overlay, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_lock_overlay, View.GONE)
                views.setViewVisibility(R.id.widget_tracking_content, View.VISIBLE)
                val e = entry!!
                views.setTextViewText(R.id.widget_tracking_title, e.title)
                views.setTextViewText(R.id.widget_tracking_value, e.value)
                views.setTextViewText(R.id.widget_tracking_note, e.note)
                views.setViewVisibility(
                    R.id.widget_tracking_value,
                    if (e.value.isEmpty()) View.GONE else View.VISIBLE,
                )
            }
            views.setOnClickPendingIntent(R.id.widget_tracking_root, contentPi)
            ArinWidgetTheme.apply(
                views,
                widgetData,
                R.id.widget_tracking_root,
                intArrayOf(
                    R.id.widget_tracking_title,
                    R.id.widget_tracking_value,
                    R.id.widget_tracking_note,
                    R.id.widget_lock_note,
                ),
            )
            appWidgetManager.updateAppWidget(widgetId, views)
        }

        if (locked || entry?.enabled == true) {
            scheduleNextRefresh(context, widgetData)
        } else {
            cancelRefresh(context)
        }
    }

    override fun onDisabled(context: Context) {
        cancelRefresh(context)
        super.onDisabled(context)
    }

    private fun loadEntry(widgetData: SharedPreferences): TrackingEntry {
        val enabled = widgetData.getString(KEY_ENABLED, null) == "1"
        if (!enabled) {
            return TrackingEntry(
                enabled = false,
                title = "Takip seçilmedi",
                value = "",
                note = "Ayarlar > Widget Merkezi",
            )
        }

        val title = widgetData.getString(KEY_TITLE, null)?.trim().orEmpty()
        val mode = widgetData.getString(KEY_MODE, null)?.trim().orEmpty()
        val value = if (mode == "quit_days") {
            val start = widgetData.getString(KEY_START_EPOCH, null)?.toLongOrNull()
            val prefix = widgetData.getString(KEY_DAY_PREFIX, null)?.trim().orEmpty()
            if (start != null && start > 0L && prefix.isNotEmpty()) {
                // 1-tabanlı sayaç: başlanan ilk gün "1. gün". Flutter tarafıyla
                // (TrackingWidgetService) birebir aynı olması için +1.
                val days = TimeUnit.MILLISECONDS.toDays(
                    (System.currentTimeMillis() - start).coerceAtLeast(0L),
                ) + 1
                "$prefix $days. gün"
            } else {
                widgetData.getString(KEY_VALUE, null)?.trim().orEmpty()
            }
        } else {
            widgetData.getString(KEY_VALUE, null)?.trim().orEmpty()
        }
        val note = dailyQuote(widgetData) ?: widgetData.getString(KEY_NOTE, null)?.trim().orEmpty()
        return TrackingEntry(
            enabled = true,
            title = title.ifEmpty { "ARIN Takip" },
            value = value,
            note = note.ifEmpty { "Bugün küçük bir adım yeter." },
        )
    }

    private fun dailyQuote(widgetData: SharedPreferences): String? {
        val raw = widgetData.getString(KEY_QUOTES_JSON, null)?.trim().orEmpty()
        if (raw.isEmpty()) return null
        return try {
            val arr = JSONArray(raw)
            if (arr.length() == 0) return null
            val day = Calendar.getInstance().get(Calendar.DAY_OF_YEAR)
            arr.optString((day - 1).coerceAtLeast(0) % arr.length()).trim().takeIf { it.isNotEmpty() }
        } catch (_: Exception) {
            null
        }
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

    private data class TrackingEntry(
        val enabled: Boolean,
        val title: String,
        val value: String,
        val note: String,
    )

    private fun scheduleNextRefresh(context: Context, widgetData: SharedPreferences) {
        cancelRefresh(context)
        val now = System.currentTimeMillis()
        val cal = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 1)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val nextDay = cal.timeInMillis.coerceAtLeast(now + 60_000L)
        val gate = gateRefreshMs(widgetData, "tracking")
        val triggerAt = listOfNotNull(nextDay, gate).filter { it > now }.minOrNull()
            ?.coerceAtLeast(now + 1_000L)
            ?: (now + 60_000L)
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, refreshPendingIntent(context))
            } else {
                @Suppress("DEPRECATION")
                am.set(AlarmManager.RTC_WAKEUP, triggerAt, refreshPendingIntent(context))
            }
        } catch (_: Exception) {
            @Suppress("DEPRECATION")
            am.set(AlarmManager.RTC_WAKEUP, triggerAt, refreshPendingIntent(context))
        }
    }

    private fun cancelRefresh(context: Context) {
        (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(
            refreshPendingIntent(context),
        )
    }

    private fun refreshPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, ArinTrackingWidgetProvider::class.java).apply {
            action = ACTION_REFRESH
        }
        return PendingIntent.getBroadcast(
            context,
            REQUEST_CODE_REFRESH,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_IMMUTABLE
                } else {
                    0
                },
        )
    }

    companion object {
        private const val KEY_ENABLED = "arin_tracking_enabled"
        private const val KEY_TITLE = "arin_tracking_title"
        private const val KEY_VALUE = "arin_tracking_value"
        private const val KEY_NOTE = "arin_tracking_note"
        private const val KEY_QUOTES_JSON = "arin_tracking_quotes_json"
        private const val KEY_MODE = "arin_tracking_mode"
        private const val KEY_START_EPOCH = "arin_tracking_start_epoch_ms"
        private const val KEY_DAY_PREFIX = "arin_tracking_day_prefix"
        private const val KEY_GATE_LOCKED = "arin_widget_gate_tracking_locked"
        private const val KEY_GATE_PREMIUM = "arin_widget_gate_premium"
        private const val KEY_GATE_GLOBAL_LOCKED = "arin_widget_gate_global_locked"
        private const val WIDGET_TRIAL_DURATION_MS = 24L * 60L * 60L * 1000L
        private const val ACTION_REFRESH = "com.arin.arin.action.TRACKING_WIDGET_REFRESH"
        private const val REQUEST_CODE_REFRESH = 19041

        fun requestUpdate(context: Context) {
            val awm = AppWidgetManager.getInstance(context)
            val cn = ComponentName(context, ArinTrackingWidgetProvider::class.java)
            val ids = awm.getAppWidgetIds(cn)
            if (ids.isEmpty()) return
            val update = Intent(context, ArinTrackingWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
            context.sendBroadcast(update)
        }
    }
}
