import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/prediction_result.dart';
import '../screens/plus_screen.dart';
import '../theme/app_theme.dart';

class WellnessForecastTimeline extends StatelessWidget {
  final List<WellnessForecast> forecasts;
  final bool isPlus;

  const WellnessForecastTimeline({
    super.key,
    required this.forecasts,
    required this.isPlus,
  });

  @override
  Widget build(BuildContext context) {
    if (forecasts.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = AppTheme.isDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Hormonal Forecast',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark(context),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF8989), Color(0xFFCE93D8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'PLUS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Chronological wellness milestones ahead',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLight(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!isPlus)
          _buildLockedTeaser(context)
        else
          SizedBox(
            height: 155,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: forecasts.length,
              itemBuilder: (context, index) {
                final forecast = forecasts[index];
                return _buildForecastCard(context, forecast, isDark);
              },
            ),
          ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildLockedTeaser(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlusScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.all(18),
        height: 125,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF2A1525), const Color(0xFF1A1A1A)]
                : [const Color(0xFFFFF3E0), const Color(0xFFFCE4EC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadow(context),
          border: Border.all(
            color: const Color(0xFFFF8989).withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8989).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFFFF8989),
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Unlock Hormonal Forecasting',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark(context),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Get day-by-day cycle surges, PMS warnings, and clinical symptom insights.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textLight(context),
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppTheme.textLight(context),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildForecastCard(
      BuildContext context, WellnessForecast forecast, bool isDark) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final forecastDate =
        DateTime(forecast.date.year, forecast.date.month, forecast.date.day);
    final diff = forecastDate.difference(today).inDays;

    String relativeLabel;
    if (diff == 0) {
      relativeLabel = 'Today';
    } else if (diff == 1) {
      relativeLabel = 'Tomorrow';
    } else if (diff == -1) {
      relativeLabel = 'Yesterday';
    } else if (diff > 0) {
      relativeLabel = 'In $diff days';
    } else {
      relativeLabel = '${diff.abs()} days ago';
    }

    // Gradient & Icon & Color setup based on type
    final LinearGradient cardGradient;
    final IconData icon;
    final Color badgeBg;
    final Color badgeText;

    switch (forecast.type) {
      case 'menstrual_rest':
        cardGradient = LinearGradient(
          colors: isDark
              ? [const Color(0xFF4A1C1C), const Color(0xFF3B1230)]
              : [const Color(0xFFFFEBEE), const Color(0xFFF3E5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        icon = Icons.spa_rounded;
        badgeBg = const Color(0xFFFFCDD2);
        badgeText = const Color(0xFFC62828);
        break;
      case 'energy_peak':
        cardGradient = LinearGradient(
          colors: isDark
              ? [const Color(0xFF422C0A), const Color(0xFF13322E)]
              : [const Color(0xFFFFF9C4), const Color(0xFFE0F2F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        icon = Icons.bolt_rounded;
        badgeBg = const Color(0xFFB2DFDB);
        badgeText = const Color(0xFF00695C);
        break;
      case 'fertility_peak':
        cardGradient = LinearGradient(
          colors: isDark
              ? [const Color(0xFF4D172E), const Color(0xFF33091B)]
              : [const Color(0xFFFCE4EC), const Color(0xFFF8BBD0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        icon = Icons.favorite_rounded;
        badgeBg = const Color(0xFFFFB2C1);
        badgeText = const Color(0xFFC2185B);
        break;
      case 'pms_warning':
        cardGradient = LinearGradient(
          colors: isDark
              ? [const Color(0xFF22193E), const Color(0xFF3A1F4D)]
              : [const Color(0xFFE8EAF6), const Color(0xFFE1BEE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        icon = Icons.bubble_chart_rounded;
        badgeBg = const Color(0xFFD1C4E9);
        badgeText = const Color(0xFF4527A0);
        break;
      case 'mood_dip':
        cardGradient = LinearGradient(
          colors: isDark
              ? [const Color(0xFF1F2937), const Color(0xFF111827)]
              : [const Color(0xFFECEFF1), const Color(0xFFCFD8DC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        icon = Icons.self_improvement_rounded;
        badgeBg = const Color(0xFFB0BEC5);
        badgeText = const Color(0xFF37474F);
        break;
      default:
        cardGradient = LinearGradient(
          colors: isDark
              ? [const Color(0xFF2D2D2D), const Color(0xFF1A1A1A)]
              : [Colors.grey.shade100, Colors.grey.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        icon = Icons.calendar_today_rounded;
        badgeBg = Colors.grey.shade300;
        badgeText = Colors.grey.shade800;
    }

    return Container(
      width: 250,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow(context),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.03),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  forecast.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark(context),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                icon,
                size: 20,
                color: badgeText,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              relativeLabel,
              style: TextStyle(
                color: badgeText,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Spacer(),
          Text(
            forecast.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textLight(context),
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
