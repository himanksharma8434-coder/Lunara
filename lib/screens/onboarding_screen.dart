// lib/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'assessment_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  double _pageValue = 0.0;

  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  // Premium Onboarding Data
  final List<Map<String, String>> _onboardingData = [
    {
      "title": "Welcome to Lunara",
      "desc": "Your personal cycle & wellness companion",
      "bottomText":
          "Track your mood, understand your hormones, and improve your wellbeing - all in one place",
      "localImage": "assets/images/meditating_girl_bg.png"
    },
    {
      "title": "Your Cycle, Simplified",
      "desc": "Your body follows a rhythm. Lunara helps you read it with ease",
      "bottomText":
          "Know exactly when you're ovulating, menstruating, or transitioning through phases - with explanations made simple and supportive",
      "localImage": "assets/images/cycle_tracker.jpg"
    },
    {
      "title": "How Are You Feeling?",
      "desc": "Track emotions and mood swings effortlessly",
      "bottomText":
          "Lunara learns your emotional patterns to support your wellbeing",
      "localImage": "assets/images/balance_wellness.png"
    },
    {
      "title": "Know Your Body Better",
      "desc": "Track periods, pain, cravings & symptoms",
      "bottomText":
          "Get accurate predictions and supportive insights tailored to your cycle",
      "localImage": "assets/images/know_body.jpg"
    },
    {
      "title": "We Support Every Woman's Journey",
      "desc":
          "Whether it's PMS, PCOS, endometriosis, or fibroids - Lunara is here for you",
      "bottomText":
          "Receive compassionate guidance, symptom insights, and tailored recommendations",
      "localImage": "assets/images/support.jpg"
    },
    {
      "title": "Eat What Your Body Needs",
      "desc": "Cycle-based diet tips made for you",
      "bottomText":
          "Balance cravings, boost energy, and support hormones with smart nutrition",
      "localImage": "assets/images/diet.jpg"
    },
    {
      "title": "Move With Your Cycle",
      "desc": "Workouts aligned to your energy levels",
      "bottomText": "Gentle, moderate, or intense — matched to your phase",
      "localImage": "assets/images/cycle.jpg"
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _pageValue = _pageController.page ?? 0.0;
      });
    });

    // Button animation for "pulse" effect
    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
          parent: _buttonAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  void _handleNext() async {
    if (_pageValue.round() == _onboardingData.length - 1) {
      // Save that onboarding is complete
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('seenOnboarding', true);

      if (!mounted) return;

      // Navigate to Assessment with smooth fade
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AssessmentScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _handleSkip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AssessmentScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    bool isTablet = screenWidth > 600;

    // Get current and next page indices for cross-fade
    int currentPage = _pageValue.floor();
    int nextPage = _pageValue.ceil();

    return Scaffold(
      backgroundColor: const Color(0xFF2a2a2a),
      body: Stack(
        children: [
          // BACKGROUND LAYER - Always visible to prevent black flash
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3a3a3a),
                    Color(0xFF1a1a1a),
                  ],
                ),
              ),
            ),
          ),

          // CURRENT PAGE IMAGE
          if (currentPage < _onboardingData.length)
            Positioned.fill(
              child: Opacity(
                opacity: (1 - (_pageValue - currentPage)).clamp(0.0, 1.0),
                child: Image.asset(
                  _onboardingData[currentPage]["localImage"]!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF8989), Color(0xFFD8405B)],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // NEXT PAGE IMAGE (for smooth cross-fade)
          if (nextPage < _onboardingData.length && nextPage != currentPage)
            Positioned.fill(
              child: Opacity(
                opacity: (_pageValue - currentPage).clamp(0.0, 1.0),
                child: Image.asset(
                  _onboardingData[nextPage]["localImage"]!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF8989), Color(0xFFD8405B)],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // GRADIENT OVERLAY - Always on top
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.95),
                  ],
                  stops: const [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // TEXT CONTENT PAGE VIEW
          PageView.builder(
            controller: _pageController,
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) {
              double delta = (index - _pageValue).clamp(-1.0, 1.0);
              double opacity = (1 - delta.abs()).clamp(0.0, 1.0);

              return Stack(
                children: [
                  // CONTENT ONLY
                  SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 60 : 28,
                        vertical: 20,
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: screenHeight * 0.12),

                          // Page Number Indicator
                          Transform.translate(
                            offset: Offset(0, delta * 20),
                            child: Opacity(
                              opacity: opacity,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFFF8989).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  "${index + 1} of ${_onboardingData.length}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.08),

                          // Title with slide animation
                          Transform.translate(
                            offset: Offset(delta * 80, 0),
                            child: Opacity(
                              opacity: opacity,
                              child: Text(
                                _onboardingData[index]["title"]!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isTablet ? 44 : 38,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.1,
                                  letterSpacing: -0.5,
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(0, 4),
                                      blurRadius: 12.0,
                                      color: Colors.black.withOpacity(0.6),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Description with delayed slide
                          Transform.translate(
                            offset: Offset(delta * 120, 0),
                            child: Opacity(
                              opacity: opacity * 0.95,
                              child: Text(
                                _onboardingData[index]["desc"]!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isTablet ? 20 : 18,
                                  color: Colors.white.withOpacity(0.95),
                                  height: 1.5,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Bottom text with fade
                          Transform.translate(
                            offset: Offset(0, delta * 40),
                            child: Opacity(
                              opacity: opacity * 0.9,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.15),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _onboardingData[index]["bottomText"]!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.85),
                                    height: 1.4,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.18),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // SKIP BUTTON (Top Right)
          if (_pageValue.round() != _onboardingData.length - 1)
            SafeArea(
              child: Positioned(
                top: 20,
                right: 20,
                child: TextButton(
                  onPressed: _handleSkip,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.15),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    "Skip",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),

          // BOTTOM CONTROLS
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 60 : 28),
              child: Column(
                children: [
                  // Next/Get Started Button with Pulse Animation
                  ScaleTransition(
                    scale: _pageValue.round() == _onboardingData.length - 1
                        ? _buttonScaleAnimation
                        : const AlwaysStoppedAnimation(1.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _handleNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF3E2723),
                          elevation: 12,
                          shadowColor: Colors.white.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _pageValue.round() == _onboardingData.length - 1
                                  ? "Get Started"
                                  : "Next",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (_pageValue.round() !=
                                _onboardingData.length - 1)
                              const SizedBox(width: 8),
                            if (_pageValue.round() !=
                                _onboardingData.length - 1)
                              const Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Enhanced Page Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingData.length,
                      (index) {
                        bool isActive = index == _pageValue.round();

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutCubic,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: isActive ? 32 : 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.white
                                : Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.4),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : [],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
