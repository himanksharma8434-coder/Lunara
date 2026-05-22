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
            val lastPeriodMs = widgetData.getLong("last_period_date_ms", 0L)
            
            val cyclePhase: String
            val cycleDay: String
            val fertilityStatus: String

            if (lastPeriodMs == 0L) {
                cyclePhase = widgetData.getString("cycle_phase", "Follicular Phase") ?: "Follicular Phase"
                cycleDay = widgetData.getString("cycle_day", "Day 1") ?: "Day 1"
                fertilityStatus = widgetData.getString("fertility_status", "Low Fertility") ?: "Low Fertility"
            } else {
                val cycleLength = widgetData.getInt("cycle_length", 28)
                val periodDuration = widgetData.getInt("period_duration", 5)
                val ovulationDay = widgetData.getInt("ovulation_day", 14)

                val today = java.util.Calendar.getInstance()
                val lastPeriod = java.util.Calendar.getInstance().apply {
                    timeInMillis = lastPeriodMs
                }
                
                // Reset time fields to normalize to calendar dates in local time
                today.set(java.util.Calendar.HOUR_OF_DAY, 0)
                today.set(java.util.Calendar.MINUTE, 0)
                today.set(java.util.Calendar.SECOND, 0)
                today.set(java.util.Calendar.MILLISECOND, 0)
                
                lastPeriod.set(java.util.Calendar.HOUR_OF_DAY, 0)
                lastPeriod.set(java.util.Calendar.MINUTE, 0)
                lastPeriod.set(java.util.Calendar.SECOND, 0)
                lastPeriod.set(java.util.Calendar.MILLISECOND, 0)
                
                val diffMs = today.timeInMillis - lastPeriod.timeInMillis
                val diffDays = (diffMs / (1000 * 60 * 60 * 24)).toInt()
                
                // Keep it positive and loop it around the cycle length
                val currentDay = if (diffDays >= 0) {
                    (diffDays % cycleLength) + 1
                } else {
                    1
                }
                
                cycleDay = "Day $currentDay of $cycleLength"
                
                val phase = when {
                    currentDay <= periodDuration -> "Menstrual"
                    currentDay < ovulationDay - 1 -> "Follicular"
                    currentDay <= ovulationDay + 1 -> "Ovulation"
                    else -> "Luteal"
                }
                cyclePhase = "$phase Phase"
                
                fertilityStatus = when {
                    currentDay <= periodDuration -> "Menstruation"
                    currentDay >= (ovulationDay - 5) && currentDay <= ovulationDay -> "High Fertility"
                    else -> "Low Fertility"
                }
            }

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
