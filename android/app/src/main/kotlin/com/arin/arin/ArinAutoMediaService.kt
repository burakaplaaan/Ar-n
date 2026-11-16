package com.arin.arin

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.support.v4.media.MediaBrowserCompat
import android.support.v4.media.MediaDescriptionCompat
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import androidx.car.app.connection.CarConnection
import androidx.core.app.NotificationCompat
import androidx.lifecycle.Observer
import androidx.media.MediaBrowserServiceCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Android Auto medya tarayıcısı. Çalma CarPlay ile aynı Dart oturumuna gider.
 * Haritaya geçince tarayıcı kopsa da ses sürer; araç bağlantısı bitince durur.
 */
class ArinAutoMediaService : MediaBrowserServiceCompat() {
    private lateinit var session: MediaSessionCompat
    private val main = Handler(Looper.getMainLooper())
    private var carConnection: CarConnection? = null
    private var sawCar = false
    private var greeted = false
    private var catalogReady = false
    private var lastLine = ""
    private var artKey = ""
    private var art: Bitmap? = null
    private var foreground = false
    private val pending = mutableListOf<Pair<String, Any?>>()
    private val carObserver = Observer<Int> { type ->
        val connected = type != null && type != CarConnection.CONNECTION_TYPE_NOT_CONNECTED
        if (connected) {
            sawCar = true
            retainEngine = true
            ArinAutoBridge.pinEngine()
        } else if (sawCar) {
            sawCar = false
            onCarEnded()
        }
    }

    override fun onCreate() {
        super.onCreate()
        ArinAutoBridge.service = this
        ensureChannel()
        session = MediaSessionCompat(this, "ArinQuran").apply {
            setCallback(callbacks)
            isActive = true
        }
        sessionToken = session.sessionToken
        publishPlaceholder()
        carConnection = CarConnection(this).also { it.type.observeForever(carObserver) }
        warmFlutter()
        onDartReady()
    }

    override fun onDestroy() {
        carConnection?.type?.removeObserver(carObserver)
        if (ArinAutoBridge.service === this) {
            onCarEnded()
            ArinAutoBridge.service = null
        }
        session.release()
        super.onDestroy()
    }

    override fun onGetRoot(
        clientPackageName: String,
        clientUid: Int,
        rootHints: Bundle?,
    ): BrowserRoot {
        warmFlutter()
        if (::session.isInitialized) {
            session.isActive = true
        }
        onDartReady()
        val extras = Bundle().apply {
            putInt(CONTENT_STYLE_BROWSABLE, CONTENT_STYLE_LIST)
            putInt(CONTENT_STYLE_PLAYABLE, CONTENT_STYLE_LIST)
        }
        return BrowserRoot(ROOT, extras)
    }

    override fun onLoadChildren(
        parentId: String,
        result: Result<MutableList<MediaBrowserCompat.MediaItem>>,
    ) {
        if (parentId != ROOT) {
            result.sendResult(mutableListOf())
            return
        }
        result.sendResult(children.toMutableList())
    }

    fun onDartReady() {
        if (!ArinAutoBridge.dartReady || ArinAutoBridge.channel == null) return
        val first = !greeted
        greeted = true
        ArinAutoBridge.emit("connected") { value ->
            (value as? Map<*, *>)?.let { applyState(it, fromCatalog = true) }
        }
        if (!first) return
        val queued = pending.toList()
        pending.clear()
        for ((method, args) in queued) {
            ArinAutoBridge.emit(method, args, null)
        }
    }

