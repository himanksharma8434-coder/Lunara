// lib/screens/assessment_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'expression_analysis_screen.dart';
import 'main_screen.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen>
    with TickerProviderStateMixin {
  double _sliderValue = 0.5;

  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  late AnimationController _breathingController;
  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Plus 5-Level Mood System
  final List<Map<String, dynamic>> _moods = [
    {
      'label': "Terrible",
      'color': const Color(0xFFE63946),
      'icon': Icons.sentiment_very_dissatisfied,
      'subtitle': 'It\'s okay to have tough days'
    },
    {
      'label': "Not Great",
      'color': const Color(0xFFFF8566),
      'icon': Icons.sentiment_dissatisfied,
      'subtitle': 'Tomorrow can be better'
    },
    {
      'label': "Okay",
      'color': const Color(0xFFFFB703),
      'icon': Icons.sentiment_neutral,
      'subtitle': 'Just another day'
    },
    {
      'label': "Good",
      'color': const Color(0xFF06D6A0),
      'icon': Icons.sentiment_satisfied,
      'subtitle': 'Feeling positive today'
    },
    {
      'label': "Amazing!",
      'color': const Color(0xFF118AB2),
      'icon': Icons.sentiment_very_satisfied,
      'subtitle': 'You\'re glowing!'
    },
  ];

  @override
  void initState() {
    super.initState();

    // Entry Animation
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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

    // Bounce Animation
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bounceAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
    _bounceController.forward();

    // Breathing Animation
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _breathingController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  Color get _currentColor {
    double scaledValue = _sliderValue * 4;
    int index = scaledValue.floor();
    double remainder = scaledValue - index;

    if (index >= 4) return _moods[4]['color'];

    Color start = _moods[index]['color'];
    Color end = _moods[index + 1]['color'];

    return Color.lerp(start, end, remainder)!;
  }

  Map<String, dynamic> get _currentMoodData {
    int index = (_sliderValue * 4).round();
    return _moods[index.clamp(0, 4)];
  }

  void _updateMood(double value) {
    Map<String, dynamic> oldMood = _currentMoodData;

    setState(() {
      _sliderValue = value;
    });

    Map<String, dynamic> newMood = _currentMoodData;

    if (oldMood['label'] != newMood['label']) {
      HapticFeedback.mediumImpact();
      _bounceController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color activeColor = _currentColor;
    Map<String, dynamic> activeMood = _currentMoodData;

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: Stack(
        children: [
          // Animated Gradient Background
          AnimatedBuilder(
            animation: _breathingController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.3),
                    radius: 0.9 + (_breathingController.value * 0.15),
                    colors: [
                      activeColor.withOpacity(0.12),
                      AppTheme.background(context),
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              );
            },
          ),

          SafeArea(
              child: SingleChildScrollView(
                  child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      // Plus Header
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24.0, vertical: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Back Button
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
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

                            // Title
                            const Text(
                              "Assessment",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: 0.3,
                              ),
                            ),

                            // Progress Indicator
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
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
                                  width: 1.5,
                                ),
                              ),
                              child: const Text(
                                "1 OF 7",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Title with Icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.self_improvement,
                            color: activeColor,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "How are you feeling?",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textDark(context),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Subtitle
                      Text(
                        "Drag the slider to express your mood",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const Spacer(flex: 1),

                      // Plus Emoji Container
                      ScaleTransition(
                        scale: _bounceAnimation,
                        child: Container(
                          height: 160,
                          width: 160,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                activeColor,
                                activeColor.withOpacity(0.8),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: activeColor.withOpacity(0.4),
                                blurRadius: 50,
                                spreadRadius: 5,
                                offset: const Offset(0, 15),
                              ),
                              BoxShadow(
                                color: activeColor.withOpacity(0.2),
                                blurRadius: 80,
                                spreadRadius: 10,
                                offset: const Offset(0, 25),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer ring
                              Container(
                                height: 140,
                                width: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                              ),
                              // Icon
                              Icon(
                                activeMood['icon'],
                                size: 80,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 35),

                      // Mood Label Card
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.3),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: Container(
                          key: ValueKey(activeMood['label']),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: activeColor.withOpacity(0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                activeMood['label'],
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: activeColor,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                activeMood['subtitle'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(flex: 2),

                      // Interactive Arc Slider
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: AspectRatio(
                          aspectRatio: 1.6,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return GestureDetector(
                                onPanUpdate: (details) => _handleDrag(
                                  details.localPosition,
                                  constraints.maxWidth,
                                  constraints.maxHeight,
                                ),
                                onTapDown: (details) => _handleDrag(
                                  details.localPosition,
                                  constraints.maxWidth,
                                  constraints.maxHeight,
                                ),
                                child: CustomPaint(
                                  painter: PlusArcPainter(
                                    value: _sliderValue,
                                    moodColors: _moods
                                        .map((m) => m['color'] as Color)
                                        .toList(),
                                  ),
                                  child: Container(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Mood Labels
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMoodLabel("Terrible", _moods[0]['color']),
                            _buildMoodLabel("Okay", _moods[2]['color']),
                            _buildMoodLabel("Amazing", _moods[4]['color']),
                          ],
                        ),
                      ),

                      // Action Buttons Row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(30, 0, 30, 40),
                        child: Row(
                          children: [
                            // Tell Later Button
                            Expanded(
                              flex: 2,
                              child: SizedBox(
                                height: 60,
                                child: OutlinedButton(
                                  onPressed: () async {
                                    HapticFeedback.lightImpact();
                                    final authProvider =
                                        Provider.of<AuthProvider>(context,
                                            listen: false);
                                    await authProvider.deferAssessment();
                                    if (!context.mounted) return;
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const MainScreen()),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: Text(
                                    "Tell Later",
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 15),

                            // Continue Button
                            Expanded(
                              flex: 3,
                              child: SizedBox(
                                height: 60,
                                child: ElevatedButton(
                                  onPressed: () {
                                    HapticFeedback.mediumImpact();
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, anim, secAnim) =>
                                            const ExpressionAnalysisScreen(),
                                        transitionsBuilder:
                                            (context, anim, secAnim, child) {
                                          return FadeTransition(
                                            opacity: Tween<double>(
                                                    begin: 0.0, end: 1.0)
                                                .animate(
                                              CurvedAnimation(
                                                  parent: anim,
                                                  curve: Curves.easeInOut),
                                            ),
                                            child: child,
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
                                      Icon(Icons.arrow_forward_rounded,
                                          size: 22),
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
          )))
        ],
      ),
    );
  }

  Widget _buildMoodLabel(String label, Color color) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color.withOpacity(0.7),
        letterSpacing: 0.3,
      ),
    );
  }

  void _handleDrag(Offset touchPosition, double width, double height) {
    final center = Offset(width / 2, height - 15);
    double dx = touchPosition.dx - center.dx;
    double dy = touchPosition.dy - center.dy;
    double angle = math.atan2(dy, dx);

    if (angle > 0) return;

    double percentage = (angle + math.pi) / math.pi;
    percentage = percentage.clamp(0.0, 1.0);
    _updateMood(percentage);
  }
}

// Plus Arc Painter
class PlusArcPainter extends CustomPainter {
  final double value;
  final List<Color> moodColors;

  PlusArcPainter({required this.value, required this.moodColors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 20);
    final radius = size.width / 2 - 25;
    const strokeWidth = 35.0;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // 1. Background Track with Shadow
    final trackShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawArc(rect, math.pi, math.pi, false, trackShadowPaint);

    final trackPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, math.pi, math.pi, false, trackPaint);

    // 2. Gradient Progress Arc
    final gradient = SweepGradient(
      startAngle: math.pi,
      endAngle: 2 * math.pi,
      colors: moodColors,
      tileMode: TileMode.clamp,
    );

    final activePaint = Paint()
      ..shader =
          gradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(rect, math.pi, math.pi * value, false, activePaint);

    // 3. Plus Knob
    double angle = math.pi + (value * math.pi);
    double knobX = center.dx + radius * math.cos(angle);
    double knobY = center.dy + radius * math.sin(angle);
    Offset knobPos = Offset(knobX, knobY);

    // Dynamic Knob Color
    Color knobColor = Colors.grey;
    double scaled = value * 4;
    int i = scaled.floor().clamp(0, 3);
    double t = scaled - i;
    knobColor = Color.lerp(moodColors[i], moodColors[i + 1], t)!;

    // Outer glow
    canvas.drawCircle(
      knobPos,
      28,
      Paint()
        ..color = knobColor.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
    );

    // Shadow
    canvas.drawCircle(
      knobPos.translate(0, 3),
      22,
      Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // White border
    canvas.drawCircle(knobPos, 22, Paint()..color = Colors.white);

    // Colored center with gradient
    final knobGradient = RadialGradient(
      colors: [
        knobColor,
        knobColor.withOpacity(0.8),
      ],
    );
    canvas.drawCircle(
      knobPos,
      18,
      Paint()
        ..shader = knobGradient
            .createShader(Rect.fromCircle(center: knobPos, radius: 18)),
    );

    // Inner white dot
    canvas.drawCircle(
        knobPos, 6, Paint()..color = Colors.white.withOpacity(0.8));
  }

  @override
  bool shouldRepaint(covariant PlusArcPainter oldDelegate) => true;
}
