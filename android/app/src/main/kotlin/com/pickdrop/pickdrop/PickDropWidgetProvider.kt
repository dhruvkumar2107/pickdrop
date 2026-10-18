package com.pickdrop.pickdrop

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews

class PickDropWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val views = buildRemoteViews(context)
        for (appWidgetId in appWidgetIds) {
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun buildRemoteViews(context: Context): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.pickdrop_widget)

        val launchIntent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra(EXTRA_OPEN_SCREEN, OPEN_SCREEN_CUSTOMER_HOME)
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            REQUEST_OPEN_CUSTOMER_HOME,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
        views.setTextViewText(R.id.widget_status, readStatus(context))

        val fare = readFare(context)
        if (fare.isNullOrEmpty()) {
            views.setViewVisibility(R.id.widget_fare, View.GONE)
        } else {
            views.setViewVisibility(R.id.widget_fare, View.VISIBLE)
            views.setTextViewText(R.id.widget_fare, fare)
        }
        return views
    }

    private fun widgetPreferences(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE)
    }

    private fun readStatus(context: Context): String {
        val prefs = widgetPreferences(context)
        val stored = prefs.getString(FLUTTER_PREFIX + KEY_STATUS, null)
            ?: prefs.getString(KEY_STATUS, null)
        return stored ?: DEFAULT_STATUS
    }

    private fun readFare(context: Context): String? {
        val prefs = widgetPreferences(context)
        return prefs.getString(FLUTTER_PREFIX + KEY_LAST_FARE, null)
            ?: prefs.getString(KEY_LAST_FARE, null)
    }

    companion object {
        const val EXTRA_OPEN_SCREEN = "open_screen"
        const val OPEN_SCREEN_CUSTOMER_HOME = "customerHome"
        private const val PREFS_FILE = "FlutterSharedPreferences"
        private const val FLUTTER_PREFIX = "flutter."
        private const val KEY_STATUS = "pickdrop_widget_status"
        private const val KEY_LAST_FARE = "pickdrop_widget_last_fare"
        private const val DEFAULT_STATUS = "Your driver is on the way"
        private const val REQUEST_OPEN_CUSTOMER_HOME = 4210
    }
}
