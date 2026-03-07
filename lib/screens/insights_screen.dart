// lib/screens/insights_screen.dart — Premium Cycle Analytics

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/cycle_provider.dart';
import '../theme/app_theme.dart';
import '../services/pdf_export_service.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CycleProvider>(context);
    return Scaffold(
      backgroundColor: LunaraColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildHeader(context),
            // Cycle Phase Overview
            SliverToBoxAdapter(
              child: _buildAnimatedCard(
                delay: 0,
                child: _CyclePhaseCard(provider: provider),
              ),
            ),
            // Wellness Trends
            SliverToBoxAdapter(
              child: _buildAnimatedCard(
                delay: 100,
                child: _WellnessTrendsCard(provider: provider),
              ),
            ),
            // Mood Trend
            SliverToBoxAdapter(
              child: _buildAnimatedCard(
                delay: 200,
                child: _MoodTrendCard(provider: provider),
              ),
            ),
            // Symptom Frequency
            SliverToBoxAdapter(
              child: _buildAnimatedCard(
                delay: 300,
                child: _SymptomFrequencyCard(provider: provider),
              ),
            ),

            // Export Button
            SliverToBoxAdapter(
              child: _buildAnimatedCard(
                delay: 400,
                child: _buildExportButton(context, provider),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          left: 20,
          right: 20,
          bottom: 20,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              LunaraColors.primaryLight,
              LunaraColors.backgroundPink.withOpacity(0.4),
              LunaraColors.background,
            ],
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: LunaraShadows.soft,
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    size: 18, color: LunaraColors.textDark),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Insights',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: LunaraColors.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Track patterns • Understand your body',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: LunaraColors.textBrown.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LunaraGradients.primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: LunaraShadows.glow,
              ),
              child: const Icon(Icons.insights_rounded,
                  size: 20, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton(BuildContext context, CycleProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          HapticFeedback.mediumImpact();
          // Provide visual feedback while generating
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Generating medical report...'),
              duration: Duration(seconds: 1),
            ),
          );
          await PdfExportService.generateAndShareDoctorReport(provider);
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: LunaraColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: LunaraColors.primaryLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LunaraRadius.md),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf_rounded, size: 20),
            SizedBox(width: 10),
            Text(
              'Export Doctor Report',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCard({required int delay, required Widget child}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  CYCLE PHASE CARD — Horizontal progress with phase segments
// ═══════════════════════════════════════════════════════════════════

class _CyclePhaseCard extends StatelessWidget {
  final CycleProvider provider;
  const _CyclePhaseCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final day = provider.currentCycleDay;
    final total = provider.cycleLength;
    final phase = provider.currentPhase;
    final periodEnd = provider.periodDuration;
    final ovulationStart = 13;
    final ovulationEnd = 17;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LunaraRadius.lg),
        boxShadow: LunaraShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _phaseColor(phase).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _phaseIcon(phase),
                  size: 18,
                  color: _phaseColor(phase),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cycle Phase',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: LunaraColors.textLight,
                        letterSpacing: 0.5,
                      )),
                  Text(
                    phase,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _phaseColor(phase),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: LunaraColors.textDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Day $day',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text: ' / $total',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          // Phase progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  _segment(periodEnd / total, LunaraColors.periodRed, day, 1,
                      periodEnd, total),
                  _segment(
                      (ovulationStart - periodEnd - 1) / total,
                      LunaraColors.follicularTeal,
                      day,
                      periodEnd + 1,
                      ovulationStart - 1,
                      total),
                  _segment(
                      (ovulationEnd - ovulationStart + 1) / total,
                      LunaraColors.ovulationBlue,
                      day,
                      ovulationStart,
                      ovulationEnd,
                      total),
                  _segment(
                      (total - ovulationEnd) / total,
                      LunaraColors.lutealPurple,
                      day,
                      ovulationEnd + 1,
                      total,
                      total),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Phase labels
          Row(
            children: [
              _phaseLabel('Menstrual', LunaraColors.periodRed),
              _phaseLabel('Follicular', LunaraColors.follicularTeal),
              _phaseLabel('Ovulation', LunaraColors.ovulationBlue),
              _phaseLabel('Luteal', LunaraColors.lutealPurple),
            ],
          ),
          if (provider.daysUntilNextPeriod > 0 &&
              provider.daysUntilNextPeriod <= provider.cycleLength) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: LunaraColors.primaryLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 16, color: LunaraColors.primaryDark),
                  const SizedBox(width: 10),
                  Text(
                    'Next period in ${provider.daysUntilNextPeriod} days',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: LunaraColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _segment(
      double flex, Color color, int currentDay, int start, int end, int total) {
    final isActive = currentDay >= start && currentDay <= end;
    return Expanded(
      flex: (flex * 100).round().clamp(1, 100),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: isActive ? color : color.withOpacity(0.25),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  Widget _phaseLabel(String label, Color color) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: LunaraColors.textLight),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _phaseColor(String phase) {
    switch (phase) {
      case 'Menstrual':
        return LunaraColors.periodRed;
      case 'Follicular':
        return LunaraColors.follicularTeal;
      case 'Ovulation':
        return LunaraColors.ovulationBlue;
      case 'Luteal':
        return LunaraColors.lutealPurple;
      default:
        return LunaraColors.primary;
    }
  }

  IconData _phaseIcon(String phase) {
    switch (phase) {
      case 'Menstrual':
        return Icons.water_drop_rounded;
      case 'Follicular':
        return Icons.eco_rounded;
      case 'Ovulation':
        return Icons.spa_rounded;
      case 'Luteal':
        return Icons.nightlight_round;
      default:
        return Icons.circle;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  WELLNESS TRENDS — Grouped bar chart (water, sleep, steps)
// ═══════════════════════════════════════════════════════════════════

class _WellnessTrendsCard extends StatelessWidget {
  final CycleProvider provider;
  const _WellnessTrendsCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final history = provider.getWellnessHistory(7);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LunaraRadius.lg),
        boxShadow: LunaraShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: LunaraColors.ovulationBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bar_chart_rounded,
                    size: 18, color: LunaraColors.ovulationBlue),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Wellness Trends',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: LunaraColors.textLight,
                        letterSpacing: 0.5,
                      )),
                  Text(
                    'Last 7 Days',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: LunaraColors.textDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot('Water', LunaraColors.ovulationBlue),
              const SizedBox(width: 20),
              _legendDot('Sleep', LunaraColors.lutealPurple),
              const SizedBox(width: 20),
              _legendDot('Steps', LunaraColors.fertileGreen),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _calculateMaxY(history),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => LunaraColors.textDark,
                    tooltipPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final labels = ['💧 Water', '😴 Sleep', '🚶 Steps'];
                      final units = [' glasses', ' hrs', ''];
                      return BarTooltipItem(
                        '${labels[rodIndex]}\n${rod.toY.toStringAsFixed(rodIndex == 2 ? 0 : 1)}${units[rodIndex]}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= history.length) {
                          return const SizedBox.shrink();
                        }
                        final date = history[index]['date'] as DateTime;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('E').format(date).substring(0, 2),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: LunaraColors.textLight,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _calculateMaxY(history) / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: LunaraColors.divider,
                    strokeWidth: 1,
                  ),
                ),
                barGroups: List.generate(history.length, (index) {
                  final entry = history[index];
                  final water = (entry['water'] as int).toDouble();
                  final sleep = (entry['sleep'] as double);
                  // Normalize steps to a 0–12 scale for visual balance
                  final stepsRaw = (entry['steps'] as int).toDouble();
                  final stepsNormalized = (stepsRaw / 1000).clamp(0.0, 12.0);

                  return BarChartGroupData(
                    x: index,
                    barsSpace: 3,
                    barRods: [
                      BarChartRodData(
                        toY: water,
                        width: 8,
                        color: LunaraColors.ovulationBlue,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: sleep,
                        width: 8,
                        color: LunaraColors.lutealPurple,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: stepsNormalized,
                        width: 8,
                        color: LunaraColors.fertileGreen,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
              ),
              duration: const Duration(milliseconds: 600),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateMaxY(List<Map<String, dynamic>> history) {
    double max = 8; // minimum scale
    for (final e in history) {
      final water = (e['water'] as int).toDouble();
      final sleep = (e['sleep'] as double);
      final steps = ((e['steps'] as int) / 1000).clamp(0.0, 12.0);
      if (water > max) max = water;
      if (sleep > max) max = sleep;
      if (steps > max) max = steps;
    }
    return (max + 2).ceilToDouble();
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: LunaraColors.textLight,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  MOOD TREND — Smooth line chart
// ═══════════════════════════════════════════════════════════════════

class _MoodTrendCard extends StatelessWidget {
  final CycleProvider provider;
  const _MoodTrendCard({required this.provider});

  double _moodToValue(String mood) {
    switch (mood.toLowerCase()) {
      case 'great':
        return 5;
      case 'good':
        return 4;
      case 'okay':
        return 3;
      case 'low':
        return 2;
      case 'bad':
      case 'terrible':
        return 1;
      default:
        return 3;
    }
  }

  String _valueToEmoji(double value) {
    if (value >= 4.5) return '😄';
    if (value >= 3.5) return '😊';
    if (value >= 2.5) return '😐';
    if (value >= 1.5) return '😔';
    return '😢';
  }

  @override
  Widget build(BuildContext context) {
    final history = provider.getWellnessHistory(7);
    final spots = history.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), _moodToValue(e.value['mood'] as String));
    }).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LunaraRadius.lg),
        boxShadow: LunaraShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: LunaraColors.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.mood_rounded,
                    size: 18, color: LunaraColors.warning),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mood Trend',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: LunaraColors.textLight,
                        letterSpacing: 0.5,
                      )),
                  Text(
                    'How you\'ve been feeling',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: LunaraColors.textDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: 0.5,
                maxY: 5.5,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => LunaraColors.textDark,
                    tooltipPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final emoji = _valueToEmoji(spot.y);
                        final index = spot.x.toInt();
                        final date = history[index]['date'] as DateTime;
                        return LineTooltipItem(
                          '$emoji ${history[index]['mood']}\n${DateFormat('MMM d').format(date)}',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= history.length) {
                          return const SizedBox.shrink();
                        }
                        final date = history[index]['date'] as DateTime;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('E').format(date).substring(0, 2),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: LunaraColors.textLight,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value < 1 || value > 5) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          _valueToEmoji(value),
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: LunaraColors.divider,
                    strokeWidth: 1,
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: LunaraColors.warning,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2.5,
                          strokeColor: LunaraColors.warning,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          LunaraColors.warning.withOpacity(0.15),
                          LunaraColors.warning.withOpacity(0.02),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 600),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SYMPTOM FREQUENCY — Horizontal bar chart
