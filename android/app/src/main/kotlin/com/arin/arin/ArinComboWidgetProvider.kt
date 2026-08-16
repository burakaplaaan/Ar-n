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
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import kotlin.math.roundToInt

/**
 * Karma widget: sıradaki namaz vakti + günlük söz.
 * Mevcut `arin_prayer_*` ve `arin_quote_*` anahtarlarını ortak kullanır.
 */
class ArinComboWidgetProvider : HomeWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_TICK || intent.action == ACTION_REFRESH) {
            val awm = AppWidgetManager.getInstance(context)
            val cn = ComponentName(context, ArinComboWidgetProvider::class.java)
            val ids = awm.getAppWidgetIds(cn)
            if (ids.isNotEmpty()) {
                val update = Intent(context, ArinComboWidgetProvider::class.java).apply {
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
        recordFirstUse(widgetData, "combo")
        val nowMs = System.currentTimeMillis()
        val locked = isWidgetLocked(widgetData, "combo")
        val scheduledPrayer = readScheduledPrayer(widgetData, nowMs)
        val scheduledQuote = readScheduledQuote(widgetData, nowMs)
        val quote = scheduledQuote?.quote ?: buildDisplayQuote(
            rawText = widgetData.getString(KEY_QUOTE_TEXT, null),
            rawSource = widgetData.getString(KEY_QUOTE_SOURCE, null),
        )

        val localeCode = widgetData.getString(KEY_LOCALE, null)?.trim()?.lowercase().orEmpty()
        val forceTurkish = !localeCode.startsWith("tr")
        val scheduleExpired = scheduledPrayer?.expired == true
        val nextName = scheduledPrayer?.name
            ?: widgetData.getString(KEY_PRAYER_NEXT_NAME, null)?.trim().orEmpty()
        val countdownStatic = if (scheduleExpired) {
            "Uygulamayı aç"
        } else {
            widgetData.getString(KEY_PRAYER_COUNTDOWN, null)?.trim().orEmpty()
        }
        val epochMs = if (scheduleExpired) {
            null
        } else {
            scheduledPrayer?.epochMs
                ?: widgetData.getString(KEY_PRAYER_NEXT_EPOCH, null)?.trim()?.toLongOrNull()
        }
        val remMs = if (epochMs != null && epochMs > 0L) {
            (epochMs - nowMs).coerceAtLeast(0L)
        } else {
            null
        }
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
            putExtra(MainActivity.EXTRA_WIDGET_KIND, "combo")
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
        val contentPi = PendingIntent.getActivity(context, 2, openApp, piFlags)

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.arin_combo_widget)
            if (locked) {
                views.setViewVisibility(R.id.widget_combo_content, View.GONE)
                views.setViewVisibility(R.id.widget_lock_overlay, View.VISIBLE)
                views.setOnClickPendingIntent(R.id.widget_combo_root, contentPi)
                ArinWidgetTheme.apply(
                    views,
                    widgetData,
                    R.id.widget_combo_root,
                    intArrayOf(
                        R.id.widget_combo_prayer_title,
                        R.id.widget_combo_countdown,
                        R.id.widget_combo_quote_text,
                        R.id.widget_combo_quote_source,
                        R.id.widget_lock_note,
                    ),
                )
                appWidgetManager.updateAppWidget(widgetId, views)
                continue
            }
            views.setViewVisibility(R.id.widget_lock_overlay, View.GONE)
            views.setViewVisibility(R.id.widget_combo_content, View.VISIBLE)
            val safeNextName = if (scheduleExpired) {
                "Güncelle"
            } else if (forceTurkish) {
                "İmsak"
            } else {
                toTurkishPrayerName(nextName)
            }
            val prayerTitle = if (scheduleExpired) {
                "Güncelle"
            } else {
                remainingTitle(safeNextName.ifEmpty { "Vakit" })
            }
            views.setTextViewText(R.id.widget_combo_prayer_title, prayerTitle)
            if (canUseChronometer) {
                val base = SystemClock.elapsedRealtime() + remMs!!
                views.setChronometer(R.id.widget_combo_countdown, base, null, true)
                views.setChronometerCountDown(R.id.widget_combo_countdown, true)
            } else {
                views.setTextViewText(
                    R.id.widget_combo_countdown,
                    if (scheduleExpired) "Uygulamayı aç" else countdown.ifEmpty { "0:00:00" },
                )
            }
            val quotePresentation = quotePresentationForWidget(
                text = quote.text,
                context = context,
                appWidgetManager = appWidgetManager,
                widgetId = widgetId,
            )
            views.setViewVisibility(
                R.id.widget_combo_quote_text,
                if (quotePresentation.show) View.VISIBLE else View.GONE,
            )
            if (quotePresentation.show) {
                views.setTextViewTextSize(
                    R.id.widget_combo_quote_text,
                    TypedValue.COMPLEX_UNIT_SP,
                    quotePresentation.textSizeSp,
                )
                views.setTextViewText(R.id.widget_combo_quote_text, quote.text)
            }
            views.setViewVisibility(R.id.widget_combo_quote_source, View.GONE)
            views.setOnClickPendingIntent(R.id.widget_combo_root, contentPi)
            ArinWidgetTheme.apply(
                views,
                widgetData,
                R.id.widget_combo_root,
                intArrayOf(
                    R.id.widget_combo_prayer_title,
                    R.id.widget_combo_countdown,
                    R.id.widget_combo_quote_text,
                    R.id.widget_combo_quote_source,
                    R.id.widget_lock_note,
                ),
            )
            appWidgetManager.updateAppWidget(widgetId, views)
        }

