package com.arin.arin

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Typeface
import android.os.Build
import android.os.SystemClock
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import android.util.TypedValue
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import java.util.concurrent.TimeUnit
import kotlin.math.roundToInt

/**
 * Kilit ekranı bildirim widget'ları: 5 widget türünün (namaz, söz, karma,
 * zikirmatik, takip) kalıcı/ongoing bir bildirim olarak gösterilmesini sağlar.
 *
 * Ana ekran widget'larının aksine, bu bildirimler [android.appwidget.AppWidgetProvider]
 * instance'larına bağlı DEĞİLDİR — kullanıcı hiç widget eklememiş olsa bile
 * çalışır (Android, `onUpdate` çağrısını yalnızca en az bir widget örneği
 * varsa tetikler; bu yüzden bağımsız bir zamanlama katmanı gerekir).
 *
 * Veri kaynağı, widget provider'ların da kullandığı aynı `HomeWidgetPreferences`
 * deposudur (`ArinWidgetSync` tarafından Flutter'dan yazılır) — bu sayede
 * mevcut namaz/söz/zikir/takip push akışlarına dokunmadan aynı veriler
 * okunabilir.
 *
 * Reklam/deneme kilidi: ana ekran widget'larıyla (`ArinPrayerWidgetProvider.
 * isWidgetLocked`) BİREBİR AYNI anahtarları ve 24 saatlik deneme süresini
 * paylaşır (`arin_widget_gate_*`, `arin_widget_first_use_ms_<kind>`). Fark:
 * bu bildirimler ana ekran widget'ına bağlı olmadığından, deneme süresi
 * kullanıcı hiç widget eklememiş olsa bile bildirimin İLK gösterildiği anda
 * [recordFirstUse] ile başlatılır. 24 saat dolunca bildirim "Açmak için
 * dokun" durumuna döner; dokunma, mevcut widget kilidi derin bağlantısıyla
 * (`MainActivity.EXTRA_WIDGET_LOCK`) doğrudan reklam-izle/premium ekranına
 * (`WidgetUnlockPage`) götürür — aynı reklam turu hem widget'ı hem bu
 * bildirimi birlikte açar.
 *
 * Admin metrikleri kapı anahtarlarından ayrıdır: kilit bildirimi
 * `arin_lock_notif_first_use_ms_<kind>` / `arin_lock_notif_last_show_ms_<kind>`
 * yazar; ana ekran widget sayımı `arin_widget_home_last_render_ms_<kind>`
 * ile yapılır. Böylece "aktif widget" ile "aktif kilit ekranı bildirimi"
 * admin panelde ayrı sayılır.
 */
object ArinLockNotifications {
    private const val CHANNEL_ID = "arin_lock_widgets"

    const val KIND_PRAYER = "prayer"
    const val KIND_QUOTE = "quote"
    const val KIND_COMBO = "combo"
    const val KIND_ZIKIR = "zikir"
    const val KIND_TRACKING = "tracking"

    private val KINDS = listOf(KIND_PRAYER, KIND_QUOTE, KIND_COMBO, KIND_ZIKIR, KIND_TRACKING)

    private const val TICK_INTERVAL_MS = 60_000L
    private const val DEADLINE_GUARD_MS = 1500L

    private const val KEY_QUOTE_TEXT = "arin_quote_text"
    private const val KEY_QUOTE_SOURCE = "arin_quote_source"
    private const val KEY_QUOTE_SCHEDULE = "arin_quote_schedule_json"
    private const val KEY_PRAYER_LOCATION = "arin_prayer_location"
    private const val KEY_PRAYER_NEXT_NAME = "arin_prayer_next_name"
    private const val KEY_PRAYER_COUNTDOWN = "arin_prayer_countdown"
    private const val KEY_PRAYER_NEXT_EPOCH = "arin_prayer_next_epoch_ms"
    private const val KEY_PRAYER_SCHEDULE = "arin_prayer_schedule_json"
    private const val KEY_ZIKIR_PHRASE = "arin_zikir_phrase"
    private const val KEY_ZIKIR_COUNT = "arin_zikir_count"
    private const val KEY_ZIKIR_TUR = "arin_zikir_tur"
    private const val KEY_TRACKING_ENABLED = "arin_tracking_enabled"
    private const val KEY_TRACKING_TITLE = "arin_tracking_title"
    private const val KEY_TRACKING_VALUE = "arin_tracking_value"
    private const val KEY_TRACKING_NOTE = "arin_tracking_note"
    private const val KEY_TRACKING_QUOTES_JSON = "arin_tracking_quotes_json"
    private const val KEY_TRACKING_MODE = "arin_tracking_mode"
    private const val KEY_TRACKING_START_EPOCH = "arin_tracking_start_epoch_ms"
    private const val KEY_TRACKING_DAY_PREFIX = "arin_tracking_day_prefix"

