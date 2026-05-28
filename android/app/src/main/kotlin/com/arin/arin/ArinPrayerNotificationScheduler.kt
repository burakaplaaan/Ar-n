package com.arin.arin

import android.Manifest
import android.app.Notification
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import org.json.JSONArray
import org.json.JSONObject

private const val TAG = "ArinPrayerNtf"
private const val PREFS = "arin_prayer_native_notifications"
private const val KEY_RECORDS = "records"
private const val ACTION_FIRE = "com.arin.arin.action.PRAYER_NOTIFICATION_FIRE"
private const val EXTRA_ID = "id"
private const val EXTRA_TITLE = "title"
private const val EXTRA_BODY = "body"
private const val EXTRA_CHANNEL_ID = "channelId"
private const val EXTRA_PLAY_SOUND = "playSound"
private const val EXTRA_SOUND_TYPE = "soundType"
private const val EXTRA_SOUND = "sound"
private const val EXTRA_SCHEDULED_AT_MS = "scheduledAtMs"
private const val EXTRA_EXPIRES_AT_MS = "expiresAtMs"
private const val EXTRA_MODE = "mode"

object ArinPrayerNotificationScheduler {
    fun schedule(context: Context, args: Map<*, *>) {
        val id = (args["id"] as? Number)?.toInt()
            ?: throw IllegalArgumentException("id missing")
        val title = args["title"] as? String ?: ""
        val body = args["body"] as? String ?: ""
        val channelId = args["channelId"] as? String
            ?: throw IllegalArgumentException("channelId missing")
        val playSound = args["playSound"] as? Boolean ?: true
        val soundType = args["soundType"] as? String ?: "default"
        val sound = args["sound"] as? String ?: ""
        val scheduledAtMs = (args["scheduledAtMs"] as? Number)?.toLong()
            ?: throw IllegalArgumentException("scheduledAtMs missing")
        val expiresAtMs = (args["expiresAtMs"] as? Number)?.toLong()
            ?: throw IllegalArgumentException("expiresAtMs missing")
        val mode = args["mode"] as? String ?: "inexactAllowWhileIdle"

        val now = System.currentTimeMillis()
        if (now > expiresAtMs) {
            cancel(context, id)
            return
        }

        val record = JSONObject()
            .put(EXTRA_ID, id)
            .put(EXTRA_TITLE, title)
            .put(EXTRA_BODY, body)
            .put(EXTRA_CHANNEL_ID, channelId)
            .put(EXTRA_PLAY_SOUND, playSound)
            .put(EXTRA_SOUND_TYPE, soundType)
            .put(EXTRA_SOUND, sound)
            .put(EXTRA_SCHEDULED_AT_MS, scheduledAtMs)
            .put(EXTRA_EXPIRES_AT_MS, expiresAtMs)
            .put(EXTRA_MODE, mode)

        persistRecord(context, record)
        scheduleAlarm(context, record)
    }

    fun cancel(context: Context, id: Int) {
        val pi = pendingIntent(context, id, record = null)
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(pi)
        pi.cancel()
        NotificationManagerCompat.from(context).cancel(id)
        removeRecord(context, id)
    }

    fun cancelAll(context: Context) {
        for (record in readRecords(context)) {
            val id = record.optInt(EXTRA_ID, -1)
            if (id >= 0) cancel(context, id)
        }
    }

    fun rescheduleStored(context: Context) {
        val now = System.currentTimeMillis()
        val fresh = mutableListOf<JSONObject>()
        for (record in readRecords(context)) {
            val id = record.optInt(EXTRA_ID, -1)
            val expiresAtMs = record.optLong(EXTRA_EXPIRES_AT_MS, 0L)
            if (id < 0 || now > expiresAtMs) {
                if (id >= 0) NotificationManagerCompat.from(context).cancel(id)
                continue
            }
            fresh.add(record)
            try {
                scheduleAlarm(context, record)
            } catch (e: Exception) {
                Log.w(TAG, "reschedule failed id=$id", e)
            }
        }
        writeRecords(context, fresh)
    }

    fun deliver(context: Context, intent: Intent) {
        val id = intent.getIntExtra(EXTRA_ID, -1)
        if (id < 0) return

        val now = System.currentTimeMillis()
        val expiresAtMs = intent.getLongExtra(EXTRA_EXPIRES_AT_MS, 0L)
        if (now > expiresAtMs) {
            removeRecord(context, id)
            return
        }
        ArinPrayerWidgetProvider.requestUpdate(context)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            // İzin reddedilmişse alarmı silme, sadece bildirimi gösterme.
            // Kullanıcı ayarları değiştirirse veya uygulamaya tekrar girerse, 
            // schedule veya rescheduleStored() üzerinde kayıt korunur.
            return
        }

        val channelId = intent.getStringExtra(EXTRA_CHANNEL_ID) ?: return
        val title = intent.getStringExtra(EXTRA_TITLE) ?: ""
        val body = intent.getStringExtra(EXTRA_BODY) ?: ""
        val playSound = intent.getBooleanExtra(EXTRA_PLAY_SOUND, true)
        val soundType = intent.getStringExtra(EXTRA_SOUND_TYPE) ?: "default"
        val sound = intent.getStringExtra(EXTRA_SOUND) ?: ""
        val scheduledAtMs = intent.getLongExtra(EXTRA_SCHEDULED_AT_MS, now)
        ensureFallbackChannel(context, channelId)

