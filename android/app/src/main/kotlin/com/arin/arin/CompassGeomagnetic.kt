package com.arin.arin

/**
 * Singleton that stores the magnetic declination (degrees) computed by
 * GeomagneticField on the Flutter side via MethodChannel "compass_geomagnetic".
 *
 * RotationVectorCompassStream reads this value on every sensor event to
 * convert magnetic-north heading to true-north heading.
 */
object CompassGeomagnetic {
    @Volatile
    private var declination: Double = 0.0

    fun setDeclinationDegrees(dec: Float) {
        declination = dec.toDouble()
    }

    fun declinationDegrees(): Double = declination
}
