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
import org.json.JSONObject
import java.util.Calendar

class ArinEsmaWidgetProvider : HomeWidgetProvider() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_MIDNIGHT_REFRESH) {
            requestUpdate(context)
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
        recordFirstUse(widgetData, "quote")
        val locked = isWidgetLocked(widgetData, "quote")
        val (arabic, turkish) = resolveName(widgetData)
        val openApp = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(MainActivity.EXTRA_WIDGET_KIND, "quote")
            if (locked) putExtra(MainActivity.EXTRA_WIDGET_LOCK, "1")
        }
        val piFlags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_IMMUTABLE
            } else {
                0
            }
        val contentPi = PendingIntent.getActivity(context, 8, openApp, piFlags)

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.arin_esma_widget)
            if (locked) {
                views.setViewVisibility(R.id.widget_esma_content, View.GONE)
                views.setViewVisibility(R.id.widget_lock_overlay, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_lock_overlay, View.GONE)
                views.setViewVisibility(R.id.widget_esma_content, View.VISIBLE)
                views.setTextViewText(R.id.widget_esma_arabic, arabic)
                views.setTextViewText(R.id.widget_esma_turkish, turkish)
            }
            views.setOnClickPendingIntent(R.id.widget_esma_root, contentPi)
            ArinWidgetTheme.apply(
                views,
                widgetData,
                R.id.widget_esma_root,
                intArrayOf(
                    R.id.widget_esma_arabic,
                    R.id.widget_esma_turkish,
                    R.id.widget_esma_label,
                    R.id.widget_lock_note,
                ),
            )
            appWidgetManager.updateAppWidget(widgetId, views)
        }
        scheduleMidnightRefresh(context)
    }

    override fun onDisabled(context: Context) {
        cancelMidnightRefresh(context)
        super.onDisabled(context)
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
        if (widgetData.getString("arin_widget_gate_premium", null) == "1") return false
        if (widgetData.getString("arin_widget_gate_global_locked", null) == "1") return true
        val now = System.currentTimeMillis()
        val unlockUntil = widgetData.getString("arin_widget_gate_${kind}_unlock_until_ms", null)
            ?.toLongOrNull() ?: 0L
        if (unlockUntil > now) return false
        if (widgetData.getString("arin_widget_gate_quote_locked", null) == "1") return true
        val firstUse = firstUseMs(widgetData, kind)
        if (firstUse <= 0L) return false
        return now >= firstUse + (24L * 60L * 60L * 1000L)
    }

    private fun resolveName(widgetData: SharedPreferences): Pair<String, String> {
        val fallbackArabic = widgetData.getString(KEY_ARABIC, null)?.trim().orEmpty()
            .ifEmpty { "الرحمن" }
        val fallbackTurkish = widgetData.getString(KEY_TURKISH, null)?.trim().orEmpty()
            .ifEmpty { "Er-Rahmân" }
        val raw = widgetData.getString(KEY_SCHEDULE, null)?.trim().orEmpty()
        if (raw.isEmpty()) return fallbackArabic to fallbackTurkish
        return try {
            val entries = JSONObject(raw).optJSONArray("entries")
            val today = todayYmd()
            if (entries != null) {
                for (i in 0 until entries.length()) {
                    val obj = entries.optJSONObject(i) ?: continue
                    if (obj.optString("day") == today) {
                        val arabic = obj.optString("arabic").trim()
                        val turkish = obj.optString("turkish").trim()
                        if (arabic.isNotEmpty() && turkish.isNotEmpty()) {
                            return arabic to turkish
                        }
                    }
                }
            }
            fallbackArabic to fallbackTurkish
        } catch (_: Exception) {
            fallbackArabic to fallbackTurkish
        }
    }

    companion object {
        private const val KEY_ARABIC = "arin_esma_arabic"
        private const val KEY_TURKISH = "arin_esma_turkish"
        private const val KEY_SCHEDULE = "arin_esma_schedule_json"
        private const val ACTION_MIDNIGHT_REFRESH =
            "com.arin.arin.action.ESMA_WIDGET_MIDNIGHT"
        private const val REQUEST_CODE_MIDNIGHT = 19031

        fun requestUpdate(context: Context) {
            val awm = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, ArinEsmaWidgetProvider::class.java)
            val ids = awm.getAppWidgetIds(component)
            if (ids.isEmpty()) return
            val update = Intent(context, ArinEsmaWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
            context.sendBroadcast(update)
        }

        private fun todayYmd(): String {
            val cal = Calendar.getInstance()
            val y = cal.get(Calendar.YEAR)
            val m = (cal.get(Calendar.MONTH) + 1).toString().padStart(2, '0')
            val d = cal.get(Calendar.DAY_OF_MONTH).toString().padStart(2, '0')
            return "$y-$m-$d"
        }

        private fun midnightIntent(context: Context): PendingIntent {
            val intent = Intent(context, ArinEsmaWidgetProvider::class.java).apply {
                action = ACTION_MIDNIGHT_REFRESH
            }
            return PendingIntent.getBroadcast(
                context,
                REQUEST_CODE_MIDNIGHT,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        PendingIntent.FLAG_IMMUTABLE
                    } else {
                        0
                    },
            )
        }

        private fun scheduleMidnightRefresh(context: Context) {
            val cal = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR, 1)
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 1)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val triggerAt = SystemClock.elapsedRealtime() +
                (cal.timeInMillis - System.currentTimeMillis()).coerceAtLeast(60_000L)
            val pi = midnightIntent(context)
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

        private fun cancelMidnightRefresh(context: Context) {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            am.cancel(midnightIntent(context))
        }
    }
}