    private const val DEFAULT_QUOTE_TEXT = "İşitirim ve görürüm."
    private const val DEFAULT_QUOTE_SOURCE = "Tâhâ, 46"

    // Ana ekran widget'larıyla (`ArinPrayerWidgetProvider`) paylaşılan reklam/
    // deneme kapısı anahtarları. Aynı isimler kasıtlı: bir tur reklam hem
    // widget'ı hem bu bildirimi birlikte açar.
    private const val KEY_GATE_PREMIUM = "arin_widget_gate_premium"
    private const val KEY_GATE_GLOBAL_LOCKED = "arin_widget_gate_global_locked"
    private const val GATE_TRIAL_DURATION_MS = 24L * 60L * 60L * 1000L

    private fun firstUseKey(kind: String) = "arin_widget_first_use_ms_$kind"
    private fun lockNotifFirstUseKey(kind: String) = "arin_lock_notif_first_use_ms_$kind"
    private fun lockNotifLastShowKey(kind: String) = "arin_lock_notif_last_show_ms_$kind"
    private fun gateLockedKey(kind: String) = "arin_widget_gate_${kind}_locked"
    private fun gateUnlockUntilKey(kind: String) = "arin_widget_gate_${kind}_unlock_until_ms"

    /** Bu tür için kilit ekranı bildirimi ilk kez gösterildiğinde deneme
     * sayacını başlatır. Kullanıcı ana ekran widget'ını hiç eklememiş olsa
     * bile bağımsız olarak çalışır; anahtar zaten set edilmişse dokunmaz. */
    private fun recordFirstUse(prefs: SharedPreferences, kind: String) {
        val key = firstUseKey(kind)
        if ((prefs.getString(key, null)?.toLongOrNull() ?: 0L) > 0L) return
        prefs.edit().putString(key, System.currentTimeMillis().toString()).apply()
    }

    /** Admin metrikleri için kilit bildirimine özgü ilk kullanım + son gösterim.
     * Reklam/deneme kapısı anahtarlarından bağımsızdır. */
    private fun recordLockNotifMetrics(prefs: SharedPreferences, kind: String) {
        val now = System.currentTimeMillis().toString()
        val editor = prefs.edit()
        val firstKey = lockNotifFirstUseKey(kind)
        if ((prefs.getString(firstKey, null)?.toLongOrNull() ?: 0L) <= 0L) {
            editor.putString(firstKey, now)
        }
        editor.putString(lockNotifLastShowKey(kind), now).apply()
    }

    private fun firstUseMs(prefs: SharedPreferences, kind: String): Long =
        prefs.getString(firstUseKey(kind), null)?.toLongOrNull() ?: 0L

    /** `ArinPrayerWidgetProvider.isWidgetLocked` ile birebir aynı karar
     * mantığı: premium/global override, sonra aktif reklam turu, sonra 24
     * saatlik deneme süresi. */
    private fun isGateLocked(prefs: SharedPreferences, kind: String): Boolean {
        if (prefs.getString(KEY_GATE_PREMIUM, null) == "1") return false
        if (prefs.getString(KEY_GATE_GLOBAL_LOCKED, null) == "1") return true
        val now = System.currentTimeMillis()
        val unlockUntil = prefs.getString(gateUnlockUntilKey(kind), null)?.toLongOrNull() ?: 0L
        if (unlockUntil > now) return false
        if (prefs.getString(gateLockedKey(kind), null) == "1") return true
        val firstUse = firstUseMs(prefs, kind)
        if (firstUse <= 0L) return false
        return now >= firstUse + GATE_TRIAL_DURATION_MS
    }

    /** Deneme bitişi veya aktif reklam turunun bitişinden hangisi daha
     * yakınsa o an — bildirim durumunu (kilitli/açık) o ana yeniden
     * değerlendirmek için bir alarm kurulmalı. Premium'da yenileme gerekmez. */
    private fun gateRefreshMs(prefs: SharedPreferences, kind: String): Long? {
        if (prefs.getString(KEY_GATE_PREMIUM, null) == "1") return null
        val now = System.currentTimeMillis()
        val firstUse = firstUseMs(prefs, kind)
        val trialEnd = if (firstUse > 0L) firstUse + GATE_TRIAL_DURATION_MS else 0L
        val unlockUntil = prefs.getString(gateUnlockUntilKey(kind), null)?.toLongOrNull() ?: 0L
        return listOf(trialEnd, unlockUntil).filter { it > now }.minOrNull()?.plus(1_000L)
    }

