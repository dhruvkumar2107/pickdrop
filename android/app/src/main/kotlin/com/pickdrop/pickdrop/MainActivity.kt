package com.pickdrop.pickdrop

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onPostResume() {
        super.onPostResume()
        refreshHomeWidgets()
    }

    override fun onPause() {
        super.onPause()
        refreshHomeWidgets()
    }

    private fun refreshHomeWidgets() {
        val manager = AppWidgetManager.getInstance(this)
        val widgetIds = manager.getAppWidgetIds(
            ComponentName(this, PickDropWidgetProvider::class.java)
        )
        if (widgetIds.isEmpty()) return
        val intent = Intent(this, PickDropWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, widgetIds)
        }
        sendBroadcast(intent)
    }
}