    fun applyState(map: Map<*, *>, fromCatalog: Boolean = false) {
        if (Looper.myLooper() != Looper.getMainLooper()) {
            main.post { applyState(map, fromCatalog) }
            return
        }
        val surah = intOf(map, "surah") ?: 1
        val ayah = intOf(map, "ayah") ?: 1
        val name = (map["name"] as? String)?.trim().orEmpty().ifEmpty { "Kur'an" }
        val line = (map["line"] as? String) ?: "$name · $ayah"
        val playing = boolOf(map["playing"])
        val failed = boolOf(map["error"])
        val reciter = (map["reciter"] as? String) ?: "Kur'an"
        val album = (map["title"] as? String) ?: "Kur'an"
        val verse = (map["verse"] as? String).orEmpty()
        val artist = if (failed) (map["errorText"] as? String) ?: reciter else reciter
        val key = "$surah|$ayah|$verse"
        if (artKey != key) {
            artKey = key
            art = renderCard(name, line, verse)
        }
        val metadata = MediaMetadataCompat.Builder()
            .putString(MediaMetadataCompat.METADATA_KEY_TITLE, line)
            .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, artist)
            .putString(MediaMetadataCompat.METADATA_KEY_ALBUM, album)
            .putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_TITLE, name)
            .putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_SUBTITLE, line)
            .putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_DESCRIPTION, verse)
            .putString(MediaMetadataCompat.METADATA_KEY_MEDIA_ID, "surah:$surah")
        art?.let { metadata.putBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART, it) }
        session.setMetadata(metadata.build())
        session.setPlaybackState(playbackState(playing && !failed, boolOf(map["buffering"])))
        updateNotification(line, artist, playing && !failed)
        val hadCatalog = catalogReady
        if (fromCatalog || map["surahs"] is List<*>) {
            children = buildChildren(map)
            catalogReady = children.size > 1
        } else if (!catalogReady) {
            children = placeholderChildren(surah, ayah, line)
        } else {
            refreshContinue(line)
        }
        if (line != lastLine || catalogReady != hadCatalog) {
            lastLine = line
            notifyChildrenChanged(ROOT)
        }
    }

    private val callbacks = object : MediaSessionCompat.Callback() {
        override fun onPlay() = send("play")
        override fun onPause() = send("pause")
        override fun onSkipToNext() = send("next")
        override fun onSkipToPrevious() = send("previous")
        override fun onPlayFromMediaId(mediaId: String?, extras: Bundle?) {
            when {
                mediaId != null && mediaId.startsWith("surah:") -> {
                    val surah = mediaId.removePrefix("surah:").toIntOrNull() ?: return
                    send("playSurah", mapOf("surah" to surah))
                }
                else -> send("play")
            }
        }
    }

    private fun send(method: String, args: Any? = null) {
        if (!greeted) {
            pending.add(method to args)
            warmFlutter()
            return
        }
        ArinAutoBridge.emit(method, args, null)
    }

    private fun onCarEnded() {
        greeted = false
        pending.clear()
        catalogReady = false
        retainEngine = false
        if (ArinAutoBridge.channel != null) {
            ArinAutoBridge.emit("disconnected", null) {
                main.post { ArinAutoBridge.releaseEngineIfActivityGone() }
            }
        } else {
            ArinAutoBridge.releaseEngineIfActivityGone()
        }
        if (::session.isInitialized) {
            session.setPlaybackState(playbackState(playing = false, buffering = false))
            session.isActive = false
        }
        if (foreground) {
            stopForeground(STOP_FOREGROUND_REMOVE)
            foreground = false
        }
    }

    private fun warmFlutter() {
        if (ArinAutoBridge.channel != null) return
        try {
            startActivity(
                Intent(this, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                },
            )
        } catch (_: RuntimeException) {
        }
    }

    private fun publishPlaceholder() {
        val (surah, ayah) = savedPlace()
        val line = "Sure $surah · $ayah. ayet"
        children = placeholderChildren(surah, ayah, line)
        session.setMetadata(
            MediaMetadataCompat.Builder()
                .putString(MediaMetadataCompat.METADATA_KEY_TITLE, line)
                .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, "Kur'an")
                .putString(MediaMetadataCompat.METADATA_KEY_ALBUM, "Kur'an")
                .build(),
        )
        session.setPlaybackState(playbackState(playing = false, buffering = false))
    }

    private fun savedPlace(): Pair<Int, Int> {
        val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        fun read(key: String): Int {
            if (!prefs.contains(key)) return 0
            return try {
                prefs.getLong(key, 0L).toInt()
            } catch (_: ClassCastException) {
                try {
                    prefs.getInt(key, 0)
                } catch (_: ClassCastException) {
                    0
                }
            }
        }
        var surah = read("flutter.quran_last_surah")
        var ayah = read("flutter.quran_last_ayah")
        if (surah !in 1..114) surah = 1
        if (ayah < 1) ayah = 1
        return surah to ayah
    }

    private fun placeholderChildren(
        surah: Int,
        ayah: Int,
        line: String,
    ): MutableList<MediaBrowserCompat.MediaItem> {
        return mutableListOf(playable("continue", line, "Sure $surah · $ayah. ayet"))
    }

    private fun buildChildren(map: Map<*, *>): MutableList<MediaBrowserCompat.MediaItem> {
        val items = mutableListOf<MediaBrowserCompat.MediaItem>()
        val line = (map["line"] as? String) ?: "Kur'an"
        val listTitle = (map["listTitle"] as? String) ?: "Sureler"
        items.add(playable("continue", line, listTitle))
        val rows = map["surahs"] as? List<*> ?: return items
        for (row in rows) {
            val item = row as? Map<*, *> ?: continue
            val number = intOf(item, "n") ?: continue
            val name = (item["name"] as? String) ?: number.toString()
            val count = (item["countLabel"] as? String).orEmpty()
            val arabic = (item["arabic"] as? String).orEmpty()
            val detail = if (arabic.isEmpty()) count else "$arabic · $count"
            items.add(playable("surah:$number", "$number. $name", detail))
        }
        return items
    }

    private fun refreshContinue(line: String) {
        if (children.isEmpty()) return
        val rest = if (children.size > 1) children.subList(1, children.size) else emptyList()
        val next = mutableListOf(playable("continue", line, line))
        next.addAll(rest)
        children = next
    }

    private fun playable(
        id: String,
        title: String,
        subtitle: String,
    ): MediaBrowserCompat.MediaItem {
        val description = MediaDescriptionCompat.Builder()
            .setMediaId(id)
            .setTitle(title)
            .setSubtitle(subtitle)
            .build()
        return MediaBrowserCompat.MediaItem(description, MediaBrowserCompat.MediaItem.FLAG_PLAYABLE)
    }

    private fun playbackState(playing: Boolean, buffering: Boolean): PlaybackStateCompat {
        val state = when {
            buffering && playing -> PlaybackStateCompat.STATE_BUFFERING
            playing -> PlaybackStateCompat.STATE_PLAYING
            else -> PlaybackStateCompat.STATE_PAUSED
        }
        return PlaybackStateCompat.Builder()
            .setActions(
                PlaybackStateCompat.ACTION_PLAY or
                    PlaybackStateCompat.ACTION_PAUSE or
                    PlaybackStateCompat.ACTION_PLAY_PAUSE or
                    PlaybackStateCompat.ACTION_SKIP_TO_NEXT or
                    PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS or
                    PlaybackStateCompat.ACTION_PLAY_FROM_MEDIA_ID,
            )
            .setState(state, PlaybackStateCompat.PLAYBACK_POSITION_UNKNOWN, if (playing) 1f else 0f)
            .build()
    }

    private fun updateNotification(title: String, text: String, playing: Boolean) {
        val open = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(this, CHANNEL)
            .setSmallIcon(R.drawable.ic_widget_crescent)
            .setContentTitle(title)
            .setContentText(text)
            .setContentIntent(open)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(playing)
            .setStyle(
                androidx.media.app.NotificationCompat.MediaStyle()
                    .setMediaSession(session.sessionToken),
            )
            .build()
        if (playing) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    startForeground(
                        NOTIFICATION_ID,
                        notification,
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK,
                    )
                } else {
                    startForeground(NOTIFICATION_ID, notification)
                }
                foreground = true
            } catch (_: SecurityException) {
            }
        } else if (foreground) {
            val manager = getSystemService(NotificationManager::class.java)
            manager.notify(NOTIFICATION_ID, notification)
        }
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            CHANNEL,
            getString(R.string.auto_quran_channel_name),
            NotificationManager.IMPORTANCE_LOW,
        )
        channel.description = getString(R.string.auto_quran_channel_description)
        manager.createNotificationChannel(channel)
    }

    private fun renderCard(title: String, line: String, verse: String): Bitmap {
        val size = 640
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.drawColor(Color.rgb(18, 28, 23))
        val titlePaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.rgb(219, 189, 117)
            textSize = 64f
            textAlign = Paint.Align.CENTER
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        }
        canvas.drawText(title, size / 2f, 120f, titlePaint)
        val linePaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.argb(210, 255, 255, 255)
            textSize = 36f
            textAlign = Paint.Align.CENTER
        }
        canvas.drawText(line, size / 2f, 180f, linePaint)
        if (verse.isNotEmpty()) {
            val versePaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.WHITE
                textSize = 40f
            }
            val layout = StaticLayout.Builder.obtain(verse, 0, verse.length, versePaint, size - 80)
                .setAlignment(Layout.Alignment.ALIGN_CENTER)
                .setIncludePad(false)
                .build()
            canvas.save()
            canvas.translate(40f, 230f)
            layout.draw(canvas)
            canvas.restore()
        }
        return bitmap
    }

    private fun intOf(map: Map<*, *>, key: String): Int? = (map[key] as? Number)?.toInt()

    private fun boolOf(value: Any?): Boolean = when (value) {
        is Boolean -> value
        is Number -> value.toInt() != 0
        else -> false
    }

    companion object {
        const val ROOT = "arin_quran"
        private const val CHANNEL = "arin_auto_quran"
        private const val NOTIFICATION_ID = 9106
        private const val CONTENT_STYLE_BROWSABLE =
            "android.media.browse.CONTENT_STYLE_BROWSABLE_HINT"
        private const val CONTENT_STYLE_PLAYABLE =
            "android.media.browse.CONTENT_STYLE_PLAYABLE_HINT"
        private const val CONTENT_STYLE_LIST = 1

        @Volatile
        var retainEngine: Boolean = false

        private var children: MutableList<MediaBrowserCompat.MediaItem> = mutableListOf()
    }
}