    private fun kindLabel(kind: String): String = when (kind) {
        KIND_PRAYER -> "Namaz vakti"
        KIND_QUOTE -> "Günün sözü"
        KIND_COMBO -> "Söz + Namaz"
        KIND_ZIKIR -> "Zikirmatik"
        KIND_TRACKING -> "Takip"
        else -> "ARIN"
    }

    /** Yeni kurulumda hepsi kapalı; kullanıcı Widget Merkezi / onboarding ile açar. */
    fun defaultEnabled(kind: String): Boolean = false

    fun isEnabled(prefs: SharedPreferences, kind: String): Boolean {
        return when (prefs.getString(enabledKey(kind), null)) {
            "1" -> true
            "0" -> false
            else -> defaultEnabled(kind)
        }
    }

    fun enabledKey(kind: String) = "arin_lock_notif_enabled_$kind"

    /** Flutter tarafından her veri push'undan sonra (ve toggle değişince) çağrılır. */
    fun syncAll(context: Context) {
        ensureChannel(context)
        val prefs = HomeWidgetPlugin.getData(context)
        for (kind in KINDS) syncInternal(context, kind, prefs)
    }

    fun sync(context: Context, kind: String) {
        if (kind !in KINDS) return
        ensureChannel(context)
        syncInternal(context, kind, HomeWidgetPlugin.getData(context))
    }

    fun cancelAllForFeatureOff(context: Context) {
        for (kind in KINDS) cancelKind(context, kind)
    }

    private fun syncInternal(context: Context, kind: String, prefs: SharedPreferences) {
        if (!isEnabled(prefs, kind)) {
            cancelKind(context, kind)
            return
        }
        // Deneme sayacı, bildirim ilk kez fiilen gösterilebilir hale
        // geldiğinde başlar (widget eklenmiş olması şart değil).
        recordFirstUse(prefs, kind)
        if (isGateLocked(prefs, kind)) {
            postLockedNotification(context, kind, prefs)
            cancelTick(context, kind)
            val refreshAt = gateRefreshMs(prefs, kind)
            if (refreshAt != null) {
                scheduleExact(context, kind, refreshAt)
            } else {
                cancelDeadline(context, kind)
            }
            return
        }
        val nowMs = System.currentTimeMillis()
        val content = buildContent(context, kind, prefs, nowMs)
        if (content == null) {
            cancelNotificationOnly(context, kind)
            cancelAlarm(context, kind)
            return
        }
        postNotification(context, kind, content, prefs)
        scheduleNext(context, kind, content, prefs)
    }

    // ─── İçerik modeli ──────────────────────────────────────────────────────

    private data class NotifBuild(
        val title: String,
        val secondary: String,
        val primaryText: String,
        val primarySizeSp: Float,
        val primaryMaxLines: Int = 1,
        val chronometerBaseElapsed: Long?,
        val nextDeadlineEpochMs: Long?,
        val useTickFallback: Boolean,
    )

    // OEM kilit ekranlarının dar collapsed kartında başlık + iki söz satırı
    // birlikte görünmeli. Genişliğe sığsa bile 13-14sp iki satır MIUI'da
    // dikeyden kırpıldığı için söz boyutu bilinçli olarak 12sp ile sınırlandı.
    private val QUOTE_TEXT_SIZE_CANDIDATES =
        listOf(11f, 10.5f, 10f, 9.5f, 9f, 8.5f)
    private val TRACKING_VALUE_SIZE_CANDIDATES = listOf(15f, 14f, 13f, 12f, 11f)

    private fun buildContent(
        context: Context,
        kind: String,
        prefs: SharedPreferences,
        nowMs: Long,
    ): NotifBuild? {
        return when (kind) {
            KIND_PRAYER -> buildPrayerContent(prefs, nowMs)
            KIND_QUOTE -> buildQuoteContent(context, prefs, nowMs)
            KIND_COMBO -> buildComboContent(context, prefs, nowMs)
            KIND_ZIKIR -> buildZikirContent(prefs)
            KIND_TRACKING -> buildTrackingContent(context, prefs, nowMs)
            else -> null
        }
    }

    // ─── Cihaz genişliğine göre otomatik font boyutu ───────────────────────
    //
    // Bildirim özel view'ı (RemoteViews) `SystemUI`/OEM kilit ekranı sürecinde
    // çizilir; oradan gerçek genişliği geri okuyamayız. Bunun yerine BURADA
    // (kendi process'imizde), cihazın gerçek ekran genişliğinden bildirim
    // kartının içerik alanına ayrılan payı çıkarıp metnin o genişliğe sığan
    // en büyük font boyutunu `StaticLayout` ile ölçüp seçiyoruz — home ekranı
    // widget'larındaki (`ArinComboWidgetProvider.quotePresentationForWidget`)
    // ile aynı teknik.

