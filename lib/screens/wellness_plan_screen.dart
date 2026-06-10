// lib/screens/wellness_plan_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/cycle_provider.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';
import '../services/groq_service.dart';
import '../services/plus_service.dart';

class WellnessPlanScreen extends StatefulWidget {
  const WellnessPlanScreen({super.key});

  @override
  State<WellnessPlanScreen> createState() => _WellnessPlanScreenState();
}

class _WellnessPlanScreenState extends State<WellnessPlanScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeAnimation;

  bool _isGenerating = false;
  String? _generatedPlan;
  String? _error;
  int _selectedTimeRange = 7; // default: last 7 days
  String _selectedDiet = 'No Preference';

  final List<Map<String, dynamic>> _dietOptions = [
    {'label': 'No Preference', 'icon': Icons.restaurant_rounded, 'color': const Color(0xFF6C63FF)},
    {'label': 'Vegetarian', 'icon': Icons.eco_rounded, 'color': const Color(0xFF4CAF50)},
    {'label': 'Vegan', 'icon': Icons.grass_rounded, 'color': const Color(0xFF66BB6A)},
    {'label': 'Eggetarian', 'icon': Icons.egg_rounded, 'color': const Color(0xFFFFB74D)},
    {'label': 'Non-Veg', 'icon': Icons.set_meal_rounded, 'color': const Color(0xFFEF5350)},
    {'label': 'Jain', 'icon': Icons.spa_rounded, 'color': const Color(0xFFAB47BC)},
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _generateWellnessPlan() async {
    final isPlus = PlusService.instance.isPlus;
    if (!isPlus) {
      _showUpgradeDialog();
      return;
    }

    setState(() {
      _isGenerating = true;
      _error = null;
      _generatedPlan = null;
    });

    try {
      final cycle = Provider.of<CycleProvider>(context, listen: false);
      final history = cycle.getWellnessHistory(_selectedTimeRange);
      final symptomFreq = cycle.getSymptomFrequency(_selectedTimeRange);
      final phase = cycle.currentPhase;
      final context_ = cycle.aiUserContext;

      // Build the detailed prompt
      final historyLines = history.map((e) {
        final d = e['date'] as DateTime;
        final dateStr = '${d.month}/${d.day}';
        final symptoms = (e['symptoms'] as List<String>).join(', ');
        return '$dateStr — Sleep: ${e['sleep']}h, Water: ${e['water']}gl, Steps: ${e['steps']}, Mood: ${e['mood']}, Symptoms: ${symptoms.isEmpty ? 'None' : symptoms}';
      }).join('\n');

      final topSymptoms = symptomFreq.entries
          .take(5)
          .map((e) => '${e.key} (${e.value}x)')
          .join(', ');

      final dietInstruction = _selectedDiet == 'No Preference'
          ? 'No specific dietary restriction.'
          : 'Dietary preference: $_selectedDiet. STRICTLY follow this restriction — do NOT suggest foods outside this diet.';

      final prompt = '''
You are a certified women's health and wellness specialist AI. Generate a personalized Weekly Wellness Plan.

=== USER PROFILE ===
$context_

=== DIETARY PREFERENCE ===
$dietInstruction
IMPORTANT: Focus heavily on **Indian cuisine and ingredients** (dal, roti, sabzi, rice, paneer, curd/dahi, ghee, turmeric, jeera, methi, amla, chana, rajma, poha, idli, upma, khichdi, etc.). Use Indian dish names and common Indian superfoods. Only suggest Western foods if highly relevant.

=== LAST $_selectedTimeRange DAYS HEALTH LOG ===
$historyLines

=== TOP SYMPTOMS (by frequency) ===
${topSymptoms.isEmpty ? 'No symptoms logged' : topSymptoms}

=== CURRENT CYCLE PHASE ===
$phase phase

=== INSTRUCTIONS ===
Create a comprehensive, actionable wellness plan with these EXACT sections:

🍎 **NUTRITION PLAN**
- 4-5 specific Indian food/meal recommendations tailored to the current cycle phase and logged symptoms
- Include breakfast, lunch, dinner, and snack ideas with Indian dishes
- Foods to avoid based on symptoms and diet preference
- Hydration target (include Indian drinks like nimbu pani, buttermilk/chaas, haldi doodh)

💤 **SLEEP HYGIENE**
- Personalized sleep recommendations based on logged sleep hours
- Wind-down routine suggestions
- Optimal sleep target for this phase

🧘 **STRESS MANAGEMENT**
- 2-3 techniques specific to the current cycle phase
- Include yoga asanas or pranayama suggestions
- Activity suggestions based on energy levels

🏃 **ACTIVITY RECOMMENDATIONS**
- Exercise type and intensity for this cycle phase
- Step goal adjustment based on recent history
- Recovery suggestions if needed

⚠️ **SYMPTOM ALERTS**
- Flag any concerning patterns from the logged data
- Suggest when to consult a doctor
- Preventive tips for recurring symptoms
- Include relevant Ayurvedic or home remedies where appropriate

Keep the tone warm, supportive, and empowering. Use emojis sparingly. Be specific — reference the actual data provided.
''';

      final model = GroqModel(
        model: PlusService.plusModels.first,
        apiKey: AppConfig.groqApiKey,
        systemInstruction:
            'You are Lunara AI, a compassionate women\'s health wellness advisor. Provide evidence-based, personalized wellness plans. Be warm but professional. Format your response with clear sections using markdown headers and bullet points.',
      );

      final response = await model.generateChatCompletion(
        messages: [
          {'role': 'user', 'content': prompt},
        ],
      );

      if (mounted) {
        setState(() {
          _generatedPlan = response;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to generate plan. Please try again.';
          _isGenerating = false;
        });
      }
    }
  }

  void _showUpgradeDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).padding.bottom + 24,
          left: 24,
          right: 24,
          top: 32,
        ),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(ctx),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider(ctx),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF7A8A), Color(0xFFD8405B)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD8405B).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'Unlock AI Wellness Plans',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.textDark(ctx),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get personalized nutrition, sleep, and stress management plans powered by advanced AI.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textLight(ctx),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await PlusService.instance.setPlus(true);
                  if (mounted) {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        behavior: SnackBarBehavior.floating,
                        padding: EdgeInsets.zero,
                        content: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  color: Colors.white),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Plus unlocked! Generate your wellness plan.',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD8405B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Upgrade to Plus',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Maybe later',
                style: TextStyle(
                  color: AppTheme.textLight(ctx),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: Consumer<CycleProvider>(
        builder: (context, cycle, _) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverHeader(cycle),
                _buildTimeRangeSelector(),
                _buildDietPreferences(),
                _buildHealthOverview(cycle),
                _buildSymptomSection(cycle),
                _buildGenerateButton(),
                if (_isGenerating) _buildLoadingSection(),
                if (_error != null) _buildErrorSection(),
                if (_generatedPlan != null) _buildPlanSection(),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverHeader(CycleProvider cycle) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          left: 20,
          right: 20,
          bottom: 24,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6C63FF).withOpacity(0.15),
              const Color(0xFFFF7A8A).withOpacity(0.1),
              AppTheme.background(context),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor(context),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppTheme.softShadow(context),
                    ),
                    child: Icon(Icons.arrow_back_ios_new,
                        size: 18, color: AppTheme.textDark(context)),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: PlusService.instance.isPlus
                        ? const LinearGradient(
                            colors: [Color(0xFFFFB74D), Color(0xFFFF9800)])
                        : null,
                    color: PlusService.instance.isPlus
                        ? null
                        : AppTheme.subtleBackground(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PlusService.instance.isPlus
                            ? Icons.workspace_premium_rounded
                            : Icons.lock_outline_rounded,
                        size: 14,
                        color: PlusService.instance.isPlus
                            ? Colors.white
                            : AppTheme.textLight(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        PlusService.instance.isPlus ? 'PRO' : 'FREE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: PlusService.instance.isPlus
                              ? Colors.white
                              : AppTheme.textLight(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF5B52CC)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.health_and_safety_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Wellness Plan',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textDark(context),
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        '${cycle.currentPhase} Phase · Day ${cycle.currentCycleDay}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textLight(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Text(
              'Analyze',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildRangeChip(7, '7 days'),
                    const SizedBox(width: 8),
                    _buildRangeChip(14, '14 days'),
                    const SizedBox(width: 8),
                    _buildRangeChip(30, '30 days'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDietPreferences() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppTheme.softShadow(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.restaurant_menu_rounded,
                      color: const Color(0xFF4CAF50), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Diet Preference',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark(context),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🇮🇳', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          'Indian Focus',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFFF9800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Your meals will be tailored to Indian cuisine',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textLight(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _dietOptions.map((opt) {
                  final isSelected = _selectedDiet == opt['label'];
                  final color = opt['color'] as Color;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedDiet = opt['label'] as String);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.15)
                            : AppTheme.subtleBackground(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? color : AppTheme.divider(context),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(opt['icon'] as IconData,
                              color: isSelected ? color : AppTheme.textLight(context),
                              size: 18),
                          const SizedBox(width: 8),
                          Text(
                            opt['label'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? color : AppTheme.textDark(context),
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.check_circle_rounded, color: color, size: 16),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRangeChip(int days, String label) {
    final isSelected = _selectedTimeRange == days;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedTimeRange = days);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF5B52CC)])
              : null,
          color: isSelected ? null : AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppTheme.divider(context),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppTheme.textLight(context),
          ),
        ),
      ),
    );
  }

  Widget _buildHealthOverview(CycleProvider cycle) {
    final history = cycle.getWellnessHistory(_selectedTimeRange);
    double avgSleep = 0;
    int avgWater = 0;
    int avgSteps = 0;
    int daysWithData = 0;

    for (final entry in history) {
      final sleep = (entry['sleep'] as double);
      final water = (entry['water'] as int);
      final steps = (entry['steps'] as int);
      if (sleep > 0 || water > 0 || steps > 0) {
        avgSleep += sleep;
        avgWater += water;
        avgSteps += steps;
        daysWithData++;
      }
    }

    if (daysWithData > 0) {
      avgSleep /= daysWithData;
      avgWater = (avgWater / daysWithData).round();
      avgSteps = (avgSteps / daysWithData).round();
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppTheme.softShadow(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.dashboard_rounded,
                      color: const Color(0xFF6C63FF), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Health Overview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark(context),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$daysWithData days tracked',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6C63FF),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _buildOverviewCard(
                      Icons.nightlight_rounded,
                      'Avg Sleep',
                      '${avgSleep.toStringAsFixed(1)}h',
                      const Color(0xFFB39DDB),
                      avgSleep >= 7 ? 'Good' : 'Low',
                      avgSleep >= 7,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildOverviewCard(
                      Icons.water_drop_rounded,
                      'Avg Water',
                      '${avgWater}gl',
                      const Color(0xFF64B5F6),
                      avgWater >= 6 ? 'Good' : 'Low',
                      avgWater >= 6,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildOverviewCard(
                      Icons.directions_walk_rounded,
                      'Avg Steps',
                      avgSteps > 999
                          ? '${(avgSteps / 1000).toStringAsFixed(1)}k'
                          : '$avgSteps',
                      const Color(0xFF81C784),
                      avgSteps >= 5000 ? 'Good' : 'Low',
                      avgSteps >= 5000,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(IconData icon, String label, String value,
      Color color, String status, bool isGood) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textLight(context),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isGood
                  ? const Color(0xFF4CAF50).withOpacity(0.15)
                  : const Color(0xFFFF9800).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: isGood
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFFF9800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomSection(CycleProvider cycle) {
    final symptomFreq = cycle.getSymptomFrequency(_selectedTimeRange);
    final todaySymptoms = cycle.todaySymptoms;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppTheme.softShadow(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.monitor_heart_rounded,
                      color: LunaraColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Logged Symptoms',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Your symptom patterns over the last $_selectedTimeRange days',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textLight(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              // Today's symptoms
              if (todaySymptoms.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary(context).withOpacity(0.08),
                        AppTheme.primary(context).withOpacity(0.02),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.primary(context).withOpacity(0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF4CAF50).withOpacity(0.4),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Today',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textDark(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: todaySymptoms.map((s) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primary(context).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    AppTheme.primary(context).withOpacity(0.25),
                              ),
                            ),
                            child: Text(
                              s,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary(context),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Symptom frequency bars
              if (symptomFreq.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: AppTheme.textLight(context), size: 32),
                        const SizedBox(height: 8),
                        Text(
                          'No symptoms logged yet',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textLight(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Log symptoms on the home screen to see patterns here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLight(context).withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...symptomFreq.entries.take(8).map((entry) {
                  final maxCount = symptomFreq.values.first;
                  final ratio = maxCount > 0 ? entry.value / maxCount : 0.0;
                  final color = _symptomColor(entry.key);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOutCubic,
                              tween: Tween(begin: 0, end: ratio),
                              builder: (context, value, _) {
                                return LinearProgressIndicator(
                                  value: value,
                                  minHeight: 10,
                                  backgroundColor: color.withOpacity(0.1),
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(color),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${entry.value}x',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Color _symptomColor(String symptom) {
    final colors = {
      'Cramps': LunaraColors.primary,
      'Headache': LunaraColors.warning,
      'Fatigue': const Color(0xFFBA68C8),
      'Bloating': LunaraColors.ovulationBlue,
      'Mood Swings': const Color(0xFFFFD54F),
      'Nausea': LunaraColors.fertileGreen,
      'Back Pain': const Color(0xFFE57373),
      'Breast Tenderness': LunaraColors.primary,
    };
    return colors[symptom] ?? const Color(0xFF6C63FF);
  }

  Widget _buildGenerateButton() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: GestureDetector(
          onTap: _isGenerating ? null : _generateWellnessPlan,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: _isGenerating
                  ? LinearGradient(
                      colors: [
                        Colors.grey.shade400,
                        Colors.grey.shade500,
                      ],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF5B52CC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: _isGenerating
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isGenerating) ...[
                  const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                ],
                Text(
                  _isGenerating
                      ? 'Generating Your Plan...'
                      : 'Generate Wellness Plan',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                if (!PlusService.instance.isPlus) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'PRO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppTheme.softShadow(context),
          ),
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, _) {
                  return Transform.rotate(
                    angle: _shimmerController.value * 2 * math.pi,
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF6C63FF),
                      size: 36,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Analyzing your health data...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Creating a personalized plan just for you',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textLight(context),
                ),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  backgroundColor:
                      const Color(0xFF6C63FF).withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF6C63FF)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFEF5350).withOpacity(0.08),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: const Color(0xFFEF5350).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFEF5350), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFEF5350),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: _generateWellnessPlan,
                child: const Text('Retry',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanSection() {
    // Parse the markdown-like plan into styled widgets
    final lines = _generatedPlan!.split('\n');

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppTheme.softShadow(context),
            border: Border.all(
              color: const Color(0xFF6C63FF).withOpacity(0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF5B52CC)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Your Wellness Plan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textDark(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Generated based on your last $_selectedTimeRange days of data',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textLight(context),
                ),
              ),
              const Divider(height: 24),
              // Render the plan content
              ...lines.map((line) {
                final trimmed = line.trim();
                if (trimmed.isEmpty) return const SizedBox(height: 6);

                // Section headers (## or **)
                if (trimmed.startsWith('##') ||
                    (trimmed.startsWith('**') && trimmed.endsWith('**'))) {
                  final headerText = trimmed
                      .replaceAll('#', '')
                      .replaceAll('**', '')
                      .trim();
                  return Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Text(
                      headerText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark(context),
                      ),
                    ),
                  );
                }

                // Bullet points
                if (trimmed.startsWith('-') || trimmed.startsWith('•')) {
                  final bulletText =
                      trimmed.substring(1).trim();
                  // Process inline bold
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 7),
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildRichText(bulletText),
                        ),
                      ],
                    ),
                  );
                }

                // Regular text
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _buildRichText(trimmed),
                );
              }),
              const SizedBox(height: 16),
              // Regenerate button
              Center(
                child: TextButton.icon(
                  onPressed: _generateWellnessPlan,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Regenerate Plan'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6C63FF),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Renders text with **bold** inline formatting
  Widget _buildRichText(String text) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: AppTheme.textDark(context),
        ),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 13,
          height: 1.6,
          color: AppTheme.textDark(context).withOpacity(0.85),
          fontWeight: FontWeight.w500,
        ),
        children: spans.isEmpty ? [TextSpan(text: text)] : spans,
      ),
    );
  }
}
