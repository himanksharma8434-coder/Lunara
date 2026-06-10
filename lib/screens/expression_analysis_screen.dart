// lib/screens/expression_analysis_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'assessment_screen.dart';
import 'sleep_assessment_screen.dart';

class ExpressionAnalysisScreen extends StatefulWidget {
  const ExpressionAnalysisScreen({super.key});

  @override
  State<ExpressionAnalysisScreen> createState() =>
      _ExpressionAnalysisScreenState();
}

class _ExpressionAnalysisScreenState extends State<ExpressionAnalysisScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _charCount = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Entry animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutCubic));

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();

    // Auto-focus with delay for smooth experience
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
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
                    // Plus Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back Button
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pushReplacement(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, anim, secAnim) =>
                                    const AssessmentScreen(),
                                transitionsBuilder:
                                    (context, anim, secAnim, child) {
                                  return FadeTransition(
                                    opacity: Tween<double>(begin: 0.0, end: 1.0)
                                        .animate(
                                      CurvedAnimation(
                                          parent: anim,
                                          curve: Curves.easeInOut),
                                    ),
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(-0.1, 0.0),
                                        end: Offset.zero,
                                      ).animate(CurvedAnimation(
                                          parent: anim, curve: Curves.easeOut)),
                                      child: child,
                                    ),
                                  );
                                },
                                transitionDuration:
                                    const Duration(milliseconds: 400),
                              ),
                            );
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

                        // Title
                        Text(
                          "Assessment",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppTheme.textDark(context),
                            letterSpacing: 0.3,
                          ),
                        ),

                        // Progress Indicator
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
                            "2 OF 7",
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

                    // Title Section with Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: LunaraColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_note_rounded,
                            color: LunaraColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Expression Analysis",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textDark(context),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      "Freely write down anything that's on your mind.\nWe're here to listen...",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppTheme.textLight(context),
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Plus Text Input Card
                    Expanded(
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor(context),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: _focusNode.hasFocus
                                  ? LunaraColors.primary.withOpacity(0.3)
                                  : Colors.grey.shade200,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _focusNode.hasFocus
                                    ? LunaraColors.primary.withOpacity(0.15)
                                    : Colors.black.withOpacity(0.06),
                                blurRadius: _focusNode.hasFocus ? 25 : 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Decorative Header
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      LunaraColors.primary.withOpacity(0.08),
                                      Colors.transparent,
                                    ],
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(28),
                                    topRight: Radius.circular(28),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.psychology_outlined,
                                      color: Colors.grey[400],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "Your thoughts are safe here",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Text Input Area
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 8),
                                  child: TextField(
                                    controller: _controller,
                                    focusNode: _focusNode,
                                    maxLines: null,
                                    maxLength: 500,
                                    onChanged: (val) {
                                      setState(() => _charCount = val.length);
                                      if (val.length % 50 == 0 &&
                                          val.isNotEmpty) {
                                        HapticFeedback.selectionClick();
                                      }
                                    },
                                    decoration: InputDecoration(
                                      hintText: "I feel...",
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade300,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      border: InputBorder.none,
                                      counterText: "",
                                    ),
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: AppTheme.textDark(context),
                                      height: 1.6,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),

                              // Bottom Stats Bar
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 16),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: Colors.grey.shade100,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Word count
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.text_fields_rounded,
                                          size: 16,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "${_controller.text.split(' ').where((word) => word.isNotEmpty).length} words",
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Character count with progress
                                    Row(
                                      children: [
                                        // Progress indicator
                                        SizedBox(
                                          width: 40,
                                          height: 4,
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(2),
                                            child: LinearProgressIndicator(
                                              value: _charCount / 500,
                                              backgroundColor:
                                                  Colors.grey.shade200,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                _charCount > 450
                                                    ? Colors.orange
                                                    : LunaraColors.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "$_charCount/500",
                                          style: TextStyle(
                                            color: _charCount > 450
                                                ? Colors.orange
                                                : Colors.grey[600],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Action Buttons Row
                    Row(
                      children: [
                        // Skip Button
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 60,
                            child: OutlinedButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                _navigateNext();
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
                                "Skip",
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
                                _navigateNext();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: LunaraColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 8,
                                shadowColor:
                                    LunaraColors.primary.withOpacity(0.4),
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
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateNext() {
    FocusScope.of(context).unfocus();

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) => const SleepAssessmentScreen(),
        transitionsBuilder: (context, anim, secAnim, child) {
          return FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeInOut),
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}