    /**
     * Sistemin/OEM'in bildirim kartı için ayırdığı pay: kart kenar boşlukları,
     * OEM'in solda gösterdiği büyük uygulama ikonu (MIUI ~56dp) ve sağdaki
     * genişlet oku dahil güvenli bir tahmin. Fazla rezerve etmek metni biraz
     * küçültür ama asla taşırmaz — kesilmektense küçük olması tercih edilir.
     */
    private const val RESERVED_CONTENT_WIDTH_DP = 140

    private fun availableContentWidthPx(context: Context): Int {
        val metrics = context.resources.displayMetrics
        val reservedPx = (RESERVED_CONTENT_WIDTH_DP * metrics.density).roundToInt()
        val minWidthPx = (120 * metrics.density).roundToInt()
        return (metrics.widthPixels - reservedPx).coerceAtLeast(minWidthPx)
    }

    private fun fitTextSizeSp(
        context: Context,
        text: String,
        maxWidthPx: Int,
        maxLines: Int,
        candidatesSp: List<Float>,
        maxHeightPx: Int? = null,
    ): Float {
        val trimmed = text.trim()
        if (trimmed.isEmpty() || maxWidthPx <= 0 || candidatesSp.isEmpty()) {
            return candidatesSp.lastOrNull() ?: 14f
        }
        val metrics = context.resources.displayMetrics
        val textPaint = TextPaint(TextPaint.ANTI_ALIAS_FLAG).apply {
            // XML'deki sans-serif-medium + bold render ayarıyla ölçüm birebir
            // aynı olmazsa ölçüm iki satır derken SystemUI üç satıra sarabilir.
            typeface = Typeface.create("sans-serif-medium", Typeface.BOLD)
        }
        // Önce okunabilir, tasarım tarafından belirlenen adayları; hiçbiri
        // sığmazsa (örn. sistem font ölçeği %200) 0.5sp adımlarla güvenli
        // minimuma kadar daha küçük boyutları dene. Böylece en küçük normal
        // adayın da yüksekliği aştığı cihazda ikinci satır kırpılmaz.
        val fallbackSizes = generateSequence(candidatesSp.last() - 0.5f) { it - 0.5f }
            .takeWhile { it >= 1f }
            .toList()
        val sizesToTry = (candidatesSp + fallbackSizes).distinct()
        for (sizeSp in sizesToTry) {
            textPaint.textSize = TypedValue.applyDimension(
                TypedValue.COMPLEX_UNIT_SP,
                sizeSp,
                metrics,
            )
            @Suppress("DEPRECATION")
            val layout = StaticLayout(
                trimmed,
                textPaint,
                maxWidthPx,
                Layout.Alignment.ALIGN_NORMAL,
                1.02f,
                0f,
                false,
            )
            val heightFits = maxHeightPx == null || layout.height <= maxHeightPx
            if (layout.lineCount <= maxLines && heightFits) return sizeSp
        }
        // Android font ölçeği platform sınırlarının da dışına zorlanmışsa
        // son güvenli fallback. Metin yatayda ellipsize olabilir ancak iki
        // satırlık dikey alan artık taşmaz.
        return 1f
    }

    private fun buildPrayerContent(
        prefs: SharedPreferences,
        nowMs: Long,
    ): NotifBuild? {
        val scheduled = readScheduledPrayer(prefs, nowMs)
        val scheduleExpired = scheduled?.expired == true
        val nextName = scheduled?.name
            ?: prefs.getString(KEY_PRAYER_NEXT_NAME, null)?.trim().orEmpty()
        val location = scheduled?.location
            ?: prefs.getString(KEY_PRAYER_LOCATION, null)?.trim().orEmpty()
        if (nextName.isEmpty() && location.isEmpty() && !scheduleExpired) return null

        val epochMs = if (scheduleExpired) {
            null
        } else {
            scheduled?.epochMs
                ?: prefs.getString(KEY_PRAYER_NEXT_EPOCH, null)?.trim()?.toLongOrNull()
        }
        val remMs = epochMs?.let { (it - nowMs).coerceAtLeast(0L) }
        val canUseChronometer =
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && remMs != null && remMs > DEADLINE_GUARD_MS

        // Ana ekran widget'ındaki gibi doğal okunan başlık: "Öğle'ye kalan".
        val safeName = if (scheduleExpired) "Güncelle" else toTurkishPrayerName(nextName)
        val title = if (scheduleExpired) "Uygulamayı aç" else remainingTitle(safeName)
        val primaryText = when {
            canUseChronometer -> "" // Chronometer taban zamanıyla gösterilecek
            scheduleExpired -> "Uygulamayı aç"
            remMs != null -> formatHms(remMs)
            else -> sanitizeCountdownLabel(
                prefs.getString(KEY_PRAYER_COUNTDOWN, null)?.trim().orEmpty(),
            )
        }
        return NotifBuild(
            title = title,
            secondary = location.ifEmpty { "Konum ayarlanmadı" },
            primaryText = primaryText,
            primarySizeSp = 16f,
            chronometerBaseElapsed = if (canUseChronometer) {
                SystemClock.elapsedRealtime() + remMs!!
            } else {
                null
            },
            nextDeadlineEpochMs = epochMs?.takeIf { it > nowMs }?.plus(1_000L),
            useTickFallback = !canUseChronometer && epochMs != null && epochMs > nowMs,
        )
    }