// ═══════════════════════════════════════════════════════════════════

class _SymptomFrequencyCard extends StatelessWidget {
  final CycleProvider provider;
  const _SymptomFrequencyCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final frequency = provider.getSymptomFrequency(30);
    final topSymptoms = frequency.entries.take(6).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LunaraRadius.lg),
        boxShadow: LunaraShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: LunaraColors.periodRed.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.healing_rounded,
                    size: 18, color: LunaraColors.periodRed),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Symptom Patterns',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: LunaraColors.textLight,
                        letterSpacing: 0.5,
                      )),
                  Text(
                    'Last 30 Days',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: LunaraColors.textDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (topSymptoms.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 48,
                      color: LunaraColors.fertileGreen.withOpacity(0.4)),
                  const SizedBox(height: 12),
                  Text(
                    'No symptoms logged yet',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: LunaraColors.textLight.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Log symptoms daily to see patterns here',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: LunaraColors.textLight.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            )
          else
            ...topSymptoms.asMap().entries.map((entry) {
              final index = entry.key;
              final symptom = entry.value.key;
              final count = entry.value.value;
              final maxCount = topSymptoms.first.value;
              final ratio = count / maxCount;

              // Gradient colors from warm to cool based on index
              final colors = [
                LunaraColors.periodRed,
                LunaraColors.primary,
                LunaraColors.warning,
                LunaraColors.ovulationBlue,
                LunaraColors.lutealPurple,
                LunaraColors.follicularTeal,
              ];
              final barColor = colors[index % colors.length];

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatSymptomName(symptom),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: LunaraColors.textDark,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: barColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$count ${count == 1 ? 'day' : 'days'}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: barColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 800 + (index * 100)),
                      tween: Tween(begin: 0.0, end: ratio),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: LunaraColors.divider,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: value,
                            child: Container(
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _formatSymptomName(String symptom) {
    return symptom
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }
}
