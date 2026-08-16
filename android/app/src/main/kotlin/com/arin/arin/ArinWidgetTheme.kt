package com.arin.arin

import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews

object ArinWidgetTheme {
    const val KEY = "arin_widget_theme_id"

    data class Palette(
        val backgroundRes: Int,
        val textColor: Int,
    )

    fun apply(
        views: RemoteViews,
        prefs: SharedPreferences,
        rootId: Int,
        textIds: IntArray,
    ) {
        val palette = paletteFor(prefs.getString(KEY, "classic"))
        views.setInt(rootId, "setBackgroundResource", palette.backgroundRes)
        for (id in textIds) {
            views.setTextColor(id, palette.textColor)
        }
    }

    private fun paletteFor(id: String?): Palette {
        return when (id) {
            "emerald" -> Palette(R.drawable.widget_theme_emerald, Color.parseColor("#E8D5A3"))
            "gold" -> Palette(R.drawable.widget_theme_gold, Color.parseColor("#F0D48A"))
            "midnight" -> Palette(R.drawable.widget_theme_midnight, Color.parseColor("#D5DCE8"))
            "rose" -> Palette(R.drawable.widget_theme_rose, Color.parseColor("#F0C9C0"))
            "sand" -> Palette(R.drawable.widget_theme_sand, Color.parseColor("#3A2A14"))
            "ocean" -> Palette(R.drawable.widget_theme_ocean, Color.parseColor("#B7E4E0"))
            else -> Palette(R.drawable.widget_theme_classic, Color.parseColor("#F4F1E8"))
        }
    }
}