        val openApp = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val contentIntent = PendingIntent.getActivity(
            context,
            id,
            openApp,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notificationBuilder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(context.applicationInfo.icon)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(true)
            .setShowWhen(true)
            .setWhen(scheduledAtMs)
            .setContentIntent(contentIntent)

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O && playSound) {
            applyPreOreoSound(context, notificationBuilder, soundType, sound)
        }

        val notification = notificationBuilder.build()

        NotificationManagerCompat.from(context).notify(id, notification)
        removeRecord(context, id)
    }

    private fun scheduleAlarm(context: Context, record: JSONObject) {
        val id = record.getInt(EXTRA_ID)
        val triggerAtMs = record.getLong(EXTRA_SCHEDULED_AT_MS)
        val mode = record.optString(EXTRA_MODE, "inexactAllowWhileIdle")
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pi = pendingIntent(context, id, record)
        when (mode) {
            "alarmClock" -> {
                val showIntent = PendingIntent.getActivity(
                    context,
                    id,
                    Intent(context, MainActivity::class.java),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                alarmManager.setAlarmClock(
                    AlarmManager.AlarmClockInfo(triggerAtMs, showIntent),
                    pi
                )
            }
            "exactAllowWhileIdle" -> alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerAtMs,
                pi
            )
            else -> alarmManager.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerAtMs,
                pi
            )
        }
    }

    private fun pendingIntent(context: Context, id: Int, record: JSONObject?): PendingIntent {
        val intent = Intent(context, ArinPrayerNotificationReceiver::class.java).apply {
            action = ACTION_FIRE
            putExtra(EXTRA_ID, id)
            if (record != null) {
                putExtra(EXTRA_TITLE, record.optString(EXTRA_TITLE))
                putExtra(EXTRA_BODY, record.optString(EXTRA_BODY))
                putExtra(EXTRA_CHANNEL_ID, record.optString(EXTRA_CHANNEL_ID))
                putExtra(EXTRA_PLAY_SOUND, record.optBoolean(EXTRA_PLAY_SOUND, true))
                putExtra(EXTRA_SOUND_TYPE, record.optString(EXTRA_SOUND_TYPE))
                putExtra(EXTRA_SOUND, record.optString(EXTRA_SOUND))
                putExtra(EXTRA_SCHEDULED_AT_MS, record.optLong(EXTRA_SCHEDULED_AT_MS))
                putExtra(EXTRA_EXPIRES_AT_MS, record.optLong(EXTRA_EXPIRES_AT_MS))
                putExtra(EXTRA_MODE, record.optString(EXTRA_MODE))
            }
        }
        return PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun applyPreOreoSound(
        context: Context,
        builder: NotificationCompat.Builder,
        soundType: String,
        sound: String,
    ) {
        val uri = when (soundType) {
            "raw" -> if (sound.isNotEmpty()) {
                Uri.parse("android.resource://${context.packageName}/raw/$sound")
            } else {
                null
            }
            "uri" -> if (sound.isNotEmpty()) Uri.parse(sound) else null
            else -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        }
        if (uri != null) {
            builder.setSound(uri)
        } else {
            builder.setDefaults(Notification.DEFAULT_SOUND)
        }
    }

    private fun ensureFallbackChannel(context: Context, channelId: String) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java)
        if (manager.getNotificationChannel(channelId) != null) return
        val channel = NotificationChannel(
            channelId,
            "Prayer",
            NotificationManager.IMPORTANCE_HIGH
        )
        manager.createNotificationChannel(channel)
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun readRecords(context: Context): List<JSONObject> {
        val raw = prefs(context).getString(KEY_RECORDS, "[]") ?: "[]"
        val arr = try {
            JSONArray(raw)
        } catch (_: Exception) {
            JSONArray()
        }
        return buildList {
            for (i in 0 until arr.length()) {
                val obj = arr.optJSONObject(i) ?: continue
                add(obj)
            }
        }
    }

    private fun writeRecords(context: Context, records: List<JSONObject>) {
        val arr = JSONArray()
        records.forEach { record -> arr.put(record) }
        prefs(context).edit().putString(KEY_RECORDS, arr.toString()).apply()
    }

    private fun persistRecord(context: Context, record: JSONObject) {
        val id = record.getInt(EXTRA_ID)
        val records = readRecords(context)
            .filterNot { it.optInt(EXTRA_ID, -1) == id }
            .toMutableList()
        records.add(record)
        writeRecords(context, records)
    }

    private fun removeRecord(context: Context, id: Int) {
        val records = readRecords(context)
            .filterNot { it.optInt(EXTRA_ID, -1) == id }
        writeRecords(context, records)
    }
}

class ArinPrayerNotificationReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_FIRE) return
        ArinPrayerNotificationScheduler.deliver(context.applicationContext, intent)
    }
}

class ArinPrayerNotificationBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        val isTimeSet = action == Intent.ACTION_TIME_SET
        val isTimeChanged = action == Intent.ACTION_TIME_CHANGED
        val isTimezoneChanged = action == Intent.ACTION_TIMEZONE_CHANGED
        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            isTimeSet ||
            isTimeChanged ||
            isTimezoneChanged ||
            action == "android.intent.action.QUICKBOOT_POWERON" ||
            action == "com.htc.intent.action.QUICKBOOT_POWERON"
        ) {
            ArinPrayerNotificationScheduler.rescheduleStored(context.applicationContext)
        }
    }
}
