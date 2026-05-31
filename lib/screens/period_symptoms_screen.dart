import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cycle_provider.dart';
import 'period_start_setup_screen.dart';
import 'main_screen.dart';

import '../theme/app_theme.dart';

class PeriodSymptomsScreen extends StatefulWidget {
  final bool isRequiredDailyLog;

  const PeriodSymptomsScreen({super.key, this.isRequiredDailyLog = false});

  @override
  State<PeriodSymptomsScreen> createState() => _PeriodSymptomsScreenState();
}

class _PeriodSymptomsScreenState extends State<PeriodSymptomsScreen>
    with TickerProviderStateMixin {
  final Set<String> _selectedSymptoms = {};
  String? _expandedSymptom;

  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, dynamic>> _symptoms = [
    {
      'name': '🌿 Yeast Infections',
      'icon': Icons.local_florist_rounded,
      'description':
          'Yeast infections are more common than you think, and they can be so uncomfortable — but you\'re not alone. Lunara is here to help you feel supported and confident while you take care of your body.',
      'tips':
          'Wear breathable cotton underwear, avoid douching, and consider probiotics. Consult your doctor for antifungal treatment.',
      'color': LunaraColors.fertileGreen,
    },
    {
      'name': '🦠 Bacterial Vaginosis (BV)',
      'icon': Icons.science_rounded,
      'description':
          "BV can feel confusing or uncomfortable, but it's much more common than you may think. Lunara is a safe, judgment-free space where you're understood and supported.",
      'tips':
          'Avoid scented products, maintain good hygiene, and see your doctor for antibiotics if needed.',
      'color': LunaraColors.ovulationBlue,
    },
    {
      'name': '🫧 Polycystic Ovary Syndrome (PCOS)',
      'icon': Icons.bubble_chart_rounded,
      'description':
          'PCOS can bring emotional and physical challenges, but your strength is real. You\'re not alone — Lunara will walk with you gently and consistently.',
      'tips':
          'Maintain a balanced diet, exercise regularly, manage stress, and work with your healthcare provider on a treatment plan.',
      'color': const Color(0xFFBA68C8),
    },
    {
      'name': '💮 Endometriosis',
      'icon': Icons.favorite_border_rounded,
      'description':
          'Endometriosis can be incredibly tough, and the pain can feel isolating. But you deserve support, understanding, and compassion. Lunara is here to stand with you.',
      'tips':
          'Use heat therapy for pain, try anti-inflammatory foods, practice gentle yoga, and work closely with your gynecologist.',
      'color': const Color(0xFFE57373),
    },
    {
      'name': '🎈 Fibroids',
      'icon': Icons.circle_outlined,
      'description':
          'Fibroids can bring discomfort and uncertainty, but so many women experience them too. Lunara is here to offer comfort, clarity, and steady support.',
      'tips':
          'Monitor your symptoms, maintain a healthy weight, eat iron-rich foods, and discuss treatment options with your doctor.',
      'color': LunaraColors.warning,
    },
    {
      'name': '💧 Urinary Tract Infections (UTIs)',
      'icon': Icons.water_drop_outlined,
      'description':
          'UTIs can be incredibly uncomfortable, and dealing with them can feel frustrating and draining. But you\'re not alone — so many women experience this, and your discomfort is valid.',
      'tips':
          'Drink plenty of water, urinate after intercourse, wipe front to back, avoid irritating feminine products, and see your doctor for antibiotics.',
      'color': const Color(0xFF4FC3F7),
    },
    {
      'name': '❓ I\'m Not Sure',
      'icon': Icons.help_outline_rounded,
      'description':
          'It\'s completely okay not to know exactly what you\'re experiencing. Many conditions share similar symptoms. Lunara will help you track patterns and provide insights.',
      'tips':
          'Keep detailed notes of your symptoms, track when they occur, and schedule an appointment with your healthcare provider for proper diagnosis.',
      'color': const Color(0xFFA1887F),
    },
  ];

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic));

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _handleComplete() async {
    HapticFeedback.mediumImpact();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cycleProvider = Provider.of<CycleProvider>(context, listen: false);

    final alreadyHasData = cycleProvider.bodyMetricsCompleted ||
        (cycleProvider.lastPeriodDate != null &&
            cycleProvider.weight != 60 &&
            cycleProvider.height != 165);

    if (authProvider.hasCompletedOnboarding || alreadyHasData) {
      // Returning user — skip setup screens, go straight to main
      await authProvider.completeAssessment();

      // Auto-fix the flag if it was lost (e.g., after logout + re-login)
      if (!authProvider.hasCompletedOnboarding) {
        await authProvider.completeOnboarding();
      }

      Navigator.pushAndRemoveUntil(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (route) => false,
      );
    } else {
      // Brand new user — collect period setup + body metrics
      await authProvider.completeAssessment();

      Navigator.pushAndRemoveUntil(
        // ignore: use_build_context_synchronously
        context,
        PageRouteBuilder(
          pageBuilder: (context, anim, secAnim) =>
              const PeriodStartSetupScreen(),
          transitionsBuilder: (context, anim, secAnim, child) {
            return FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(anim),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              LunaraColors.primaryLight.withOpacity(0.6),
              LunaraColors.backgroundPink.withOpacity(0.6),
              const Color(0xFFE1BEE7).withOpacity(0.6),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Premium Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 18,
                              color: LunaraColors.textDark,
                            ),
                          ),
                        ),
                        const Text(
                          "Daily Check-in",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: LunaraColors.textDark,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                LunaraColors.primary,
                                Color(0xFFFFB4A9),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: LunaraColors.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Text(
                            "6 OF 7",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Title Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                LunaraColors.primary,
                                LunaraColors.primaryDark,
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: LunaraColors.primary.withOpacity(0.4),
                                blurRadius: 25,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.health_and_safety_rounded,
                            size: 35,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'Which symptoms are\nyou experiencing?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: LunaraColors.textDark,
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'Tap to learn more, select to track',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Selection Counter
                        if (_selectedSymptoms.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: LunaraColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: LunaraColors.primary.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              '${_selectedSymptoms.length} symptom${_selectedSymptoms.length > 1 ? 's' : ''} selected',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: LunaraColors.primaryDark,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Symptom List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      itemCount: _symptoms.length,
                      itemBuilder: (context, index) {
                        final symptom = _symptoms[index];
                        final isSelected =
                            _selectedSymptoms.contains(symptom['name']);
                        final isExpanded = _expandedSymptom == symptom['name'];

                        return Column(
                          children: [
                            // Main Symptom Card
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  if (isExpanded) {
                                    _expandedSymptom = null;
                                  } else {
                                    _expandedSymptom = symptom['name'];
                                  }
                                });
                              },
                              child: TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                tween: Tween(
                                    begin: 0.0, end: isSelected ? 1.0 : 0.0),
                                builder: (context, value, child) {
                                  return Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      gradient: value > 0
                                          ? LinearGradient(
                                              colors: [
                                                symptom['color']
                                                    .withOpacity(0.15 * value),
                                                symptom['color']
                                                    .withOpacity(0.05 * value),
                                              ],
                                            )
                                          : null,
                                      color: value == 0 ? Colors.white : null,
                                      borderRadius: BorderRadius.circular(
                                        isExpanded ? 20 : 25,
                                      ),
                                      border: Border.all(
                                        color: Color.lerp(
                                          Colors.grey.shade200,
                                          symptom['color'],
                                          value,
                                        )!,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color.lerp(
                                            Colors.black.withOpacity(0.04),
                                            symptom['color'].withOpacity(0.2),
                                            value,
                                          )!,
                                          blurRadius: 10 + (8 * value),
                                          offset: Offset(0, 4 + (4 * value)),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        // Icon
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: symptom['color']
                                                .withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            symptom['icon'],
                                            color: symptom['color'],
                                            size: 24,
                                          ),
                                        ),

                                        const SizedBox(width: 15),

                                        // Name
                                        Expanded(
                                          child: Text(
                                            symptom['name'],
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: Color.lerp(
                                                LunaraColors.textDark,
                                                symptom['color'],
                                                value,
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Expand/Select Indicator
                                        Row(
                                          children: [
                                            if (isExpanded)
                                              Icon(
                                                Icons.expand_less_rounded,
                                                color: symptom['color'],
                                                size: 24,
                                              )
                                            else
                                              Icon(
                                                Icons.expand_more_rounded,
                                                color: Colors.grey[400],
                                                size: 24,
                                              ),
                                            const SizedBox(width: 8),
                                            // Checkbox
                                            Container(
                                              width: 26,
                                              height: 26,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: symptom['color'],
                                                  width: 2.5,
                                                ),
                                                color: isSelected
                                                    ? symptom['color']
                                                    : Colors.transparent,
                                              ),
                                              child: isSelected
                                                  ? const Icon(
                                                      Icons.check_rounded,
                                                      size: 16,
                                                      color: Colors.white,
                                                    )
                                                  : null,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),

                            // Expanded Info Card
                            AnimatedSize(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutCubic,
                              child: isExpanded
                                  ? Container(
                                      margin: const EdgeInsets.only(
                                          top: 8, bottom: 12),
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color:
                                              symptom['color'].withOpacity(0.3),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: symptom['color']
                                                .withOpacity(0.1),
                                            blurRadius: 15,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Description
                                          Text(
                                            symptom['description'],
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                              height: 1.6,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),

                                          const SizedBox(height: 15),

                                          // Tips Section
                                          Container(
                                            padding: const EdgeInsets.all(15),
                                            decoration: BoxDecoration(
                                              color: symptom['color']
                                                  .withOpacity(0.08),
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  Icons
                                                      .lightbulb_outline_rounded,
                                                  color: symptom['color'],
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Relief Tips',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              symptom['color'],
                                                        ),
                                                      ),
                                                      const SizedBox(height: 5),
                                                      Text(
                                                        symptom['tips'],
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color:
                                                              Colors.grey[700],
                                                          height: 1.5,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          const SizedBox(height: 15),

                                          // Select Button
                                          SizedBox(
                                            width: double.infinity,
                                            height: 45,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                HapticFeedback.mediumImpact();
                                                setState(() {
                                                  if (isSelected) {
                                                    _selectedSymptoms.remove(
                                                        symptom['name']);
                                                  } else {
                                                    _selectedSymptoms
                                                        .add(symptom['name']);
                                                  }
                                                  _expandedSymptom = null;
                                                });
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: isSelected
                                                    ? Colors.grey[300]
                                                    : symptom['color'],
                                                foregroundColor: isSelected
                                                    ? Colors.grey[700]
                                                    : Colors.white,
                                                elevation: isSelected ? 0 : 3,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                ),
                                              ),
                                              child: Text(
                                                isSelected
                                                    ? 'Remove'
                                                    : 'Select This Symptom',
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),

                            if (index < _symptoms.length - 1)
                              const SizedBox(height: 12),
                          ],
                        );
                      },
                    ),
                  ),

                  // Continue Button
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _handleComplete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LunaraColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: LunaraColors.primary.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _selectedSymptoms.isEmpty
                                  ? 'Skip for Now'
                                  : 'Complete Check-in',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.check_circle_outline_rounded,
                                size: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
