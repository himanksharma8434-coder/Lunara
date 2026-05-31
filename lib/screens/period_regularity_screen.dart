// lib/screens/period_regularity_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/cycle_provider.dart';
import '../theme/app_theme.dart';
import 'period_feeling_screen.dart';

class PeriodRegularityScreen extends StatefulWidget {
  const PeriodRegularityScreen({super.key});

  @override
  State<PeriodRegularityScreen> createState() => _PeriodRegularityScreenState();
}

class _PeriodRegularityScreenState extends State<PeriodRegularityScreen>
    with TickerProviderStateMixin {
  bool? _isRegular;

  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.5),
            radius: 1.2,
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
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
                child: Column(
                  children: [
                    // Premium Header
                    Row(
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
                            "4 OF 7",
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

                    const Spacer(flex: 1),

                    // Icon + Title Section
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
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
                            Icons.calendar_today_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 25),
                        const Text(
                          "Are your periods\nregular or not?",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: LunaraColors.textDark,
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          "This helps us predict your cycle better",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 50),

                    // Premium Option Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildPremiumOptionCard(
                            label: "Yes, Regular",
                            icon: Icons.check_circle_outline_rounded,
                            description: "Cycles come at predictable times",
                            isSelected: _isRegular == true,
                            color: const Color(0xFF06D6A0),
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              setState(() => _isRegular = true);
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildPremiumOptionCard(
                            label: "No, Irregular",
                            icon: Icons.event_busy_rounded,
                            description: "Cycles vary or are unpredictable",
                            isSelected: _isRegular == false,
                            color: const Color(0xFFFF8566),
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              setState(() => _isRegular = false);
                            },
                          ),
                        ),
                      ],
                    ),

                    const Spacer(flex: 2),

                    // Info Card
                    if (_isRegular != null)
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 400),
                        opacity: _isRegular != null ? 1.0 : 0.0,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: (_isRegular == true
                                      ? const Color(0xFF06D6A0)
                                      : const Color(0xFFFF8566))
                                  .withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: (_isRegular == true
                                          ? const Color(0xFF06D6A0)
                                          : const Color(0xFFFF8566))
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.lightbulb_outline_rounded,
                                  color: _isRegular == true
                                      ? const Color(0xFF06D6A0)
                                      : const Color(0xFFFF8566),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  _isRegular == true
                                      ? "Great! We'll help you track patterns accurately"
                                      : "No worries! We'll help you identify patterns over time",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _isRegular == null
                            ? null
                            : () {
                                HapticFeedback.mediumImpact();
                                Provider.of<CycleProvider>(context, listen: false)
                                    .setIsIrregular(_isRegular == false);
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, anim, secAnim) =>
                                        const PeriodFeelingScreen(),
                                    transitionsBuilder:
                                        (context, anim, secAnim, child) {
                                      return FadeTransition(
                                        opacity: anim,
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0.1, 0),
                                            end: Offset.zero,
                                          ).animate(anim),
                                          child: child,
                                        ),
                                      );
                                    },
                                    transitionDuration:
                                        const Duration(milliseconds: 400),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isRegular == null
                              ? Colors.grey.shade300
                              : LunaraColors.primary,
                          foregroundColor: Colors.white,
                          elevation: _isRegular == null ? 0 : 8,
                          shadowColor: LunaraColors.primary.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isRegular == null
                                  ? "Select an Option"
                                  : "Continue",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: _isRegular == null
                                    ? Colors.grey[500]
                                    : Colors.white,
                              ),
                            ),
                            if (_isRegular != null) ...[
                              const SizedBox(width: 10),
                              const Icon(Icons.arrow_forward_rounded, size: 22),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumOptionCard({
    required String label,
    required IconData icon,
    required String description,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
        builder: (context, value, child) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: value > 0
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(0.15 * value),
                        color.withOpacity(0.05 * value),
                      ],
                    )
                  : null,
              color: value == 0 ? Colors.white : null,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Color.lerp(Colors.grey.shade200, color, value)!,
                width: 2 + (0.5 * value),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color.lerp(
                    Colors.black.withOpacity(0.04),
                    color.withOpacity(0.25),
                    value,
                  )!,
                  blurRadius: 10 + (10 * value),
                  offset: Offset(0, 4 + (4 * value)),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: value > 0
                        ? RadialGradient(
                            colors: [
                              Color.lerp(Colors.grey.shade100, color, value)!,
                              Color.lerp(Colors.grey.shade100,
                                  color.withOpacity(0.8), value)!,
                            ],
                          )
                        : null,
                    color: value == 0 ? Colors.grey.shade100 : null,
                    shape: BoxShape.circle,
                    boxShadow: value > 0
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.4 * value),
                              blurRadius: 15 * value,
                              offset: Offset(0, 5 * value),
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    icon,
                    size: 36,
                    color: Color.lerp(Colors.grey[400]!, Colors.white, value),
                  ),
                ),

                const SizedBox(height: 15),

                // Label
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color.lerp(LunaraColors.textDark, color, value),
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 8),

                // Description
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 12),

                // Checkmark indicator
                Container(
                  height: 5,
                  width: 40 * value,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
