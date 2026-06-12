// lib/screens/sleep_assessment_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/cycle_provider.dart';
import '../theme/app_theme.dart';
import 'period_regularity_screen.dart';

class SleepAssessmentScreen extends StatefulWidget {
  const SleepAssessmentScreen({super.key});

  @override
  State<SleepAssessmentScreen> createState() => _SleepAssessmentScreenState();
}

class _SleepAssessmentScreenState extends State<SleepAssessmentScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 2; // Default to "Fair" (middle)
  final double _knobSize = 60.0;

  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _breathingController;

  final List<Map<String, dynamic>> _levels = [
    {
      'label': 'Worst',
      'sub': '< 3 HOURS',
      'color': const Color(0xFFE63946),
      'icon': Icons.bedtime_off_rounded,
      'desc': 'Barely any rest'
    },
    {
      'label': 'Poor',
      'sub': '3-4 HOURS',
      'color': const Color(0xFFFF8566),
      'icon': Icons.nights_stay_outlined,
      'desc': 'Restless night'
    },
    {
      'label': 'Fair',
      'sub': '5 HOURS',
      'color': const Color(0xFFFFB703),
      'icon': Icons.nightlight_round,
      'desc': 'Could be better'
    },
    {
      'label': 'Good',
      'sub': '6-7 HOURS',
      'color': const Color(0xFF06D6A0),
      'icon': Icons.bed_rounded,
      'desc': 'Decent rest'
    },
    {
      'label': 'Excellent',
      'sub': '8+ HOURS',
      'color': const Color(0xFF118AB2),
      'icon': Icons.king_bed_rounded,
      'desc': 'Well rested!'
    },
  ];

  int _mapHoursToIndex(double hours) {
    if (hours <= 0) return 2; // Default to "Fair" (index 2)
    if (hours < 3.0) return 0;
    if (hours < 5.0) return 1;
    if (hours < 6.0) return 2;
    if (hours < 8.0) return 3;
    return 4;
  }

  @override
  void initState() {
    super.initState();

    // Load initial sleep selection from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final cycleProvider = Provider.of<CycleProvider>(context, listen: false);
        final initialHours = cycleProvider.sleepHours;
        if (initialHours > 0) {
          setState(() {
            _selectedIndex = _mapHoursToIndex(initialHours);
          });
        }
      }
    });

    // Entry animation
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

    // Breathing animation for background
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color activeColor = _levels[_selectedIndex]['color'];

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: Stack(
        children: [
          // Animated breathing background
          AnimatedBuilder(
            animation: _breathingController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, 0),
                    radius: 0.8 + (_breathingController.value * 0.2),
                    colors: [
                      activeColor.withOpacity(0.1),
                      AppTheme.background(context),
                    ],
                  ),
                ),
              );
            },
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 20),
                  child: Column(
                    children: [
                      // Plus Header
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
                                color: AppTheme.cardColor(context),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.arrow_back_ios_new,
                                size: 18,
                                color: AppTheme.textDark(context),
                              ),
                            ),
                          ),
                          Text(
                            "Assessment",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppTheme.textDark(context),
                              letterSpacing: 0.3,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  activeColor.withOpacity(0.8),
                                  activeColor,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: activeColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Text(
                              "3 OF 7",
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

                      const SizedBox(height: 35),

                      // Title with Icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: activeColor.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.nightlight_rounded,
                              color: activeColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Flexible(
                            child: Text(
                              "Sleep Quality",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Text(
                        "Drag the slider to rate your sleep last night",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 35),

                      // Selected Level Card
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.8, end: 1.0)
                                  .animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          key: ValueKey(_selectedIndex),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                activeColor.withOpacity(0.15),
                                activeColor.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: activeColor.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _levels[_selectedIndex]['icon'],
                                size: 40,
                                color: activeColor,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _levels[_selectedIndex]['label'],
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: activeColor,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _levels[_selectedIndex]['sub'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey[700],
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _levels[_selectedIndex]['desc'],
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Plus Slider Section
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 30),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor(context),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: activeColor.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Left Labels
                              Expanded(
                                flex: 3,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children:
                                      List.generate(_levels.length, (index) {
                                    int realIndex = _levels.length - 1 - index;
                                    bool isSelected =
                                        realIndex == _selectedIndex;

                                    return AnimatedOpacity(
                                      duration:
                                          const Duration(milliseconds: 400),
                                      opacity: isSelected ? 1.0 : 0.3,
                                      child: AnimatedScale(
                                        scale: isSelected ? 1.05 : 0.95,
                                        duration:
                                            const Duration(milliseconds: 300),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _levels[realIndex]['label'],
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? _levels[realIndex]
                                                        ['color']
                                                    : AppTheme.textDark(context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),

                              // Track & Knob
                              Expanded(
                                flex: 2,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return GestureDetector(
                                      behavior: HitTestBehavior.translucent,
                                      onVerticalDragUpdate: (details) {
                                        _handleDrag(details.localPosition,
                                            constraints.maxHeight);
                                      },
                                      onTapDown: (details) {
                                        _handleDrag(details.localPosition,
                                            constraints.maxHeight);
                                      },
                                      child: Stack(
                                        alignment: Alignment.center,
                                        clipBehavior: Clip.none,
                                        children: [
                                          // Background Track
                                          Container(
                                            width: 14,
                                            height: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.05),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Animated Colored Track
                                          AnimatedPositioned(
                                            duration: const Duration(
                                                milliseconds: 500),
                                            curve: Curves.easeOutCubic,
                                            bottom: 0,
                                            top: _getTrackTopPosition(
                                                constraints.maxHeight),
                                            child: Container(
                                              width: 14,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    activeColor
                                                        .withOpacity(0.6),
                                                    activeColor,
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),

                                          // Plus Knob
                                          AnimatedPositioned(
                                            duration: const Duration(
                                                milliseconds: 500),
                                            curve: Curves.easeOutCubic,
                                            bottom: _getKnobBottomPosition(
                                                constraints.maxHeight),
                                            child: Container(
                                              height: _knobSize,
                                              width: _knobSize,
                                              decoration: BoxDecoration(
                                                gradient: RadialGradient(
                                                  colors: [
                                                    activeColor,
                                                    activeColor
                                                        .withOpacity(0.8),
                                                  ],
                                                ),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: activeColor
                                                        .withOpacity(0.5),
                                                    blurRadius: 20,
                                                    offset: const Offset(0, 8),
                                                  ),
                                                  BoxShadow(
                                                    color: activeColor
                                                        .withOpacity(0.3),
                                                    blurRadius: 35,
                                                    spreadRadius: 5,
                                                  ),
                                                ],
                                                border: Border.all(
                                                    color: Colors.white,
                                                    width: 5),
                                              ),
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  Container(
                                                    height: 35,
                                                    width: 35,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: Colors.white
                                                            .withOpacity(0.3),
                                                        width: 1,
                                                      ),
                                                    ),
                                                  ),
                                                  const Icon(
                                                    Icons.unfold_more_rounded,
                                                    color: Colors.white,
                                                    size: 26,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // Right Emojis
                              Expanded(
                                flex: 2,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children:
                                      List.generate(_levels.length, (index) {
                                    int realIndex = _levels.length - 1 - index;
                                    bool isSelected =
                                        realIndex == _selectedIndex;

                                    return AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 400),
                                      curve: Curves.easeOutCubic,
                                      height: isSelected ? 50 : 36,
                                      width: isSelected ? 50 : 36,
                                      decoration: BoxDecoration(
                                        gradient: isSelected
                                            ? RadialGradient(
                                                colors: [
                                                  _levels[realIndex]['color'],
                                                  _levels[realIndex]['color']
                                                      .withOpacity(0.8),
                                                ],
                                              )
                                            : null,
                                        color: isSelected
                                            ? null
                                            : _levels[realIndex]['color']
                                                .withOpacity(0.15),
                                        shape: BoxShape.circle,
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: _levels[realIndex]
                                                          ['color']
                                                      .withOpacity(0.4),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ]
                                            : [],
                                      ),
                                      child: Icon(
                                        _levels[realIndex]['icon'],
                                        color: isSelected
                                            ? Colors.white
                                            : _levels[realIndex]['color'],
                                        size: isSelected ? 28 : 20,
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Continue Button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();

                            // Save sleep hours to CycleProvider
                            final cycleProvider =
                                Provider.of<CycleProvider>(context, listen: false);
                            final hours = [2.0, 3.5, 5.0, 6.5, 8.0][_selectedIndex];
                            cycleProvider.updateSleep(hours);

                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, anim, secAnim) =>
                                    const PeriodRegularityScreen(),
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
                            backgroundColor: activeColor,
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: activeColor.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Continue",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.arrow_forward_rounded, size: 22),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleDrag(Offset position, double height) {
    double dy = height - position.dy;
    double percentage = (dy / height).clamp(0.0, 1.0);
    int newIndex = (percentage * 4).round();

    if (newIndex != _selectedIndex) {
      HapticFeedback.mediumImpact();
      setState(() {
        _selectedIndex = newIndex;
      });
    }
  }

  double _getTrackTopPosition(double maxHeight) {
    double topDistToCenter = maxHeight * (1 - (_selectedIndex / 4.0));
    return topDistToCenter.clamp(0.0, maxHeight);
  }

  double _getKnobBottomPosition(double maxHeight) {
    double centerPointY = (_selectedIndex / 4.0) * maxHeight;
    double bottomPos = centerPointY - (_knobSize / 2.0);
    return bottomPos.clamp(0.0, maxHeight - _knobSize);
  }
}
