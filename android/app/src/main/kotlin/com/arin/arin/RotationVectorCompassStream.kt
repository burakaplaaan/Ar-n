package com.arin.arin

import android.app.Activity
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.plugin.common.EventChannel
import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.sin

/**
 * Pusula heading stream — cihaza göre en uygun sensörü otomatik seçer.
 *
 * Öncelik sırası (hem doğruluk hem uyumluluk gözetilerek):
 *   1. TYPE_GEOMAGNETIC_ROTATION_VECTOR — magnetometre + ivmeölçer, kuzey
 *      referanslı; jiroskop içermeyen/hatalı cihazlarda en güvenilir.
 *   2. Ham ACCELEROMETER + MAGNETIC_FIELD (getRotationMatrix) — tüm
 *      Android sürümlerinde desteklenen klasik yöntem, her cihazda çalışır.
 *
 * TYPE_ROTATION_VECTOR kasıtlı olarak kullanılmıyor: fused-orientation sensor
 *  bazı cihazlarda "oyun" (jiroskop-sadece) vektörü döndürerek kuzey
 *  referansını kaybeder → pusula için yanlış değer üretir.
 *
 * CompassGeomagnetic deklinasyonu eklenerek manyetik kuzey → gerçek kuzey
 * dönüşümü yapılır.
 */