    private fun buildQuoteContent(
        context: Context,
        prefs: SharedPreferences,
        nowMs: Long,
    ): NotifBuild? {
        val scheduled = readScheduledQuote(prefs, nowMs)
        val quote = scheduled?.quote ?: buildDisplayQuote(
            rawText = prefs.getString(KEY_QUOTE_TEXT, null),
            rawSource = prefs.getString(KEY_QUOTE_SOURCE, null),
        )
        if (quote.text.isEmpty()) return null
        val maxLines = 2
        val sizeSp = fitTextSizeSp(
            context = context,
            text = quote.text,
            maxWidthPx = availableContentWidthPx(context),
            maxLines = maxLines,
            candidatesSp = QUOTE_TEXT_SIZE_CANDIDATES,
            // MIUI collapsed kartında başlık sonrasında güvenli kalan alan.
            // Font ölçeği büyütülmüş cihazlarda da aday boyut buna göre düşer.
            maxHeightPx = (26f * context.resources.displayMetrics.density).roundToInt(),
        )
        return NotifBuild(
            title = "Günün Sözü",
            secondary = quote.source,
            primaryText = quote.text,
            primarySizeSp = sizeSp,
            primaryMaxLines = maxLines,
            chronometerBaseElapsed = null,
            nextDeadlineEpochMs = scheduled?.nextEpochMs?.takeIf { it > nowMs },
            useTickFallback = false,
        )
    }

    private fun buildComboContent(
        context: Context,
        prefs: SharedPreferences,
        nowMs: Long,
    ): NotifBuild? {
        val prayer = buildPrayerContent(prefs, nowMs)
        val scheduledQuote = readScheduledQuote(prefs, nowMs)
        val quote = scheduledQuote?.quote ?: buildDisplayQuote(
            rawText = prefs.getString(KEY_QUOTE_TEXT, null),
            rawSource = prefs.getString(KEY_QUOTE_SOURCE, null),
        )
        if (prayer == null && quote.text.isEmpty()) return null
        val base = prayer ?: NotifBuild(
            title = "Söz + Namaz",
            secondary = "",
            primaryText = "—",
            primarySizeSp = 16f,
            chronometerBaseElapsed = null,
            nextDeadlineEpochMs = null,
            useTickFallback = false,
        )
        val quoteNext = scheduledQuote?.nextEpochMs?.takeIf { it > nowMs }
        val nextDeadline = listOfNotNull(base.nextDeadlineEpochMs, quoteNext).minOrNull()
        // Karma görünümde üst satır meta alanına söz metni yazılır; tek satırda
        // ellipsize ile kesilir (kompakt kart için bilinçli tercih).
        return base.copy(
            title = base.title,
            secondary = quote.text.ifEmpty { base.secondary },
            nextDeadlineEpochMs = nextDeadline,
        )
    }

    private fun buildZikirContent(prefs: SharedPreferences): NotifBuild? {
        val phrase = prefs.getString(KEY_ZIKIR_PHRASE, null)?.trim().orEmpty()
        val count = prefs.getString(KEY_ZIKIR_COUNT, null)?.toIntOrNull()
        val tur = prefs.getString(KEY_ZIKIR_TUR, null)?.toIntOrNull() ?: 1
        if (phrase.isEmpty() && count == null) return null
        return NotifBuild(
            title = phrase.ifEmpty { "Zikirmatik" },
            secondary = "$tur. tur",
            primaryText = (count ?: 0).toString(),
            primarySizeSp = 18f,
            chronometerBaseElapsed = null,
            nextDeadlineEpochMs = null,
            useTickFallback = false,
        )
    }

