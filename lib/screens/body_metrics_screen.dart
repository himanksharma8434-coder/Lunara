// lib/screens/body_metrics_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/cycle_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';

class BodyMetricsScreen extends StatefulWidget {
  const BodyMetricsScreen({super.key});

  @override
  State<BodyMetricsScreen> createState() => _BodyMetricsScreenState();
}

class _BodyMetricsScreenState extends State<BodyMetricsScreen>
    with TickerProviderStateMixin {
  int _selectedWeight = 60; // kg
  int _selectedHeight = 165; // cm

  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final FixedExtentScrollController _weightController =
      FixedExtentScrollController(initialItem: 30);
  final FixedExtentScrollController _heightController =
      FixedExtentScrollController(initialItem: 115);

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
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic));

    _entryController.forward();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.5),
            radius: 1.5,
            colors: [
              LunaraColors.primary.withOpacity(0.08),
              AppTheme.background(context),
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
                  const SizedBox(height: 24),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                LunaraColors.primary,
                                LunaraColors.primaryDark
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: LunaraColors.primary.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.monitor_weight_rounded,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Body Metrics',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textDark(context),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Help us personalize your experience',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Weight & Height Pickers
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // Weight Section
                                Expanded(
                                  child: _buildMetricPicker(
                                    label: 'Weight',
                                    unit: 'kg',
                                    value: _selectedWeight,
                                    minValue: 30,
                                    maxValue: 200,
                                    controller: _weightController,
                                    color: LunaraColors.primary,
                                    onChanged: (index) {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        _selectedWeight = 30 + index;
                                      });
                                    },
                                  ),
                                ),

                                const SizedBox(width: 16),

                                // Height Section
                                Expanded(
                                  child: _buildMetricPicker(
                                    label: 'Height',
                                    unit: 'cm',
                                    value: _selectedHeight,
                                    minValue: 50,
                                    maxValue: 250,
                                    controller: _heightController,
                                    color: const Color(0xFF118AB2),
                                    onChanged: (index) {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        _selectedHeight = 50 + index;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // BMI Display
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF06D6A0).withOpacity(0.15),
                                    const Color(0xFF06D6A0).withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      const Color(0xFF06D6A0).withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.health_and_safety_rounded,
                                    color: Color(0xFF06D6A0),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'BMI: ${_calculateBMI()}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF06D6A0),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${_getBMICategory()})',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Continue Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saveAndContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LunaraColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: LunaraColors.primary.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(Icons.arrow_forward_rounded, size: 24),
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

  Widget _buildMetricPicker({
    required String label,
    required String unit,
    required int value,
    required int minValue,
    required int maxValue,
    required FixedExtentScrollController controller,
    required Color color,
    required Function(int) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),

          // Large Value Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Scrollable Picker
          SizedBox(
            height: 160,
            child: Stack(
              children: [
                // Selection Indicator
                Center(
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  ),
                ),

                // Scrollable List
                ListWheelScrollView.useDelegate(
                  controller: controller,
                  itemExtent: 45,
                  diameterRatio: 1.5,
                  perspective: 0.003,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: onChanged,
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: maxValue - minValue + 1,
                    builder: (context, index) {
                      final itemValue = minValue + index;
                      final isSelected = itemValue == value;

                      return Center(
                        child: Text(
                          '$itemValue',
                          style: TextStyle(
                            fontSize: isSelected ? 20 : 16,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? color : Colors.grey[400],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _calculateBMI() {
    final heightInMeters = _selectedHeight / 100;
    final bmi = _selectedWeight / (heightInMeters * heightInMeters);
    return bmi.toStringAsFixed(1);
  }

  String _getBMICategory() {
    final bmi = double.parse(_calculateBMI());
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  void _saveAndContinue() async {
    HapticFeedback.mediumImpact();

    final cycleProvider = Provider.of<CycleProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Save body metrics
    cycleProvider.setWeight(_selectedWeight);
    cycleProvider.setHeight(_selectedHeight);
    cycleProvider.setBodyMetricsCompleted(true); // Mark as completed
    await authProvider.completeOnboarding();

    // Sync full profile to cloud after onboarding
    cycleProvider.syncProfileToCloud();

    if (!mounted) return;
    // Navigate to main screen
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) => const MainScreen(),
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