class RotationVectorCompassStream(private val activity: Activity) :
    EventChannel.StreamHandler {

    private companion object {
        const val HISTORY_SIZE = 7
        const val TILT_LIMIT_DEG = 38.0
        const val JITTER_LIMIT_DEG = 12.0
    }

    private var sensorManager: SensorManager? = null
    private var eventSink: EventChannel.EventSink? = null

    // Strateji 1: GEOMAGNETIC_ROTATION_VECTOR
    private var geoRotSensor: Sensor? = null
    private var geoRotListener: SensorEventListener? = null

    // Strateji 2: ACCELEROMETER + MAGNETIC_FIELD (ham)
    private var accelSensor: Sensor? = null
    private var magSensor: Sensor? = null
    private var rawListener: SensorEventListener? = null
    private val lastAccel = FloatArray(3)
    private val lastMag   = FloatArray(3)
    private var hasAccel  = false
    private var hasMag    = false
    private var sensorAccuracy = SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM

    private val rotMat = FloatArray(9)
    private val oriMat = FloatArray(3)
    private val headingHistory = ArrayDeque<Double>(HISTORY_SIZE)

    // ── Flutter stream yönetimi ──────────────────────────────────────────────

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        val sm = activity.getSystemService(Activity.SENSOR_SERVICE) as? SensorManager
            ?: run {
                events?.error("SENSOR_MGR", "SensorManager unavailable", null)
                return
            }
        sensorManager = sm

        val geoRot = sm.getDefaultSensor(Sensor.TYPE_GEOMAGNETIC_ROTATION_VECTOR)
        if (geoRot != null) {
            startGeoRotVector(sm, geoRot)
        } else {
            startRawSensors(sm)
        }
    }

    override fun onCancel(arguments: Any?) {
        val sm = sensorManager ?: return
        geoRotListener?.let  { sm.unregisterListener(it) }
        rawListener?.let     { sm.unregisterListener(it) }
        geoRotListener = null
        rawListener    = null
        eventSink      = null
        sensorManager  = null
        hasAccel = false
        hasMag   = false
        headingHistory.clear()
    }

    // ── Strateji 1: GEOMAGNETIC_ROTATION_VECTOR ─────────────────────────────

    private fun startGeoRotVector(sm: SensorManager, sensor: Sensor) {
        geoRotSensor = sensor
        geoRotListener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent?) {
                val ev = event ?: return
                SensorManager.getRotationMatrixFromVector(rotMat, ev.values)
                emitFromRotMatrix()
            }
            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
                sensorAccuracy = accuracy
            }
        }
        sm.registerListener(geoRotListener, sensor, SensorManager.SENSOR_DELAY_GAME)
    }

    // ── Strateji 2: Ham ACCELEROMETER + MAGNETIC_FIELD ──────────────────────

    private fun startRawSensors(sm: SensorManager) {
        val accel = sm.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        val mag   = sm.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)

        if (accel == null || mag == null) {
            eventSink?.error("SENSOR_UNAVAILABLE", "No compass sensors found", null)
            return
        }
        accelSensor = accel
        magSensor   = mag

        rawListener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent?) {
                val ev = event ?: return
                when (ev.sensor.type) {
                    Sensor.TYPE_ACCELEROMETER -> {
                        System.arraycopy(ev.values, 0, lastAccel, 0, 3)
                        hasAccel = true
                    }
                    Sensor.TYPE_MAGNETIC_FIELD -> {
                        System.arraycopy(ev.values, 0, lastMag, 0, 3)
                        hasMag = true
                    }
                }
                if (!hasAccel || !hasMag) return
                if (!SensorManager.getRotationMatrix(rotMat, null, lastAccel, lastMag)) return
                emitFromRotMatrix()
            }
            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
                if (sensor?.type == Sensor.TYPE_MAGNETIC_FIELD) {
                    sensorAccuracy = accuracy
                }
            }
        }
        sm.registerListener(rawListener, accel, SensorManager.SENSOR_DELAY_GAME)
        sm.registerListener(rawListener, mag,   SensorManager.SENSOR_DELAY_GAME)
    }

    // ── Ortak: rotasyon matrisinden heading hesapla ve emit et ───────────────

    private fun emitFromRotMatrix() {
        SensorManager.getOrientation(rotMat, oriMat)
        // oriMat[0] = azimuth (radians, −π … +π), manyetik kuzeyden saat yönüne.
        var azimuth = Math.toDegrees(oriMat[0].toDouble())
        // Manyetik deklinasyon ekle → gerçek (coğrafi) kuzey.
        azimuth += CompassGeomagnetic.declinationDegrees()
        val rawHeading = normalizeDeg(azimuth)

        val pitchDeg = Math.toDegrees(oriMat[1].toDouble())
        val rollDeg = Math.toDegrees(oriMat[2].toDouble())
        val smoothHeading = smoothHeading(rawHeading)
        val jitterDeg = circularDelta(rawHeading, smoothHeading)

        val flatEnough = abs(pitchDeg) <= TILT_LIMIT_DEG &&
            abs(rollDeg) <= TILT_LIMIT_DEG
        val accuracyGood = sensorAccuracy != SensorManager.SENSOR_STATUS_UNRELIABLE
        val stable = flatEnough && accuracyGood && jitterDeg <= JITTER_LIMIT_DEG

        val guidance = when {
            !flatEnough -> "tilt"
            !accuracyGood -> "calibrate"
            jitterDeg > JITTER_LIMIT_DEG -> "unstable"
            else -> "good"
        }

        eventSink?.success(
            mapOf(
                "heading" to smoothHeading,
                "rawHeading" to rawHeading,
                "pitch" to pitchDeg,
                "roll" to rollDeg,
                "accuracy" to sensorAccuracy,
                "jitter" to jitterDeg,
                "stable" to stable,
                "guidance" to guidance,
            ),
        )
    }

    private fun smoothHeading(heading: Double): Double {
        if (headingHistory.size == HISTORY_SIZE) {
            headingHistory.removeFirst()
        }
        headingHistory.addLast(heading)

        var sinSum = 0.0
        var cosSum = 0.0
        headingHistory.forEach { deg ->
            val rad = Math.toRadians(deg)
            sinSum += sin(rad)
            cosSum += cos(rad)
        }
        return normalizeDeg(Math.toDegrees(atan2(sinSum, cosSum)))
    }

    private fun circularDelta(a: Double, b: Double): Double {
        val raw = abs(a - b)
        return if (raw > 180.0) 360.0 - raw else raw
    }

    private fun normalizeDeg(value: Double): Double {
        val normalized = value % 360.0
        return if (normalized < 0) normalized + 360.0 else normalized
    }
}