    private fun buildTrackingContent(
        context: Context,
        prefs: SharedPreferences,
        nowMs: Long,
    ): NotifBuild? {
        val enabled = prefs.getString(KEY_TRACKING_ENABLED, null) == "1"
        if (!enabled) return null
        val title = prefs.getString(KEY_TRACKING_TITLE, null)?.trim().orEmpty()
        val mode = prefs.getString(KEY_TRACKING_MODE, null)?.trim().orEmpty()
        val value = if (mode == "quit_days") {
            val start = prefs.getString(KEY_TRACKING_START_EPOCH, null)?.toLongOrNull()
            val prefix = prefs.getString(KEY_TRACKING_DAY_PREFIX, null)?.trim().orEmpty()
            if (start != null && start > 0L && prefix.isNotEmpty()) {
                val days = TimeUnit.MILLISECONDS.toDays((nowMs - start).coerceAtLeast(0L)) + 1
                "$prefix $days. gün"
            } else {
                prefs.getString(KEY_TRACKING_VALUE, null)?.trim().orEmpty()
            }
        } else {
            prefs.getString(KEY_TRACKING_VALUE, null)?.trim().orEmpty()
        }
        val note = dailyQuote(prefs) ?: prefs.getString(KEY_TRACKING_NOTE, null)?.trim().orEmpty()
        if (title.isEmpty() && value.isEmpty()) return null

        val cal = Calendar.getInstance().apply {
            timeInMillis = nowMs
            add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 1)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val safeValue = value.ifEmpty { "—" }
        val sizeSp = fitTextSizeSp(
            context = context,
            text = safeValue,
            maxWidthPx = availableContentWidthPx(context),
            maxLines = 1,
            candidatesSp = TRACKING_VALUE_SIZE_CANDIDATES,
        )
        return NotifBuild(
            title = title.ifEmpty { "ARIN Takip" },
            secondary = note.ifEmpty { "Bugün küçük bir adım yeter." },
            primaryText = safeValue,
            primarySizeSp = sizeSp,
            chronometerBaseElapsed = null,
            nextDeadlineEpochMs = cal.timeInMillis.coerceAtLeast(nowMs + 60_000L),
            useTickFallback = false,
        )
    }

    // ─── Bildirim oluşturma ─────────────────────────────────────────────────

    /** 24 saatlik deneme (veya reklam turu) dolduğunda gösterilen "dokun ve
     * aç" durumu. Gerçek içerik yerine geçer; PendingIntent doğrudan reklam
     * izle/premium ekranına (`WidgetUnlockPage`) yönlendirir. */
    private fun postLockedNotification(
        context: Context,
        kind: String,
        prefs: SharedPreferences,
    ) {
        val label = kindLabel(kind)
        val content = NotifBuild(
            title = "$label bildirimi kilitli",
            secondary = "",
            primaryText = "Açmak için dokun",
            primarySizeSp = 13f,
            chronometerBaseElapsed = null,
            nextDeadlineEpochMs = null,
            useTickFallback = false,
        )
        postNotification(context, kind, content, prefs, locked = true)
    }

    /**
     * Kilit bildirimi metin renklerini uiMode'a göre absolute ARGB olarak yazar.
     * Theme attribute (?android:attr/textColor*) OEM SystemUI'da koyu modda
     * sık sık koyu-kart / koyu-metin üretiyor; setTextColor bu hatayı keser.
     */
    private fun applyLockNotifTextColors(context: Context, views: RemoteViews) {
        val primary = ContextCompat.getColor(context, R.color.lock_notif_text_primary)
        val secondary = ContextCompat.getColor(context, R.color.lock_notif_text_secondary)
        views.setTextColor(R.id.notif_primary, primary)
        views.setTextColor(R.id.notif_title, secondary)
    }