object ArinAutoBridge {
    const val ENGINE_ID = "arin_auto"
    var channel: MethodChannel? = null
    var dartReady: Boolean = false
    var activityAlive: Boolean = false
    var engine: FlutterEngine? = null
    var service: ArinAutoMediaService? = null

    fun attachFromActivity(flutterEngine: FlutterEngine) {
        engine = flutterEngine
        activityAlive = true
        attach(flutterEngine.dartExecutor.binaryMessenger)
        service?.onDartReady()
    }

    fun onActivityFinished() {
        activityAlive = false
        if (!ArinAutoMediaService.retainEngine) {
            io.flutter.embedding.engine.FlutterEngineCache.getInstance().remove(ENGINE_ID)
            detach()
            engine = null
        } else {
            pinEngine()
        }
    }

    fun pinEngine() {
        val held = engine ?: return
        io.flutter.embedding.engine.FlutterEngineCache.getInstance().put(ENGINE_ID, held)
    }

    fun releaseEngineIfActivityGone() {
        if (activityAlive) return
        val held = engine
        detach()
        engine = null
        io.flutter.embedding.engine.FlutterEngineCache.getInstance().remove(ENGINE_ID)
        held?.destroy()
    }

    private fun attach(messenger: BinaryMessenger) {
        val next = MethodChannel(messenger, "com.arin.arin/auto")
        channel = next
        next.setMethodCallHandler { call, result ->
            when (call.method) {
                "hostReady" -> {
                    dartReady = true
                    Handler(Looper.getMainLooper()).post {
                        service?.onDartReady()
                    }
                    result.success(null)
                }
                "onState" -> {
                    val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
                    Handler(Looper.getMainLooper()).post {
                        service?.applyState(args)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
        dartReady = false
    }

    fun emit(method: String, args: Any? = null, callback: ((Any?) -> Unit)?) {
        val target = channel ?: return
        target.invokeMethod(method, args, object : MethodChannel.Result {
            override fun success(result: Any?) {
                callback?.invoke(result)
            }

            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                callback?.invoke(null)
            }

            override fun notImplemented() {
                callback?.invoke(null)
            }
        })
    }
}
