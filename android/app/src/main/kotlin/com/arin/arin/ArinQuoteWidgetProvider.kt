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
import org.json.JSONObject

/**
 * Söz / ayet widget: Flutter [HomeWidget.saveWidgetData] ile
 * `arin_quote_text` / `arin_quote_source`.
 */
class ArinQuoteWidgetProvider : HomeWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_REFRESH) {
            val awm = AppWidgetManager.getInstance(context)
            val cn = ComponentName(context, ArinQuoteWidgetProvider::class.java)
            val ids = awm.getAppWidgetIds(cn)
            if (ids.isNotEmpty()) {
                val update = Intent(context, ArinQuoteWidgetProvider::class.java).apply {
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
        val scheduled = readScheduledQuote(widgetData, System.currentTimeMillis())
        val quote = scheduled?.quote ?: buildDisplayQuote(
            rawText = widgetData.getString(KEY_QUOTE_TEXT, null),
            rawSource = widgetData.getString(KEY_QUOTE_SOURCE, null),
        )
        val locked = isWidgetLocked(widgetData, "quote")
        val openApp = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(MainActivity.EXTRA_WIDGET_KIND, "quote")
        }
        val piFlags =
            PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_IMMUTABLE
                } else {
                    0
                }
        val contentPi = PendingIntent.getActivity(context, 0, openApp, piFlags)

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.arin_quote_widget)
            views.setTextViewText(
                R.id.widget_quote_text,
                if (locked) "Açmak için dokun" else quote.text,
            )
            views.setTextViewText(
                R.id.widget_quote_source,
                if (locked) "🔒 Widget kilitli" else quote.source,
            )
            views.setViewVisibility(
                R.id.widget_quote_header_row,
                if (locked || quote.showSource) {
                    View.VISIBLE
                } else {
                    View.GONE
                },
            )
            views.setOnClickPendingIntent(R.id.widget_root, contentPi)
            appWidgetManager.updateAppWidget(widgetId, views)
        }

        val gateRefresh = gateRefreshMs(widgetData, "quote")
        val nextRefresh = listOfNotNull(scheduled?.nextEpochMs, gateRefresh).minOrNull()
        nextRefresh?.let { scheduleRefresh(context, it) } ?: cancelRefresh(context)
    }

    override fun onDisabled(context: Context) {
        cancelRefresh(context)
        super.onDisabled(context)
    }

    private fun readScheduledQuote(
        widgetData: SharedPreferences,
        nowMs: Long,
    ): ScheduledQuote? {
        val raw = widgetData.getString(KEY_QUOTE_SCHEDULE, null)?.trim().orEmpty()
        if (raw.isEmpty()) return null
        return try {
            val entries = JSONObject(raw).optJSONArray("entries") ?: return null
            var current: DisplayQuote? = null
            var nextEpochMs: Long? = null
            var first: DisplayQuote? = null
            for (i in 0 until entries.length()) {
                val obj = entries.optJSONObject(i) ?: continue
                val epoch = obj.optLong("epochMs", 0L)
                val text = obj.optString("text", "").trim()
                val source = obj.optString("source", "").trim()
                if (epoch <= 0L || text.isEmpty()) continue
                val quote = buildDisplayQuote(rawText = text, rawSource = source)
                if (first == null) first = quote
                if (epoch <= nowMs) {
                    current = quote
                } else {
                    nextEpochMs = epoch
                    break
                }
            }
            val quote = current ?: first ?: return null
            ScheduledQuote(quote = quote, nextEpochMs = nextEpochMs)
        } catch (_: Exception) {
            null
        }
    }

    private fun scheduleRefresh(context: Context, epochMs: Long) {
        cancelRefresh(context)
        val now = System.currentTimeMillis()
        val triggerAt = epochMs.coerceAtLeast(now + 1_000L)
        val pi = refreshPendingIntent(context)
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
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

    private fun cancelRefresh(context: Context) {
        (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(
            refreshPendingIntent(context),
        )
    }

    private fun refreshPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, ArinQuoteWidgetProvider::class.java).apply {
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

    private fun buildDisplayQuote(rawText: String?, rawSource: String?): DisplayQuote {
        val compactText = rawText?.replace(Regex("""\s+"""), " ")?.trim().orEmpty()
        val source = rawSource?.trim().orEmpty()
        if (compactText.isEmpty()) {
            return DisplayQuote(
                text = DEFAULT_QUOTE_TEXT,
                source = DEFAULT_QUOTE_SOURCE,
                showSource = true,
            )
        }

        val text = compactText
        if (source.isNotEmpty()) {
            return DisplayQuote(text = text, source = source, showSource = true)
        }
        return DisplayQuote(text = text, source = "", showSource = false)
    }

    private fun isWidgetLocked(widgetData: SharedPreferences, kind: String): Boolean {
        if (widgetData.getString(KEY_GATE_PREMIUM, null) == "1") return false
        if (widgetData.getString(KEY_GATE_LOCKED, null) == "1") return true
        val now = System.currentTimeMillis()
        val trialUntil = widgetData.getString("arin_widget_gate_${kind}_trial_until_ms", null)
            ?.toLongOrNull() ?: 0L
        val unlockUntil = widgetData.getString("arin_widget_gate_${kind}_unlock_until_ms", null)
            ?.toLongOrNull() ?: 0L
        if (trialUntil <= 0L) return false
        return now >= trialUntil && now >= unlockUntil
    }

    private fun gateRefreshMs(widgetData: SharedPreferences, kind: String): Long? {
        if (widgetData.getString(KEY_GATE_PREMIUM, null) == "1") return null
        val now = System.currentTimeMillis()
        return listOf(
            widgetData.getString("arin_widget_gate_${kind}_trial_until_ms", null)
                ?.toLongOrNull() ?: 0L,
            widgetData.getString("arin_widget_gate_${kind}_unlock_until_ms", null)
                ?.toLongOrNull() ?: 0L,
        ).filter { it > now }.minOrNull()?.plus(1_000L)
    }

    private data class DisplayQuote(
        val text: String,
        val source: String,
        val showSource: Boolean,
    )

    private data class ScheduledQuote(
        val quote: DisplayQuote,
        val nextEpochMs: Long?,
    )

    companion object {
        private const val DEFAULT_QUOTE_SOURCE = "Tâhâ, 46"
        private const val DEFAULT_QUOTE_TEXT = "İşitirim ve görürüm."

        private const val KEY_QUOTE_TEXT = "arin_quote_text"
        private const val KEY_QUOTE_SOURCE = "arin_quote_source"
        private const val KEY_QUOTE_SCHEDULE = "arin_quote_schedule_json"
        private const val KEY_GATE_LOCKED = "arin_widget_gate_quote_locked"
        private const val KEY_GATE_PREMIUM = "arin_widget_gate_premium"
        private const val ACTION_REFRESH = "com.arin.arin.action.QUOTE_WIDGET_REFRESH"
        private const val REQUEST_CODE_REFRESH = 19011

        fun requestUpdate(context: Context) {
            val awm = AppWidgetManager.getInstance(context)
            val cn = ComponentName(context, ArinQuoteWidgetProvider::class.java)
            val ids = awm.getAppWidgetIds(cn)
            if (ids.isEmpty()) return
            val update = Intent(context, ArinQuoteWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
            context.sendBroadcast(update)
        }
    }
}