        scheduleNextNativeRefresh(
            context,
            canUseChronometer,
            epochMs,
            scheduledQuote?.nextEpochMs,
            gateRefreshMs(widgetData, "combo"),
        )
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            scheduleTicks(context)
        }
    }

    override fun onDisabled(context: Context) {
        cancelTickAlarm(context)
        cancelRefreshAlarm(context)
        super.onDisabled(context)
    }

    private fun scheduleNextNativeRefresh(
        context: Context,
        canUseChronometer: Boolean,
        prayerEpochMs: Long?,
        quoteNextEpochMs: Long?,
        gateRefreshMs: Long?,
    ) {
        val now = System.currentTimeMillis()
        val prayerRefreshMs = prayerEpochMs
            ?.takeIf { it > now }
            ?.let { it + 1_000L }
        val quoteRefreshMs = quoteNextEpochMs?.takeIf { it > now }
        val nextRefresh = listOfNotNull(prayerRefreshMs, quoteRefreshMs, gateRefreshMs).minOrNull()

        if (canUseChronometer) {
            cancelTickAlarm(context)
            if (nextRefresh != null) {
                scheduleRefresh(context, nextRefresh)
            } else {
                cancelRefreshAlarm(context)
            }
        } else if (prayerEpochMs != null && prayerEpochMs > now) {
            if (gateRefreshMs != null && gateRefreshMs < now + TICK_INTERVAL_MS) {
                cancelTickAlarm(context)
                scheduleRefresh(context, gateRefreshMs)
            } else {
                cancelRefreshAlarm(context)
                scheduleTicks(context)
            }
        } else if (nextRefresh != null) {
            cancelTickAlarm(context)
            scheduleRefresh(context, nextRefresh)
        } else {
            cancelTickAlarm(context)
            cancelRefreshAlarm(context)
        }
    }

    private fun scheduleTicks(context: Context) {
        cancelTickAlarm(context)
        val awm = AppWidgetManager.getInstance(context)
        val component = ComponentName(context, ArinComboWidgetProvider::class.java)
        val ids = awm.getAppWidgetIds(component)
        if (ids.isEmpty()) return

        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val triggerAt = SystemClock.elapsedRealtime() + TICK_INTERVAL_MS
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                am.setAndAllowWhileIdle(
                    AlarmManager.ELAPSED_REALTIME_WAKEUP,
                    triggerAt,
                    tickPendingIntent(context),
                )
            } else {
                @Suppress("DEPRECATION")
                am.set(AlarmManager.ELAPSED_REALTIME_WAKEUP, triggerAt, tickPendingIntent(context))
            }
        } catch (_: Exception) {
            @Suppress("DEPRECATION")
            am.set(AlarmManager.ELAPSED_REALTIME_WAKEUP, triggerAt, tickPendingIntent(context))
        }
    }

    private fun cancelTickAlarm(context: Context) {
        (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(
            tickPendingIntent(context),
        )
    }

    private fun tickPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, ArinComboWidgetProvider::class.java).apply {
            action = ACTION_TICK
        }
        return PendingIntent.getBroadcast(
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
    }

    private fun scheduleRefresh(context: Context, epochMs: Long) {
        cancelRefreshAlarm(context)
        val now = System.currentTimeMillis()
        val triggerAt = epochMs.coerceAtLeast(now + 200L)
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
                    am.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerAt,
                        refreshPendingIntent(context),
                    )
                } else {
                    @Suppress("DEPRECATION")
                    am.setExact(AlarmManager.RTC_WAKEUP, triggerAt, refreshPendingIntent(context))
                }
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                am.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAt,
                    refreshPendingIntent(context),
                )
            } else {
                @Suppress("DEPRECATION")
                am.set(AlarmManager.RTC_WAKEUP, triggerAt, refreshPendingIntent(context))
            }
        } catch (_: Exception) {
            @Suppress("DEPRECATION")
            am.set(AlarmManager.RTC_WAKEUP, triggerAt, refreshPendingIntent(context))
        }
    }

    private fun cancelRefreshAlarm(context: Context) {
        (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(
            refreshPendingIntent(context),
        )
    }

    private fun refreshPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, ArinComboWidgetProvider::class.java).apply {
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

    private fun buildDisplayQuote(rawText: String?, rawSource: String?): DisplayQuote {
        val compactText = rawText?.replace(Regex("""\s+"""), " ")?.trim().orEmpty()
        val source = rawSource?.trim().orEmpty()
        if (compactText.isEmpty()) {
            return DisplayQuote(
                text = DEFAULT_QUOTE_TEXT,
                source = DEFAULT_QUOTE_SOURCE,
                showSource = false,
            )
        }
        if (source.isNotEmpty()) {
            return DisplayQuote(text = compactText, source = source, showSource = false)
        }
        return DisplayQuote(text = compactText, source = FALLBACK_QUOTE_SOURCE, showSource = false)
    }

    private fun quotePresentationForWidget(
        text: String,
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
    ): QuotePresentation {
        val trimmed = text.trim()
        if (trimmed.isEmpty()) return QuotePresentation(show = false, textSizeSp = 0f)

        val options = appWidgetManager.getAppWidgetOptions(widgetId)
        val minWidthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
            .takeIf { it > 0 } ?: DEFAULT_WIDGET_MIN_WIDTH_DP
        val minHeightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
            .takeIf { it > 0 } ?: DEFAULT_WIDGET_MIN_HEIGHT_DP

        // Namaz bölümü (~65dp) hesaba katılarak kalan yükseklik hesaplanır
        val quoteHeightDp = (minHeightDp - PRAYER_SECTION_HEIGHT_DP).coerceAtLeast(0)
        val maxLinesByHeight = when {
            quoteHeightDp >= 100 -> 3
            quoteHeightDp >= 60  -> 2
            else                 -> 1
        }

        val metrics = context.resources.displayMetrics
        val widgetWidthPx = (minWidthDp * metrics.density).roundToInt()
        val availableWidthPx = (widgetWidthPx - dpToPx(40f, metrics)).coerceAtLeast(0)
        if (availableWidthPx <= 0) return QuotePresentation(show = false, textSizeSp = 0f)

        val textPaint = TextPaint(TextPaint.ANTI_ALIAS_FLAG)
        val candidateSizes = listOf(28f, 26f, 24f, 22f, 20f, 18f)
        for (sizeSp in candidateSizes) {
            textPaint.textSize = TypedValue.applyDimension(
                TypedValue.COMPLEX_UNIT_SP,
                sizeSp,
                metrics,
            )
            @Suppress("DEPRECATION")
            val layout = StaticLayout(
                trimmed,
                textPaint,
                availableWidthPx,
                Layout.Alignment.ALIGN_NORMAL,
                1.02f,
                0f,
                false,
            )
            if (layout.lineCount <= maxLinesByHeight) {
                return QuotePresentation(show = true, textSizeSp = sizeSp)
            }
        }
        // Hiçbir boyut sığmasa bile en küçük boyutla göster; taşma ellipsize ile kesilir
        return QuotePresentation(show = true, textSizeSp = 18f)
    }

    private fun dpToPx(dp: Float, metrics: android.util.DisplayMetrics): Int {
        return (dp * metrics.density).roundToInt()
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

    private fun remainingTitle(name: String): String {
        val suffix = when (name) {
            "Öğle", "İkindi" -> "ye"
            "Güneş", "Vakit" -> "e"
            "Yatsı" -> "ya"
            else -> "a"
        }
        return "$name'$suffix kalan"
    }

    private data class ScheduledPrayer(
        val name: String,
        val epochMs: Long?,
        @Suppress("unused") val location: String?,
        val expired: Boolean,
    )

    private data class DisplayQuote(
        val text: String,
        val source: String,
        val showSource: Boolean,
    )

    private data class ScheduledQuote(
        val quote: DisplayQuote,
        val nextEpochMs: Long?,
    )

    private data class QuotePresentation(
        val show: Boolean,
        val textSizeSp: Float,
    )

    companion object {
        private const val DEFAULT_QUOTE_SOURCE = "Tâhâ, 46"
        private const val DEFAULT_QUOTE_TEXT = "İşitirim ve görürüm."
        private const val FALLBACK_QUOTE_SOURCE = "ARIN"

        private const val KEY_QUOTE_TEXT = "arin_quote_text"
        private const val KEY_QUOTE_SOURCE = "arin_quote_source"
        private const val KEY_QUOTE_SCHEDULE = "arin_quote_schedule_json"
        private const val KEY_PRAYER_NEXT_NAME = "arin_prayer_next_name"
        private const val KEY_PRAYER_COUNTDOWN = "arin_prayer_countdown"
        private const val KEY_PRAYER_NEXT_EPOCH = "arin_prayer_next_epoch_ms"
        private const val KEY_PRAYER_SCHEDULE = "arin_prayer_schedule_json"
        private const val KEY_LOCALE = "arin_widget_locale"
        private const val KEY_GATE_LOCKED = "arin_widget_gate_combo_locked"
        private const val KEY_GATE_PREMIUM = "arin_widget_gate_premium"
        private const val KEY_GATE_GLOBAL_LOCKED = "arin_widget_gate_global_locked"
        private const val WIDGET_TRIAL_DURATION_MS = 24L * 60L * 60L * 1000L

        private const val ACTION_TICK = "com.arin.arin.action.COMBO_WIDGET_TICK"
        private const val ACTION_REFRESH = "com.arin.arin.action.COMBO_WIDGET_REFRESH"
        private const val REQUEST_CODE_TICK = 19031
        private const val REQUEST_CODE_REFRESH = 19032
        private const val DEADLINE_GUARD_MS = 1500L
        private const val TICK_INTERVAL_MS = 60_000L
        private const val DEFAULT_WIDGET_MIN_WIDTH_DP = 220
        private const val DEFAULT_WIDGET_MIN_HEIGHT_DP = 140
        private const val PRAYER_SECTION_HEIGHT_DP = 65

        fun requestUpdate(context: Context) {
            val awm = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, ArinComboWidgetProvider::class.java)
            val ids = awm.getAppWidgetIds(component)
            if (ids.isEmpty()) return
            val update = Intent(context, ArinComboWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
            context.sendBroadcast(update)
        }
    }
}
