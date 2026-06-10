// lib/screens/plus_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/plus_service.dart';
import '../services/razorpay_service.dart';
import '../widgets/custom_toast.dart';

class PlusScreen extends StatefulWidget {
  const PlusScreen({super.key});

  @override
  State<PlusScreen> createState() => _PlusScreenState();
}

class _PlusScreenState extends State<PlusScreen>
    with TickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final AnimationController _pulseController;
  late final AnimationController _floatController;
  bool _isYearly = true;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    RazorpayService.instance.init();
    RazorpayService.instance.setCompletionCallback((success) {
      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          CustomToast.show(context, message: 'Welcome to Lunara Plus! 🎉', icon: Icons.workspace_premium, backgroundColor: const Color(0xFF4CAF50));
        } else {
          CustomToast.show(context, message: 'Payment failed or was cancelled.', icon: Icons.error_outline, backgroundColor: Colors.orange[800]);
        }
      }
    });
  }

  bool _isLoading = false;

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final isPlus = context.watch<PlusService>().isPlus;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0F) : const Color(0xFFFDF8F4),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── HERO HEADER ───
          SliverToBoxAdapter(child: _buildHeroHeader(isDark, isPlus)),

          // ─── PLAN TOGGLE ───
          if (!isPlus)
            SliverToBoxAdapter(child: _buildPlanToggle(isDark)),

          // ─── PRICING CARDS ───
          if (!isPlus)
            SliverToBoxAdapter(child: _buildPricingCards(isDark)),

          // ─── FEATURE COMPARISON ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 12),
              child: Text(
                'Feature Comparison',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF2D1B4E),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildFeatureTable(isDark)),

          // ─── WHY PREMIUM ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 12),
              child: Text(
                'Why Go Plus?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF2D1B4E),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildWhyPlusCards(isDark)),

          // ─── CTA BUTTON ───
          if (!isPlus)
            SliverToBoxAdapter(child: _buildCTAButton(isDark)),

          // ─── ALREADY PREMIUM BADGE ───
          if (isPlus)
            SliverToBoxAdapter(child: _buildAlreadyPlusBadge(isDark)),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  HERO HEADER — Animated gradient + floating crown
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildHeroHeader(bool isDark, bool isPlus) {
    return Stack(
      children: [
        // Background gradient
        Container(
          height: 320,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF1A0A2E),
                      const Color(0xFF2D1B4E),
                      const Color(0xFF44206E),
                    ]
                  : [
                      const Color(0xFFFF8989),
                      const Color(0xFFD8405B),
                      const Color(0xFF9C2D82),
                    ],
            ),
          ),
        ),

        // Decorative circles
        Positioned(
          top: -40,
          right: -30,
          child: AnimatedBuilder(
            animation: _floatController,
            builder: (_, __) {
              final val = _floatController.value;
              return Transform.translate(
                offset: Offset(0, math.sin(val * math.pi) * 8),
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 10,
          left: -50,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.06),
            ),
          ),
        ),

        // Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            child: Column(
              children: [
                // Back button row
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (isPlus)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.amber.withOpacity(0.5), width: 1),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded,
                                color: Colors.amber, size: 14),
                            SizedBox(width: 4),
                            Text('Active',
                                style: TextStyle(
                                    color: Colors.amber,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Animated crown
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) {
                    final scale =
                        1.0 + (_pulseController.value * 0.06);
                    return Transform.scale(
                      scale: scale,
                      child: AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (_, child) {
                          return ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: const [
                                  Colors.amber,
                                  Colors.white,
                                  Colors.amber,
                                ],
                                stops: [
                                  (_shimmerController.value - 0.3)
                                      .clamp(0.0, 1.0),
                                  _shimmerController.value,
                                  (_shimmerController.value + 0.3)
                                      .clamp(0.0, 1.0),
                                ],
                              ).createShader(bounds);
                            },
                            child: child!,
                          );
                        },
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                const Text(
                  'Lunara Plus',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isPlus
                      ? 'You\'re enjoying all Plus benefits ✨'
                      : 'Unlock the full power of your health journey',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.85),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PLAN TOGGLE — Monthly / Yearly
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildPlanToggle(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _toggleTab('Monthly', !_isYearly, isDark, () {
                HapticFeedback.selectionClick();
                setState(() => _isYearly = false);
              }),
              _toggleTab('Yearly', _isYearly, isDark, () {
                HapticFeedback.selectionClick();
                setState(() => _isYearly = true);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggleTab(
      String label, bool isActive, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? const Color(0xFF9C2D82) : const Color(0xFFFF8989))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: (isDark
                            ? const Color(0xFF9C2D82)
                            : const Color(0xFFFF8989))
                        .withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isActive
                    ? Colors.white
                    : (isDark ? Colors.white54 : Colors.black54),
              ),
            ),
            if (label == 'Yearly' && isActive) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'SAVE 40%',
                  style: TextStyle(
                      color: Colors.amber,
                      fontSize: 9,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PRICING CARDS — Free vs Plus side-by-side
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildPricingCards(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          // Free card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.06),
                ),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.grey.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.person_outline_rounded,
                        size: 24,
                        color: isDark ? Colors.white54 : Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Free',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF2D1B4E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹0',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  Text(
                    'forever',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _miniFeature('Basic cycle tracking', true, isDark),
                  _miniFeature('10 AI messages/day', true, isDark),
                  _miniFeature('7-day analytics', true, isDark),
                  _miniFeature('Community support', true, isDark),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Plus card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2D1B4E), Color(0xFF44206E)],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF44206E).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Popular badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Colors.amber, Color(0xFFFFD54F)]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('MOST POPULAR',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2D1B4E))),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.workspace_premium_rounded,
                        size: 24, color: Colors.amber),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isYearly ? 'Plus' : 'Plus',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Builder(
                    builder: (context) {
                      final monthlyPrice = '₹99';
                      final annualPrice = '₹799';
                      
                      return Text(
                        _isYearly ? annualPrice : monthlyPrice,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.amber,
                        ),
                      );
                    }
                  ),
                  Text(
                    _isYearly ? '/year' : '/month',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _miniFeature('Unlimited AI chat', true, true),
                  _miniFeature('90-day analytics', true, true),
                  _miniFeature('AI wellness plans', true, true),
                  _miniFeature('Priority support', true, true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniFeature(String text, bool included, bool darkBg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            included
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            size: 14,
            color: included
                ? (darkBg == true ? Colors.amber : Colors.green)
                : Colors.red.withOpacity(0.5),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: darkBg == true
                    ? Colors.white.withOpacity(0.8)
                    : (AppTheme.isDark(context) ? Colors.white70 : Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  FEATURE COMPARISON TABLE
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildFeatureTable(bool isDark) {
    final features = [
      _FeatureRow('Cycle Tracking', '✓', '✓', Icons.calendar_month_rounded),
      _FeatureRow('Symptom Logging', '✓', '✓', Icons.healing_rounded),
      _FeatureRow('AI Chat Messages', '10/day', 'Unlimited', Icons.chat_bubble_outline_rounded),
      _FeatureRow('AI Models', 'Basic', 'Advanced', Icons.psychology_rounded),
      _FeatureRow('Analytics Range', '7 days', '90 days', Icons.insights_rounded),
      _FeatureRow('AI Wellness Plans', '✗', '✓', Icons.spa_rounded),
      _FeatureRow('AI Predictive Trends', '✗', '✓', Icons.trending_up_rounded),
      _FeatureRow('Personalized Diet Plans', '✗', '✓', Icons.restaurant_rounded),
      _FeatureRow('Priority Support', '✗', '✓', Icons.support_agent_rounded),
      _FeatureRow('SMS Notifications', '✗', '✓', Icons.sms_rounded),
      _FeatureRow('PDF Health Reports', '✗', '✓', Icons.picture_as_pdf_rounded),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.grey.withOpacity(0.04),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 5,
                  child: Text('Feature',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey)),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text('Free',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white54 : Colors.grey[600])),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.amber, Color(0xFFFFD54F)],
                      ).createShader(bounds),
                      child: const Text('Plus',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Feature rows
          ...features.asMap().entries.map((entry) {
            final i = entry.key;
            final f = entry.value;
            return _buildFeatureRow(f, isDark, i == features.length - 1);
          }),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(_FeatureRow f, bool isDark, bool isLast) {
    final isFreeCheck = f.free == '✓';
    final isFreeCross = f.free == '✗';
    final isPremCheck = f.plus == '✓';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.04),
                ),
              ),
      ),
      child: Row(
        children: [
          // Feature icon + label
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Icon(f.icon,
                    size: 16,
                    color: isDark ? Colors.white38 : Colors.grey[400]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    f.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF2D1B4E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Free column
          Expanded(
            flex: 2,
            child: Center(
              child: isFreeCheck
                  ? const Icon(Icons.check_rounded,
                      size: 18, color: Colors.green)
                  : isFreeCross
                      ? Icon(Icons.close_rounded,
                          size: 18,
                          color: Colors.red.withOpacity(0.4))
                      : Text(f.free,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white54 : Colors.grey[600])),
            ),
          ),
          // Plus column
          Expanded(
            flex: 2,
            child: Center(
              child: isPremCheck
                  ? const Icon(Icons.check_circle_rounded,
                      size: 18, color: Colors.amber)
                  : Text(f.plus,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.amber)),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  WHY PREMIUM CARDS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildWhyPlusCards(bool isDark) {
    final items = [
      _WhyItem(
        Icons.auto_awesome_rounded,
        'Smarter AI',
        'Plus unlocks 70B-parameter models for deeper, more accurate health insights.',
        const Color(0xFF7C4DFF),
      ),
      _WhyItem(
        Icons.timeline_rounded,
        '90-Day Trends',
        'See long-term patterns in your cycle, mood, sleep, and symptoms.',
        const Color(0xFF00BFA5),
      ),
      _WhyItem(
        Icons.restaurant_menu_rounded,
        'Personalized Plans',
        'Get AI-crafted nutrition, sleep, and exercise plans tailored to your body.',
        const Color(0xFFFF6D00),
      ),
      _WhyItem(
        Icons.shield_rounded,
        'Priority Support',
        'Your tickets are flagged high-priority with instant SMS and email replies.',
        const Color(0xFFE91E63),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: items.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: item.color.withOpacity(isDark ? 0.2 : 0.1),
              ),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: item.color.withOpacity(0.06),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, size: 22, color: item.color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF2D1B4E),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey[600],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  CTA BUTTON
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildCTAButton(bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: AnimatedBuilder(
        animation: _pulseController,
        builder: (_, __) {
          final glow = 0.2 + _pulseController.value * 0.15;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8989).withOpacity(glow),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _isLoading ? null : () async {
                  HapticFeedback.heavyImpact();
                  setState(() => _isLoading = true);
                  
                  // Razorpay requires amount in smallest currency unit (paise)
                  final amountInPaise = _isYearly ? 79900 : 9900;
                  
                  final success = await RazorpayService.instance.startPayment(
                    amountInPaise: amountInPaise,
                    name: 'Lunara Plus',
                    description: _isYearly ? 'Yearly Subscription' : 'Monthly Subscription',
                    contact: '9999999999', // User's actual phone would go here
                    email: 'test@example.com', // User's actual email
                  );
                  
                  if (!success) {
                    if (mounted) {
                      setState(() => _isLoading = false);
                      CustomToast.show(context, message: 'Unable to open payment gateway.', icon: Icons.error_outline, backgroundColor: Colors.red[400]);
                    }
                  }
                  // Success is handled by Razorpay callbacks initialized in initState
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8989), Color(0xFFD8405B)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isLoading)
                        const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      else ...[
                        const Icon(Icons.workspace_premium_rounded,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Builder(
                          builder: (context) {
                            final monthlyPrice = '₹99';
                            final annualPrice = '₹799';
                            return Text(
                              _isYearly
                                  ? 'Start Plus — $annualPrice/year'
                                  : 'Start Plus — $monthlyPrice/month',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            );
                          }
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
        ),
      // Restore purchases button
      const SizedBox(height: 12),
      Center(
        child: TextButton(
          onPressed: () async {
            setState(() => _isLoading = true);
            await PlusService.instance.init();
            
            if (mounted) {
              setState(() => _isLoading = false);
              final isPlus = Provider.of<PlusService>(context, listen: false).isPlus;
              if (isPlus) {
                CustomToast.show(context, message: 'Purchases restored! 🎉', icon: Icons.check_circle, backgroundColor: const Color(0xFF4CAF50));
              } else {
                CustomToast.show(context, message: 'No active subscription found.', icon: Icons.error_outline, backgroundColor: Colors.orange[800]);
              }
            }
          },
          child: Text(
            'Restore Purchases',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.grey[600],
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  ALREADY PREMIUM BADGE
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildAlreadyPlusBadge(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.amber.withOpacity(0.12),
              Colors.amber.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.verified_rounded,
                  size: 24, color: Colors.amber),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You\'re Plus! 🎉',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF2D1B4E),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Thank you for supporting Lunara. All plus features are active.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.grey[600],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Data models ────────────────────────────────────────────────────

class _FeatureRow {
  final String label;
  final String free;
  final String plus;
  final IconData icon;
  const _FeatureRow(this.label, this.free, this.plus, this.icon);
}

class _WhyItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _WhyItem(this.icon, this.title, this.subtitle, this.color);
}
