package com.example.lunaraai

import android.appwidget.AppWidgetManager
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetPlugin

import android.content.SharedPreferences

class LunaraWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val cyclePhase = widgetData.getString("cycle_phase", "Follicular Phase") ?: "Follicular Phase"
            val cycleDay = widgetData.getString("cycle_day", "Day 1") ?: "Day 1"
            val fertilityStatus = widgetData.getString("fertility_status", "Low Fertility") ?: "Low Fertility"

            // Update the UI RemoteViews
            val views = RemoteViews(context.packageName, R.layout.lunara_widget).apply {
                setTextViewText(R.id.widget_cycle_phase, cyclePhase)
                setTextViewText(R.id.widget_cycle_day, cycleDay)
                setTextViewText(R.id.widget_fertility_status, fertilityStatus)
            }
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