    private fun postNotification(
        context: Context,
        kind: String,
        content: NotifBuild,
        prefs: SharedPreferences,
        locked: Boolean = false,
    ) {
        val views = RemoteViews(context.packageName, R.layout.arin_lock_notification)
        // Kompakt 2 satırlık tasarım: başlık + meta bilgi tek üst satırda
        // birleşir ("Günün Sözü · Tâhâ, 46"), alt satırda ana değer gösterilir.
        val headerText = listOf(content.title, content.secondary)
            .filter { it.isNotBlank() }
            .joinToString(" · ")
        views.setTextViewText(R.id.notif_title, headerText)
        // Absolute ARGB: OEM SystemUI ?attr/textColor* çözümünü koyu kartta
        // koyu metne çevirip sözü görünmez yapabiliyor; burada uiMode'a göre
        // çözülen renk RemoteViews action olarak gömülür.
        applyLockNotifTextColors(context, views)
        views.setTextViewTextSize(
            R.id.notif_primary,
            TypedValue.COMPLEX_UNIT_SP,
            content.primarySizeSp,
        )
        // RemoteViews'te doğrudan bir "setMaxLines" action'ı yok; `setInt` genel
        // reflection mekanizması ile TextView.setMaxLines(int) çağırıyoruz — her
        // widget türü kendi içeriğine (kısa geri sayım / uzun söz metni) uygun
        // satır sayısını cihazın genişliğine göre seçebilsin diye.
        views.setInt(R.id.notif_primary, "setMaxLines", content.primaryMaxLines)
        if (content.chronometerBaseElapsed != null) {
            views.setChronometer(R.id.notif_primary, content.chronometerBaseElapsed, null, true)
            views.setChronometerCountDown(R.id.notif_primary, true)
        } else {
            // Chronometer, TextView'dan türer: setChronometer çağrılmadığı sürece
            // düz metin göstermeye devam eder (widget provider'larda da aynı desen).
            views.setTextViewText(R.id.notif_primary, content.primaryText)
        }

        val openApp = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(MainActivity.EXTRA_WIDGET_KIND, kind)
            // Ana ekran widget kilidiyle aynı derin bağlantı: Flutter tarafı
            // (`WidgetLaunchGateListener`) bunu görünce doğrudan reklam-izle/
            // premium ekranını (`WidgetUnlockPage`) açar.
            if (locked) putExtra(MainActivity.EXTRA_WIDGET_LOCK, "1")
        }
        val piFlags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_IMMUTABLE
            } else {
                0
            }
        val contentPi = PendingIntent.getActivity(context, notifId(kind), openApp, piFlags)

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_widget_crescent)
            .setContentTitle(headerText)
            .setContentText(
                content.primaryText.ifBlank { content.secondary }.ifBlank { content.title },
            )
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setCustomContentView(views)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setContentIntent(contentPi)

        try {
            if (!NotificationManagerCompat.from(context).areNotificationsEnabled()) return
            NotificationManagerCompat.from(context).notify(notifId(kind), builder.build())
            // Bildirim gerçekten post edildiğinde metrik damgası yazılır.
            recordLockNotifMetrics(prefs, kind)
        } catch (_: SecurityException) {
            // POST_NOTIFICATIONS reddedilmiş olabilir (Android 13+); sessizce yut.
        }
    }

    private fun cancelKind(context: Context, kind: String) {
        cancelNotificationOnly(context, kind)
        cancelAlarm(context, kind)
    }

    private fun cancelNotificationOnly(context: Context, kind: String) {
        try {
            NotificationManagerCompat.from(context).cancel(notifId(kind))
        } catch (_: Exception) {
            // yok say
        }
    }

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            context.getString(R.string.lock_notif_channel_name),
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = context.getString(R.string.lock_notif_channel_description)
            setShowBadge(false)
            enableVibration(false)
            setSound(null, null)
        }
        manager.createNotificationChannel(channel)
    }

    // ─── Zamanlama ──────────────────────────────────────────────────────────

    private fun scheduleNext(
        context: Context,
        kind: String,
        content: NotifBuild,
        prefs: SharedPreferences,
    ) {
        if (content.useTickFallback) {
            // Tick her 60sn'de bir zaten `syncInternal`'ı tekrar çalıştırıp
            // kilit durumunu yeniden değerlendiriyor; ayrı bir gate alarmı
            // gerekmez.
            cancelDeadline(context, kind)
            scheduleTick(context, kind)
            return
        }
        cancelTick(context, kind)
        // Deneme/reklam turu, bir sonraki içerik güncellemesinden ÖNCE
        // dolabilir (örn. namaz vaktine daha saatler varken deneme biter) —
        // hangisi daha yakınsa o anda yeniden değerlendirme kur.
        val gateRefresh = gateRefreshMs(prefs, kind)
        val at = listOfNotNull(content.nextDeadlineEpochMs, gateRefresh).minOrNull()
        if (at != null) {
            scheduleExact(context, kind, at)
        } else {
            cancelDeadline(context, kind)
        }
    }

    private fun cancelAlarm(context: Context, kind: String) {
        cancelDeadline(context, kind)
        cancelTick(context, kind)
    }

    private fun scheduleExact(context: Context, kind: String, epochMs: Long) {
        val now = System.currentTimeMillis()
        val triggerAt = epochMs.coerceAtLeast(now + 200L)
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pi = deadlinePendingIntent(context, kind)
        try {
            val canExact = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
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

    private fun scheduleTick(context: Context, kind: String) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pi = tickPendingIntent(context, kind)
        val triggerAt = SystemClock.elapsedRealtime() + TICK_INTERVAL_MS
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                am.setAndAllowWhileIdle(AlarmManager.ELAPSED_REALTIME_WAKEUP, triggerAt, pi)
            } else {
                @Suppress("DEPRECATION")
                am.set(AlarmManager.ELAPSED_REALTIME_WAKEUP, triggerAt, pi)
            }
        } catch (_: Exception) {
            @Suppress("DEPRECATION")
            am.set(AlarmManager.ELAPSED_REALTIME_WAKEUP, triggerAt, pi)
        }
    }

    private fun cancelDeadline(context: Context, kind: String) {
        (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager)
            .cancel(deadlinePendingIntent(context, kind))
    }

    private fun cancelTick(context: Context, kind: String) {
        (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager)
            .cancel(tickPendingIntent(context, kind))
    }

    private fun deadlinePendingIntent(context: Context, kind: String): PendingIntent {
        val intent = Intent(context, ArinLockNotificationReceiver::class.java).apply {
            action = ACTION_DEADLINE_PREFIX + kind
        }
        return PendingIntent.getBroadcast(
            context,
            reqCode(kind, 3),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_IMMUTABLE
                } else {
                    0
                },
        )
    }

    private fun tickPendingIntent(context: Context, kind: String): PendingIntent {
        val intent = Intent(context, ArinLockNotificationReceiver::class.java).apply {
            action = ACTION_TICK_PREFIX + kind
        }
        return PendingIntent.getBroadcast(
            context,
            reqCode(kind, 2),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_IMMUTABLE
                } else {
                    0
                },
        )
    }

    private fun notifId(kind: String) = when (kind) {
        KIND_PRAYER -> 9101
        KIND_QUOTE -> 9102
        KIND_COMBO -> 9103
        KIND_ZIKIR -> 9104
        KIND_TRACKING -> 9105
        else -> 9100
    }

    private fun reqCode(kind: String, suffix: Int) = notifId(kind) * 10 + suffix

    internal const val ACTION_TICK_PREFIX = "com.arin.arin.action.LOCK_NOTIF_TICK_"
    internal const val ACTION_DEADLINE_PREFIX = "com.arin.arin.action.LOCK_NOTIF_DEADLINE_"

    // ─── Paylaşılan içerik yardımcıları (widget provider'larla aynı format) ──

    private data class ScheduledPrayer(
        val name: String,
        val epochMs: Long?,
        val location: String?,
        val expired: Boolean,
    )

    private data class DisplayQuote(val text: String, val source: String)

    private data class ScheduledQuote(val quote: DisplayQuote, val nextEpochMs: Long?)

    private fun readScheduledPrayer(prefs: SharedPreferences, nowMs: Long): ScheduledPrayer? {
        val raw = prefs.getString(KEY_PRAYER_SCHEDULE, null)?.trim().orEmpty()
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

    private fun readScheduledQuote(prefs: SharedPreferences, nowMs: Long): ScheduledQuote? {
        val raw = prefs.getString(KEY_QUOTE_SCHEDULE, null)?.trim().orEmpty()
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
            return DisplayQuote(text = DEFAULT_QUOTE_TEXT, source = DEFAULT_QUOTE_SOURCE)
        }
        return DisplayQuote(text = compactText, source = source)
    }

    private fun dailyQuote(prefs: SharedPreferences): String? {
        val raw = prefs.getString(KEY_TRACKING_QUOTES_JSON, null)?.trim().orEmpty()
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

    private fun containsArabic(s: String): Boolean = s.any { ch -> ch.code in 0x0600..0x06FF }

    private fun toTurkishPrayerName(raw: String): String {
        val t = raw.trim()
        if (t.isEmpty()) return "İmsak"
        if (containsArabic(t)) return "İmsak"
        // Türkçe 'İ' düzeltmesi: lowercase() locale bağımsız çalıştığı için
        // "İkindi" -> "i̇kindi" (birleşik noktalı i) olur ve "ikindi" ile
        // eşleşmez; önce İ/I harflerini elle Türkçe kurala göre indiriyoruz.
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

    /** "Öğle" -> "Öğle'ye kalan" (ArinComboWidgetProvider ile aynı ek kuralları). */
    private fun remainingTitle(name: String): String {
        val suffix = when (name) {
            "Öğle", "İkindi" -> "ye"
            "Güneş", "Vakit" -> "e"
            "Yatsı" -> "ya"
            else -> "a"
        }
        return "$name'$suffix kalan"
    }
}

/**
 * Kilit ekranı bildirimlerinin bağımsız tick/deadline alarm'larını karşılar.
 * `AppWidgetProvider` DEĞİLDİR — herhangi bir widget örneği eklenmemiş olsa
 * bile çalışır.
 */
class ArinLockNotificationReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        val kind = when {
            action.startsWith(ArinLockNotifications.ACTION_TICK_PREFIX) ->
                action.removePrefix(ArinLockNotifications.ACTION_TICK_PREFIX)
            action.startsWith(ArinLockNotifications.ACTION_DEADLINE_PREFIX) ->
                action.removePrefix(ArinLockNotifications.ACTION_DEADLINE_PREFIX)
            else -> null
        } ?: return
        ArinLockNotifications.sync(context.applicationContext, kind)
    }
}
