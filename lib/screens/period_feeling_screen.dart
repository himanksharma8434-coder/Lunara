// lib/screens/period_feeling_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'period_symptoms_screen.dart';

import '../theme/app_theme.dart';

class PeriodFeelingScreen extends StatefulWidget {
  final bool isRequiredDailyLog;

  const PeriodFeelingScreen({super.key, this.isRequiredDailyLog = false});

  @override
  State<PeriodFeelingScreen> createState() => _PeriodFeelingScreenState();
}

class _PeriodFeelingScreenState extends State<PeriodFeelingScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = -1;

  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, dynamic>> _feelings = [
    {
      'label': 'Happy',
      'color': const Color(0xFFFFD54F),
      'icon': Icons.sentiment_very_satisfied_rounded,
      'description':
          'Feeling positive and energized! Your mood is bright and you\'re ready to take on the day.',
      'emoji': '😊'
    },
    {
      'label': 'Tired',
      'color': const Color(0xFFB39DDB),
      'icon': Icons.bedtime_rounded,
      'description':
          'Low energy and need rest. It\'s okay to slow down and prioritize self-care today.',
      'emoji': '😴'
    },
    {
      'label': 'Moody',
      'color': const Color(0xFF90CAF9),
      'icon': Icons.cloud_queue_rounded,
      'description':
          'Emotions feel up and down. This is completely normal during your cycle.',
      'emoji': '😐'
    },
    {
      'label': 'Relaxed',
      'color': LunaraColors.fertileGreen,
      'icon': Icons.spa_rounded,
      'description':
          'Feeling calm and at peace. You\'re in tune with your body and mind.',
      'emoji': '😌'
    },
    {
      'label': 'In Pain',
      'color': const Color(0xFFEF9A9A),
      'icon': Icons.healing_rounded,
      'description':
          'Experiencing discomfort or cramps. We\'ll help you track patterns and find relief.',
      'emoji': '😣'
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

  void _handleContinue() async {
    HapticFeedback.mediumImpact();

    // If this is a required daily log, we'll handle completion after all screens
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) =>
            PeriodSymptomsScreen(isRequiredDailyLog: widget.isRequiredDailyLog),
        transitionsBuilder: (context, anim, secAnim, child) {
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
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      children: [
                  // Plus Header
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
                          "Daily Check-in",
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
                            "5 OF 7",
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

                  const SizedBox(height: 20),

                  // Icon + Title
                  Column(
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
                          Icons.favorite_rounded,
                          size: 35,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 25),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Text(
                          "How do you feel about\nyour period today?",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textDark(context),
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Tap a card to learn more",
                        style: TextStyle(
                          fontSize: 15,
                          color: AppTheme.secondaryText(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),

                  // Scrollable Mood Cards
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _feelings.length,
                      itemBuilder: (context, index) {
                        bool isSelected = index == _selectedIndex;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            setState(() => _selectedIndex = index);
                          },
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            tween:
                                Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: 1.0 + (0.08 * value),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 15),
                                  width: 110,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        _feelings[index]['color'],
                                        _feelings[index]['color']
                                            .withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: Color.lerp(
                                        Colors.transparent,
                                        AppTheme.primary(context),
                                        value,
                                      )!,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _feelings[index]['color']
                                            .withOpacity(0.3 + (0.2 * value)),
                                        blurRadius: 15 + (10 * value),
                                        offset: Offset(0, 5 + (5 * value)),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _feelings[index]['emoji'],
                                        style: TextStyle(
                                          fontSize: 40 + (8 * value),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _feelings[index]['label'],
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Explanation Card (appears when option selected)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _selectedIndex == -1
                        ? const SizedBox(key: ValueKey('empty'), height: 200)
                        : Container(
                            key: ValueKey(_selectedIndex),
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor(context),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: _feelings[_selectedIndex]['color']
                                    .withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _feelings[_selectedIndex]['color']
                                      .withOpacity(0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Icon header
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: _feelings[_selectedIndex]
                                                ['color']
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Icon(
                                        _feelings[_selectedIndex]['icon'],
                                        color: _feelings[_selectedIndex]
                                            ['color'],
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Text(
                                        "Feeling ${_feelings[_selectedIndex]['label']}",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: _feelings[_selectedIndex]
                                              ['color'],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),

                                // Description
                                Text(
                                  _feelings[_selectedIndex]['description'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.secondaryText(context),
                                    height: 1.6,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),

                  const Spacer(),

                  // Continue Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
                    child: SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed:
                            _selectedIndex == -1 ? null : _handleContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedIndex == -1
                              ? AppTheme.subtleBackground(context)
                              : _feelings[_selectedIndex]['color'],
                          foregroundColor: Colors.white,
                          elevation: _selectedIndex == -1 ? 0 : 8,
                          shadowColor: _selectedIndex == -1
                              ? null
                              : _feelings[_selectedIndex]['color']
                                  .withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _selectedIndex == -1
                                  ? "Select a Feeling"
                                  : "Continue",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: _selectedIndex == -1
                                    ? AppTheme.textLight(context)
                                    : Colors.white,
                              ),
                            ),
                            if (_selectedIndex != -1) ...[
                              const SizedBox(width: 10),
                              const Icon(Icons.arrow_forward_rounded, size: 22),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                      ],
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
