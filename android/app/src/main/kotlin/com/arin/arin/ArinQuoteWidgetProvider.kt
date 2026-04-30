package com.arin.arin

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Söz / ayet widget: Flutter [HomeWidget.saveWidgetData] ile
 * `arin_quote_text` / `arin_quote_source`.
 */
class ArinQuoteWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val quote = buildDisplayQuote(
            rawText = widgetData.getString(KEY_QUOTE_TEXT, null),
            rawSource = widgetData.getString(KEY_QUOTE_SOURCE, null),
        )
        val openApp = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
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
            views.setTextViewText(R.id.widget_quote_text, quote.text)
            views.setTextViewText(R.id.widget_quote_source, quote.source)
            views.setViewVisibility(
                R.id.widget_quote_header_row,
                if (quote.showSource) {
                    View.VISIBLE
                } else {
                    View.GONE
                },
            )
            views.setOnClickPendingIntent(R.id.widget_root, contentPi)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
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

    private data class DisplayQuote(
        val text: String,
        val source: String,
        val showSource: Boolean,
    )

    companion object {
        private const val DEFAULT_QUOTE_SOURCE = "Tâhâ, 46"
        private const val DEFAULT_QUOTE_TEXT = "İşitirim ve görürüm."

        private const val KEY_QUOTE_TEXT = "arin_quote_text"
        private const val KEY_QUOTE_SOURCE = "arin_quote_source"
    }
}
