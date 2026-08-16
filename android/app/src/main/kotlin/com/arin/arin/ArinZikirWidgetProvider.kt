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
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Zikirmatik widget: renksiz beyaz silüet + kümülatif sayaç + "+1" butonu.
 *
 * TEK paylaşılan otorite [KEY_COUNT] (kümülatif toplam). "+1" butonu uygulamayı
 * açmadan bu değeri artırır; uygulama foreground'a dönünce ([ZikirWidgetService]
 * üzerinden) okuyup oturumu kaldığı yerden devam ettirir.
 */
class ArinZikirWidgetProvider : HomeWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_TICK -> {
                handleTick(context.applicationContext)
                return
            }
            ACTION_REFRESH -> {
                requestUpdate(context.applicationContext)
                return
            }
        }
        super.onReceive(context, intent)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        recordFirstUse(widgetData, KIND)
        val locked = isWidgetLocked(widgetData, KIND)

        val phrase = widgetData.getString(KEY_PHRASE, null)?.trim().orEmpty()
            .ifEmpty { context.getString(R.string.widget_zikir_phrase_fallback) }
        val count = widgetData.getString(KEY_COUNT, null)?.toIntOrNull() ?: 0
        val lockNote = widgetData.getString(KEY_GATE_LOCK_NOTE, null)?.trim().orEmpty()
            .ifEmpty { context.getString(R.string.widget_lock_tap_to_unlock) }

        val openApp = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(MainActivity.EXTRA_WIDGET_KIND, KIND)
            if (locked) {
                putExtra(MainActivity.EXTRA_WIDGET_LOCK, "1")
            }
        }
        val piFlags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_IMMUTABLE
            } else {
                0
            }
        val contentPi = PendingIntent.getActivity(context, REQ_OPEN, openApp, piFlags)

        // Kilitliyken "+1" de unlock akışına gitsin; açıkken broadcast ile say.
        val tickPi = if (locked) {
            PendingIntent.getActivity(context, REQ_TICK_LOCKED, openApp, piFlags)
        } else {
            val tick = Intent(context, ArinZikirWidgetProvider::class.java).apply {
                action = ACTION_TICK
            }
            PendingIntent.getBroadcast(context, REQ_TICK, tick, piFlags)
        }

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.arin_zikir_widget)
            if (locked) {
                views.setViewVisibility(R.id.widget_lock_overlay, View.VISIBLE)
                views.setViewVisibility(R.id.widget_zikir_content, View.GONE)
                views.setTextViewText(R.id.widget_lock_note, lockNote)
            } else {
                views.setViewVisibility(R.id.widget_lock_overlay, View.GONE)
                views.setViewVisibility(R.id.widget_zikir_content, View.VISIBLE)
                views.setTextViewText(R.id.widget_zikir_phrase, phrase)
                views.setTextViewText(R.id.widget_zikir_count, count.toString())
            }
            views.setOnClickPendingIntent(R.id.widget_zikir_root, contentPi)
            views.setOnClickPendingIntent(R.id.widget_zikir_tick, tickPi)
            ArinWidgetTheme.apply(
                views,
                widgetData,
                R.id.widget_zikir_root,
                intArrayOf(
                    R.id.widget_zikir_phrase,
                    R.id.widget_zikir_count,
                    R.id.widget_lock_note,
                ),
            )
            appWidgetManager.updateAppWidget(widgetId, views)
        }

        scheduleNextRefresh(context, widgetData)
    }

    override fun onDisabled(context: Context) {
        cancelRefresh(context)
        super.onDisabled(context)
    }

    /** "+1": kümülatif sayacı uygulama açmadan artırır. */
    private fun handleTick(context: Context) {
        val prefs = HomeWidgetPlugin.getData(context)
        if (isWidgetLocked(prefs, KIND)) {
            // Kilitli: sayma; yalnızca yeniden çiz (overlay görünür).
            requestUpdate(context)
            return
        }
        val total = prefs.getString(KEY_COUNT, null)?.toIntOrNull() ?: 0
        var round = prefs.getString(KEY_ROUND, null)?.toIntOrNull() ?: 0
        var tur = prefs.getString(KEY_TUR, null)?.toIntOrNull() ?: 1
        val target = (prefs.getString(KEY_TARGET, null)?.toIntOrNull() ?: 33)
            .coerceAtLeast(1)

        val newTotal = (total + 1).coerceAtMost(999999)
        round += 1
        if (round >= target) {
            round = 0
            tur += 1
        }
        prefs.edit()
            .putString(KEY_ENABLED, "1")
            .putString(KEY_COUNT, newTotal.toString())
            .putString(KEY_ROUND, round.toString())
            .putString(KEY_TUR, tur.toString())
            .apply()
        requestUpdate(context)
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

    private fun scheduleNextRefresh(context: Context, widgetData: SharedPreferences) {
        cancelRefresh(context)
        val now = System.currentTimeMillis()
        val triggerAt = gateRefreshMs(widgetData, KIND) ?: return
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val at = triggerAt.coerceAtLeast(now + 1_000L)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, refreshPendingIntent(context))
            } else {
                @Suppress("DEPRECATION")
                am.set(AlarmManager.RTC_WAKEUP, at, refreshPendingIntent(context))
            }
        } catch (_: Exception) {
            @Suppress("DEPRECATION")
            am.set(AlarmManager.RTC_WAKEUP, at, refreshPendingIntent(context))
        }
    }

    private fun cancelRefresh(context: Context) {
        (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(
            refreshPendingIntent(context),
        )
    }

    private fun refreshPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, ArinZikirWidgetProvider::class.java).apply {
            action = ACTION_REFRESH
        }
        return PendingIntent.getBroadcast(
            context,
            REQ_REFRESH,
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
        private const val KIND = "zikir"
        private const val KEY_ENABLED = "arin_zikir_enabled"
        private const val KEY_PHRASE = "arin_zikir_phrase"
        private const val KEY_COUNT = "arin_zikir_count"
        private const val KEY_ROUND = "arin_zikir_round"
        private const val KEY_TUR = "arin_zikir_tur"
        private const val KEY_TARGET = "arin_zikir_target"
        private const val KEY_GATE_LOCKED = "arin_widget_gate_zikir_locked"
        private const val KEY_GATE_PREMIUM = "arin_widget_gate_premium"
        private const val KEY_GATE_GLOBAL_LOCKED = "arin_widget_gate_global_locked"
        private const val KEY_GATE_LOCK_NOTE = "arin_widget_gate_lock_note"
        private const val WIDGET_TRIAL_DURATION_MS = 24L * 60L * 60L * 1000L

        private const val ACTION_TICK = "com.arin.arin.action.ZIKIR_WIDGET_TICK"
        private const val ACTION_REFRESH = "com.arin.arin.action.ZIKIR_WIDGET_REFRESH"

        private const val REQ_OPEN = 7
        private const val REQ_TICK = 8
        private const val REQ_TICK_LOCKED = 9
        private const val REQ_REFRESH = 19061

        fun requestUpdate(context: Context) {
            val awm = AppWidgetManager.getInstance(context)
            val cn = ComponentName(context, ArinZikirWidgetProvider::class.java)
            val ids = awm.getAppWidgetIds(cn)
            if (ids.isEmpty()) return
            val update = Intent(context, ArinZikirWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
            context.sendBroadcast(update)
        }
    }
}
