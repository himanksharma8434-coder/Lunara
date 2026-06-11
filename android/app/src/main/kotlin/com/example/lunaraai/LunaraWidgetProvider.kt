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
            val phaseName: String

            if (lastPeriodMs == 0L) {
                cyclePhase = widgetData.getString("cycle_phase", "Follicular Phase") ?: "Follicular Phase"
                cycleDay = widgetData.getString("cycle_day", "Day 1") ?: "Day 1"
                fertilityStatus = widgetData.getString("fertility_status", "Low Fertility") ?: "Low Fertility"
                phaseName = when {
                    cyclePhase.contains("Menstrual", ignoreCase = true) || cyclePhase.contains("Period", ignoreCase = true) -> "Menstrual"
                    cyclePhase.contains("Follicular", ignoreCase = true) -> "Follicular"
                    cyclePhase.contains("Ovulation", ignoreCase = true) -> "Ovulation"
                    else -> "Luteal"
                }
            } else {
                val cycleLength = try {
                    widgetData.getInt("cycle_length", 28)
                } catch (e: Exception) {
                    widgetData.getLong("cycle_length", 28L).toInt()
                }

                val periodDuration = try {
                    widgetData.getInt("period_duration", 5)
                } catch (e: Exception) {
                    widgetData.getLong("period_duration", 5L).toInt()
                }

                val ovulationDay = try {
                    widgetData.getInt("ovulation_day", 14)
                } catch (e: Exception) {
                    widgetData.getLong("ovulation_day", 14L).toInt()
                }

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
                phaseName = phase
                
                fertilityStatus = when {
                    currentDay <= periodDuration -> "Menstruation"
                    currentDay >= (ovulationDay - 5) && currentDay <= ovulationDay -> "High Fertility"
                    else -> "Low Fertility"
                }
            }

            val backgroundResId = when (phaseName) {
                "Menstrual" -> R.drawable.widget_background_menstrual
                "Follicular" -> R.drawable.widget_background_follicular
                "Ovulation" -> R.drawable.widget_background_ovulation
                else -> R.drawable.widget_background_luteal
            }

            val phaseColorStr = when (phaseName) {
                "Menstrual" -> "#FF8989"
                "Follicular" -> "#4DB6AC"
                "Ovulation" -> "#64B5F6"
                else -> "#CE93D8"
            }

            val fertilityColorStr = when (fertilityStatus) {
                "Menstruation" -> "#FF8989"
                "High Fertility" -> "#64B5F6"
                else -> "#81C784"
            }

            val fertilityBgResId = when (fertilityStatus) {
                "Menstruation" -> R.drawable.fertility_pill_bg_menstrual
                "High Fertility" -> R.drawable.fertility_pill_bg_high
                else -> R.drawable.fertility_pill_bg_low
            }

            // Update the UI RemoteViews
            val views = RemoteViews(context.packageName, R.layout.lunara_widget).apply {
                setTextViewText(R.id.widget_cycle_phase, cyclePhase)
                setTextColor(R.id.widget_cycle_phase, android.graphics.Color.parseColor(phaseColorStr))
                setTextViewText(R.id.widget_cycle_day, cycleDay)
                
                setTextViewText(R.id.widget_fertility_status, fertilityStatus)
                setTextColor(R.id.widget_fertility_status, android.graphics.Color.parseColor(fertilityColorStr))
                setInt(R.id.widget_fertility_status, "setBackgroundResource", fertilityBgResId)
                
                setInt(R.id.widget_root, "setBackgroundResource", backgroundResId)
            }
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
