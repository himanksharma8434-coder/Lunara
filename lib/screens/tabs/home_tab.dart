import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:ui';
import '../../providers/cycle_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../symptom_log_screen.dart';
import '../ai_chat_screen.dart';
import '../note_screen.dart';
import '../insights_screen.dart';
import '../wellness_plan_screen.dart';
import '../plus_screen.dart';
import '../assessment_screen.dart';
import '../bbt_log_screen.dart';
import '../../widgets/animations.dart';
import '../../widgets/custom_toast.dart';
import '../../widgets/wellness_forecast_timeline.dart';
import '../../models/prediction_result.dart';
import '../../services/plus_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/database_service.dart';
import '../notifications_screen.dart';

// HOME TAB - ENHANCED
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _scrollController;
  final GlobalKey _irregularButtonKey = GlobalKey();
  bool _hasNewNotifications = false;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _scrollController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scrollController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNotifications();
    });
  }

  Future<void> _checkNotifications() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;
    if (userId.isEmpty) return;

    try {
      final dbService = DatabaseService();
      final replies = await dbService.getRepliesToUserPosts(userId);
      if (replies.isEmpty) {
        if (mounted) {
          setState(() {
            _hasNewNotifications = false;
          });
        }
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final lastViewStr = prefs.getString('last_notifications_view_time');
      if (lastViewStr == null) {
        if (mounted) {
          setState(() {
            _hasNewNotifications = true;
          });
        }
        return;
      }

      final lastView = DateTime.parse(lastViewStr);
      final hasNew = replies.any((r) {
        final createdAt = DateTime.tryParse(r['created_at'] ?? '') ?? DateTime.now();
        return createdAt.isAfter(lastView);
      });

      if (mounted) {
        setState(() {
          _hasNewNotifications = hasNew;
        });
      }
    } catch (e) {
      debugPrint('Error checking notifications in home: $e');
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Plays the plus irregular-toggle animation:
  /// 1. Glowing orb with particle trail rises from the button to the top header.
  /// 2. Glassmorphism info card drops in explaining what Lunara Intelligence adapts.
  void _showIrregularAnimation(CycleProvider provider) {
    final renderBox =
        _irregularButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final buttonPos = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;
    final overlay = Overlay.of(context);
    final screenSize = MediaQuery.of(context).size;
    final willBeIrregular = !provider.isIrregular;

    // Toggle the value first
    provider.setIsIrregular(willBeIrregular);
    HapticFeedback.mediumImpact();

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (_) => _IrregularAnimationOverlay(
        startOffset: Offset(
          buttonPos.dx + buttonSize.width / 2,
          buttonPos.dy + buttonSize.height / 2,
        ),
        screenSize: screenSize,
        isIrregular: willBeIrregular,
        onDismiss: () => overlayEntry.remove(),
      ),
    );
    overlay.insert(overlayEntry);
  }

  void _showSetNameDialog(BuildContext context, CycleProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppTheme.cardColor(context),
        title: Text(
          'What should we call you?',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: TextStyle(color: AppTheme.textLight(context)),
            filled: true,
            fillColor: Theme.of(context).scaffoldBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textLight(context)),
            ),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                provider.setUserName(name);
                Navigator.pop(ctx);
              }
            },
            child: Text(
              'Save',
              style: TextStyle(
                color: AppTheme.primary(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CycleProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = context.select<CycleProvider, String>((p) => p.userName);
    final dynamicGreeting = context.select<CycleProvider, String>((p) => p.dynamicGreeting);
    final isOnPeriod = context.select<CycleProvider, bool>((p) => p.isOnPeriod);
    final shouldShowPeriodConfirmation = context.select<CycleProvider, bool>((p) => p.shouldShowPeriodConfirmation);
    final predictiveInsight = context.select<CycleProvider, String?>((p) => p.predictiveInsight);
    final currentPredictions = context.select<CycleProvider, List<String>>((p) => p.currentPredictions);
    final forecasts = context.select<CycleProvider, List<WellnessForecast>>((p) => p.latestPrediction.wellnessForecasts);
    final isPlus = context.watch<PlusService>().isPlus;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final showDeferredBanner = authProvider.hasDeferredAssessment &&
        isOnPeriod &&
        authProvider.shouldShowAssessment(isOnPeriod);

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.backgroundGradient(context),
      ),
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Enhanced Header with animation
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _scrollController,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.2),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _scrollController,
                    curve: Curves.easeOutCubic,
                  )),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [
                                    AppTheme.textDark(context),
                                    AppTheme.primary(context)
                                  ],
                                ).createShader(bounds),
                                child: Text(
                                  'Hello, ${userName.isEmpty ? 'There' : userName.split(' ')[0]}',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 14,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      dynamicGreeting,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textLight(context),
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationsScreen(),
                              ),
                            ).then((_) {
                              _checkNotifications();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.cardColor(context).withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary(context)
                                      .withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Icon(
                                  Icons.notifications_none_rounded,
                                  color: textColor,
                                  size: 22,
                                ),
                                if (_hasNewNotifications)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        gradient:
                                            AppTheme.primaryGradient(context),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.primary(context)
                                                .withOpacity(0.5),
                                            blurRadius: 4,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Complete Profile Banner (name missing)
            if (userName.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _showSetNameDialog(context, provider);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: AppTheme.isDark(context)
                              ? [const Color(0xFF1A2740), const Color(0xFF1E3A5F)]
                              : [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF42A5F5).withOpacity(0.4),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF42A5F5).withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor(context),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF42A5F5).withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person_add_alt_1_rounded,
                              color: Color(0xFF42A5F5),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Complete your profile',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tap to add your name',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textLight(context),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppTheme.textLight(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Deferred Assessment Banner
            if (showDeferredBanner)
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AssessmentScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: AppTheme.isDark(context)
                              ? [const Color(0xFF3E2723), const Color(0xFF4E342E)]
                              : [const Color(0xFFFFF3E0), const Color(0xFFFFE0B2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: LunaraColors.warning.withOpacity(0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF9800).withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor(context),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFFF9800).withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.assignment_late_rounded,
                              color: Color(0xFFFF9800),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Daily Assessment Pending',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tap to log how you\'re feeling today',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        AppTheme.textLight(context),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFF9800),
                                  Color(0xFFF57C00),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFFF9800).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Log Now',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Period Confirmation Banner
            if (shouldShowPeriodConfirmation)
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppTheme.isDark(context)
                            ? [const Color(0xFF2A1525), AppTheme.primary(context).withOpacity(0.15)]
                            : [const Color(0xFFF3E5F5), LunaraColors.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: LunaraColors.lutealPurple.withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF9C27B0).withOpacity(0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.cardColor(context),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF9C27B0)
                                        .withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.calendar_today_rounded,
                                color: Color(0xFF9C27B0),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Did your period start?',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Your period is expected around now',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textLight(context),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  provider.confirmPeriodStarted();
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        LunaraColors.primaryDark,
                                        LunaraColors.primary,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: LunaraColors.primaryDark
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Yes, it started',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  provider.dismissPeriodConfirmation();
                                  CustomToast.show(
                                    context,
                                    message: 'Noted! Lunara\'s intelligence will adjust your predictions.',
                                    icon: Icons.auto_awesome_rounded,
                                    backgroundColor: LunaraColors.primaryDark,
                                    duration: const Duration(seconds: 4),
                                  );
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardColor(context),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: LunaraColors.lutealPurple
                                          .withOpacity(0.5),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Not yet',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // "Correct Date" link
                        Center(
                          child: GestureDetector(
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  final isDark = Theme.of(context).brightness == Brightness.dark;
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: isDark
                                          ? ColorScheme.dark(
                                              primary: AppTheme.primary(context),
                                              onPrimary: Colors.white,
                                              surface: const Color(0xFF1E1E1E),
                                              onSurface: Colors.white,
                                            )
                                          : ColorScheme.light(
                                              primary: AppTheme.primary(context),
                                              onPrimary: Colors.white,
                                              surface: Colors.white,
                                              onSurface: const Color(0xFF3E2723),
                                            ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                provider.updateLastPeriodDate(picked);
                                if (context.mounted) {
                                  CustomToast.show(
                                    context,
                                    message: 'Period date updated! Predictions recalculated.',
                                    icon: Icons.check_circle_rounded,
                                    backgroundColor: const Color(0xFF06D6A0),
                                  );
                                }
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit_calendar_rounded,
                                    size: 14,
                                    color: LunaraColors.lutealPurple.withOpacity(0.8),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'It started on a different day',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: LunaraColors.lutealPurple.withOpacity(0.8),
                                      decoration: TextDecoration.underline,
                                      decorationColor: LunaraColors.lutealPurple.withOpacity(0.4),
                                    ),
                                  ),
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

            // AI Predictive Insight Card
            if (predictiveInsight != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          LunaraColors.primary.withOpacity(0.15),
                          LunaraColors.primaryDark.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: LunaraColors.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor(context),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: LunaraColors.primary.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.insights_rounded,
                            color: LunaraColors.primaryDark,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Predictive Insight',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                predictiveInsight,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textLight(context),
                                  height: 1.4,
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

            // Enhanced Cycle Ring
            SliverToBoxAdapter(
              child: CycleRingWidget(
                breathingAnimation: _breathingController,
                onTap: () => _showEnhancedDetails(context, provider),
              ),
            ),

            // Animated Phase Legend
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _buildEnhancedLegend('Menstrual', LunaraColors.primaryLight,
                        Icons.water_drop_rounded),
                    _buildEnhancedLegend('Follicular', const Color(0xFFFFCCBC),
                        Icons.eco_rounded),
                    _buildEnhancedLegend('Ovulation', const Color(0xFFE1BEE7),
                        Icons.spa_rounded),
                    _buildEnhancedLegend('Luteal', const Color(0xFFB39DDB),
                        Icons.nightlight_round),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Enhanced Quick Stats & Quick Log Action
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: StatsRowWidget(
                  onShowEditStatDialog: (statName) => _showEditStatDialog(context, provider, statName),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Enhanced Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            LunaraColors.primary,
                            LunaraColors.primaryDark
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            LunaraColors.primary,
                            LunaraColors.primaryDark
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            if (currentPredictions.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: PredictionsWidget(
                    predictions: currentPredictions,
                    onLogSymptom: (symptom) {
                      provider.addSymptom(symptom);
                      CustomToast.show(
                        context,
                        message: '$symptom logged for today',
                        icon: Icons.health_and_safety_rounded,
                        backgroundColor: AppTheme.primary(context),
                        duration: const Duration(seconds: 2),
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
            ],

            // Plus AI Cards with animation
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: PlusAICard(
                        text: 'Diet Plan',
                        icon: Icons.restaurant_menu_rounded,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF81C784),
                            Color(0xFF66BB6A)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        prompt: 'I need a personalized diet plan based on my menstrual cycle phase.',
                        delay: 0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PlusAICard(
                        text: 'Workout',
                        icon: Icons.fitness_center_rounded,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF8989),
                            Color(0xFFD8405B)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        prompt: 'I need a workout routine suitable for my current cycle phase.',
                        delay: 100,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Insights Card
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: InsightsCardWidget(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // AI Wellness Plan Card
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: WellnessPlanCardWidget(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // FAM / Clinical Tracking Card
            const SliverToBoxAdapter(
              child: FamTrackingWidget(),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Chronological Wellness Forecast Timeline
            SliverToBoxAdapter(
              child: WellnessForecastTimeline(
                forecasts: forecasts,
                isPlus: isPlus,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Regular Actions with hover effect
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: RegularActionsRowWidget(),
              ),
            ),

            // ─── Plus Upgrade Banner ───
            if (!PlusService.instance.isPlus)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: PlusUpgradeBannerWidget(),
                ),
              ),

            // Bottom spacing for nav bar
// Irregular Period Section - Plus Design
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              sliver: SliverToBoxAdapter(
                child: IrregularPeriodWidget(
                  irregularButtonKey: _irregularButtonKey,
                  onToggleIrregular: () => _showIrregularAnimation(provider),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedLegend(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context).withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textDark(context),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }




  void _showEnhancedDetails(BuildContext context, CycleProvider provider) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [LunaraColors.primary, LunaraColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [LunaraColors.primary, LunaraColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: LunaraColors.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_rounded, color: Colors.white, size: 26),
                  SizedBox(width: 12),
                  Text(
                    'Cycle Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _buildDetailRow('Current Phase', provider.currentPhase,
                LunaraColors.primary, Icons.spa_rounded),
            _buildDetailRow(
                'Cycle Day',
                '${provider.currentCycleDay}/${provider.cycleLength}',
                LunaraColors.ovulationBlue,
                Icons.calendar_today_rounded),
            _buildDetailRow(
                'Days Until Period',
                '${provider.daysUntilNextPeriod}',
                LunaraColors.warning,
                Icons.schedule_rounded),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: LunaraColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      String label, String value, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.secondaryText(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditStatDialog(
      BuildContext context, CycleProvider provider, String statName) {
    HapticFeedback.mediumImpact();
    final controller = TextEditingController(
        text: statName == 'Sleep'
            ? (provider.sleepHours > 0 ? provider.sleepHours.toString() : '')
            : (provider.dailySteps > 0 ? provider.dailySteps.toString() : ''));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Update $statName',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              hintText: statName == 'Sleep' ? 'e.g. 7.5' : 'e.g. 5000',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppTheme.inputFillColor(context),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                final val = double.tryParse(controller.text);
                if (val != null) {
                  if (statName == 'Sleep') {
                    provider.updateSleep(val);
                  } else if (statName == 'Steps') {
                    provider.updateSteps(val.toInt());
                  }
                }
                Navigator.pop(context);
                HapticFeedback.lightImpact();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary(context),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

}

// ENHANCED CYCLE RING PAINTER - STATIC BACKGROUND
class StaticBackgroundRingPainter extends CustomPainter {
  final double progress;

  StaticBackgroundRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 15;

    // Phase colors with gradients
    final colors = [
      LunaraColors.primaryLight,
      const Color(0xFFFFCCBC),
      const Color(0xFFE1BEE7),
      const Color(0xFFB39DDB),
    ];

    // Draw background rings with glow
    for (int i = 0; i < 4; i++) {
      // Main ring background
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2 + (i * math.pi / 2),
        math.pi / 2,
        false,
        paint,
      );
    }

    // Main progress line
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [LunaraColors.primary, LunaraColors.primaryDark],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(StaticBackgroundRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ENHANCED CYCLE RING PAINTER - ANIMATED FOREGROUND
class AnimatedForegroundRingPainter extends CustomPainter {
  final double progress;
  final double breathAnimation;

  AnimatedForegroundRingPainter(
      {required this.progress, required this.breathAnimation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 15;

    // Progress indicator with animated glow effect
    final progressGlowPaint = Paint()
      ..color = LunaraColors.primary.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12 + (breathAnimation * 3)
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressGlowPaint,
    );

    // Note: The marker has been moved to a Flutter Widget layer (Container + Transform)
    // to allow for high-quality box shadows and gradients without repainting the canvas on every frame.
  }

  @override
  bool shouldRepaint(AnimatedForegroundRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.breathAnimation != breathAnimation;
}

// ═══════════════════════════════════════════════════════════════════
//  IRREGULAR ANIMATION OVERLAY
//  A plus orb-rise + info card animation for irregular toggle.
// ═══════════════════════════════════════════════════════════════════

class _IrregularAnimationOverlay extends StatefulWidget {
  final Offset startOffset;
  final Size screenSize;
  final bool isIrregular;
  final VoidCallback onDismiss;

  const _IrregularAnimationOverlay({
    required this.startOffset,
    required this.screenSize,
    required this.isIrregular,
    required this.onDismiss,
  });

  @override
  State<_IrregularAnimationOverlay> createState() =>
      _IrregularAnimationOverlayState();
}

class _IrregularAnimationOverlayState
    extends State<_IrregularAnimationOverlay> with TickerProviderStateMixin {
  late AnimationController _orbController;
  late AnimationController _cardController;
  late AnimationController _bgController;
  late AnimationController _pulseController;

  late Animation<double> _orbProgress;
  late Animation<double> _orbScale;
  late Animation<double> _cardSlide;
  late Animation<double> _cardOpacity;
  late Animation<double> _bgOpacity;
  late List<Animation<double>> _pointOpacities;

  // Trail particles state
  final List<_TrailParticle> _trailParticles = [];
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();

    // Phase 1: Orb rises from button to top (800ms)
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _orbProgress = CurvedAnimation(
      parent: _orbController,
      curve: Curves.easeInOutCubic,
    );
    _orbScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.8), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.8, end: 0.0), weight: 10),
    ]).animate(_orbController);

    // Phase 2: Info card slides up
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _cardSlide = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutBack,
    );
    _cardOpacity = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOut,
    );

    // Staggered fade animations for the info card's points
    _pointOpacities = List.generate(3, (index) {
      final start = 0.3 + index * 0.2;
      final end = (start + 0.4).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _cardController,
        curve: Interval(start, end, curve: Curves.easeOut),
      );
    });

    // Background dim
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bgOpacity = CurvedAnimation(
      parent: _bgController,
      curve: Curves.easeOut,
    );

    // Pulse glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _orbController.addListener(() {
      // Generate trail particles during the orb's journey
      if (_orbController.value > 0.05 && _orbController.value < 0.85) {
        _generateTrailParticle();
      }
      setState(() {});
    });

    _startSequence();
  }

  void _generateTrailParticle() {
    final endY = 80.0;
    final currentX = widget.startOffset.dx +
        (_rng.nextDouble() - 0.5) *
            30 *
            math.sin(_orbProgress.value * math.pi);
    final currentY = widget.startOffset.dy +
        (endY - widget.startOffset.dy) * _orbProgress.value;

    _trailParticles.add(_TrailParticle(
      x: currentX + (_rng.nextDouble() - 0.5) * 20,
      y: currentY + (_rng.nextDouble() - 0.5) * 20,
      radius: 2 + _rng.nextDouble() * 4,
      opacity: 0.6 + _rng.nextDouble() * 0.4,
      createdAt: _orbController.value,
    ));

    // Remove old particles
    _trailParticles
        .removeWhere((p) => _orbController.value - p.createdAt > 0.25);
  }

  Future<void> _startSequence() async {
    _bgController.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _orbController.forward();
    await Future.delayed(const Duration(milliseconds: 700));
    HapticFeedback.lightImpact();
    _cardController.forward();
  }

  Future<void> _dismiss() async {
    await _bgController.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _orbController.dispose();
    _cardController.dispose();
    _bgController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orbColor = widget.isIrregular
        ? const Color(0xFFFF8566)
        : const Color(0xFF7C4DFF);
    final endY = 80.0;

    // Calculate orb position along a curved path
    final orbX = widget.startOffset.dx +
        math.sin(_orbProgress.value * math.pi) *
            (widget.screenSize.width / 2 - widget.startOffset.dx) *
            0.3;
    final orbY =
        widget.startOffset.dy + (endY - widget.startOffset.dy) * _orbProgress.value;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _dismiss,
        child: AnimatedBuilder(
          animation:
              Listenable.merge([_bgOpacity, _orbController, _cardController, _pulseController]),
          builder: (context, _) {
            return Stack(
              children: [
                // Dimmed background
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.4 * _bgOpacity.value),
                  ),
                ),

                // Trail particles
                ..._trailParticles.map((p) {
                  final age = (_orbController.value - p.createdAt).clamp(0.0, 0.25);
                  final fadeout = 1.0 - (age / 0.25);
                  return Positioned(
                    left: p.x - p.radius,
                    top: p.y - p.radius,
                    child: Opacity(
                      opacity: p.opacity * fadeout,
                      child: Container(
                        width: p.radius * 2,
                        height: p.radius * 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: orbColor.withOpacity(0.6),
                          boxShadow: [
                            BoxShadow(
                              color: orbColor.withOpacity(0.3 * fadeout),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                // Main orb
                if (_orbScale.value > 0)
                  Positioned(
                    left: orbX - 18,
                    top: orbY - 18,
                    child: Transform.scale(
                      scale: _orbScale.value,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white,
                              orbColor,
                              orbColor.withOpacity(0.0),
                            ],
                            stops: const [0.0, 0.4, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: orbColor.withOpacity(
                                  0.6 + 0.3 * math.sin(_pulseController.value * math.pi)),
                              blurRadius: 30 + 10 * _pulseController.value,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Info card (after orb arrives)
                Positioned(
                  left: 24,
                  right: 24,
                  top: 100 + (1 - _cardSlide.value) * 60,
                  child: Opacity(
                    opacity: _cardOpacity.value,
                    child: _buildInfoCard(context, orbColor),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, Color accentColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final title = widget.isIrregular
        ? '🌀  Lunara Intelligence Activated'
        : '✨  Lunara Intelligence Updated';

    final subtitle = widget.isIrregular
        ? 'Your cycle has been marked as irregular'
        : 'Your cycle has been marked as regular';

    final List<_IntelligencePoint> points = widget.isIrregular
        ? [
            _IntelligencePoint(
              icon: Icons.trending_up_rounded,
              title: 'Wider Prediction Windows',
              desc: 'Predictions will account for variability — showing ranges instead of exact dates.',
            ),
            _IntelligencePoint(
              icon: Icons.psychology_rounded,
              title: 'Adaptive Learning',
              desc: 'Lunara will learn your unique pattern over 3–6 cycles to improve accuracy.',
            ),
            _IntelligencePoint(
              icon: Icons.notifications_active_rounded,
              title: 'Smarter Reminders',
              desc: 'Notifications will be sent earlier to prepare you for a wider window.',
            ),
          ]
        : [
            _IntelligencePoint(
              icon: Icons.calendar_today_rounded,
              title: 'Precise Predictions',
              desc: 'Predictions will follow a steady cycle length pattern.',
            ),
            _IntelligencePoint(
              icon: Icons.auto_awesome_rounded,
              title: 'Optimized Tracking',
              desc: 'Insights and tips are tuned for a consistent cycle rhythm.',
            ),
          ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: accentColor.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.15),
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withOpacity(0.2),
                      accentColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: accentColor.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: Icon(
                  widget.isIrregular
                      ? Icons.auto_fix_high_rounded
                      : Icons.check_circle_outline_rounded,
                  color: accentColor,
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? Colors.white.withOpacity(0.6)
                      : Colors.black54,
                ),
              ),
              const SizedBox(height: 24),

              // Intelligence points
              ...List.generate(points.length, (index) {
                final point = points[index];
                final anim = index < _pointOpacities.length
                    ? _pointOpacities[index]
                    : _cardOpacity;
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.15),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: anim,
                      curve: Curves.easeOutCubic,
                    )),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              point.icon,
                              color: accentColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  point.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  point.desc,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white.withOpacity(0.5)
                                        : Colors.black45,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 8),
              Text(
                'Tap anywhere to dismiss',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? Colors.white.withOpacity(0.3)
                      : Colors.black26,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrailParticle {
  final double x;
  final double y;
  final double radius;
  final double opacity;
  final double createdAt;

  _TrailParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.opacity,
    required this.createdAt,
  });
}

class _IntelligencePoint {
  final IconData icon;
  final String title;
  final String desc;

  _IntelligencePoint({
    required this.icon,
    required this.title,
    required this.desc,
  });
}


// ═══════════════════════════════════════════════════════════════════
//  CUSTOM OPTIMIZED WIDGETS
// ═══════════════════════════════════════════════════════════════════

class CycleRingWidget extends StatelessWidget {
  final Animation<double> breathingAnimation;
  final VoidCallback onTap;

  const CycleRingWidget({
    super.key,
    required this.breathingAnimation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentCycleDay = context.select<CycleProvider, int>((p) => p.currentCycleDay);
    final cycleLength = context.select<CycleProvider, int>((p) => p.cycleLength);
    final currentPhase = context.select<CycleProvider, String>((p) => p.currentPhase);

    return CycleRingCard(
      currentCycleDay: currentCycleDay,
      cycleLength: cycleLength,
      currentPhase: currentPhase,
      breathingAnimation: breathingAnimation,
      onTap: onTap,
    );
  }
}

class CycleRingCard extends StatelessWidget {
  final int currentCycleDay;
  final int cycleLength;
  final String currentPhase;
  final Animation<double> breathingAnimation;
  final VoidCallback onTap;

  const CycleRingCard({
    super.key,
    required this.currentCycleDay,
    required this.cycleLength,
    required this.currentPhase,
    required this.breathingAnimation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Container(
          height: 250,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context).withOpacity(0.35),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppTheme.cardColor(context).withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: AnimatedBuilder(
            animation: breathingAnimation,
            child: Stack(
              alignment: Alignment.center,
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    size: const Size(200, 200),
                    painter: StaticBackgroundRingPainter(
                      progress: currentCycleDay / cycleLength,
                    ),
                  ),
                ),
                // Center info
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.cardColor(context).withOpacity(0.8),
                    border: Border.all(
                      color: AppTheme.cardColor(context).withOpacity(0.6),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              LunaraColors.primary,
                              LunaraColors.primaryDark
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          currentPhase.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                const LinearGradient(
                              colors: [
                                LunaraColors.textDark,
                                LunaraColors.primary
                              ],
                            ).createShader(bounds),
                            child: Text(
                              '$currentCycleDay',
                              style: const TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                          ),
                          Text(
                            '/$cycleLength',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.secondaryText(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'cycle days',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.secondaryText(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            builder: (context, child) {
              // Calculate marker position mathematically
              final progress = currentCycleDay / cycleLength;
              final angle = -math.pi / 2 + (2 * math.pi * progress);
              // Radius matches the painter's radius: (200 / 2) - 15 = 85
              final radiusX = 85 * math.cos(angle);
              final radiusY = 85 * math.sin(angle);

              return Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Plus background breathing glow (Restored RadialGradient)
                  // Wrapped in Transform.scale so it doesn't repaint!
                  Transform.scale(
                    scale: 1.0 + (breathingAnimation.value * 0.06),
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            LunaraColors.primary.withOpacity(0.15),
                            LunaraColors.primary.withOpacity(0.0),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  
                  // 2. Ring Stack
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Static background ring and center text
                        child!,
                        
                        // Animated foreground arc (Simple arc, no expensive shadows here)
                        RepaintBoundary(
                          child: CustomPaint(
                            size: const Size(200, 200),
                            painter: AnimatedForegroundRingPainter(
                              progress: progress,
                              breathAnimation: breathingAnimation.value,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Plus Glowing Marker (Restored shadows and gradients)
                  // Translated and scaled via GPU compositor, zero repaint cost!
                  Transform.translate(
                    offset: Offset(radiusX, radiusY),
                    child: Transform.scale(
                      scale: 1.0 + (breathingAnimation.value * 0.2),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: LunaraColors.primary,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: LunaraColors.primary.withOpacity(0.6),
                              blurRadius: 12,
                              spreadRadius: 4,
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.8),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class StatsRowWidget extends StatelessWidget {
  final Function(String) onShowEditStatDialog;

  const StatsRowWidget({
    super.key,
    required this.onShowEditStatDialog,
  });

  @override
  Widget build(BuildContext context) {
    final sleepHours = context.select<CycleProvider, double>((p) => p.sleepHours);
    final waterGlasses = context.select<CycleProvider, int>((p) => p.waterGlasses);
    final dailySteps = context.select<CycleProvider, int>((p) => p.dailySteps);
    final provider = Provider.of<CycleProvider>(context, listen: false);

    return Row(
      children: [
        Expanded(
          child: InteractiveStat(
            label: 'Sleep',
            icon: Icons.nightlight_rounded,
            color: const Color(0xFFB39DDB),
            value: '${sleepHours}h',
            delay: 0,
            onTap: () => onShowEditStatDialog('Sleep'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InteractiveStat(
            label: 'Water',
            icon: Icons.water_drop_rounded,
            color: LunaraColors.ovulationBlue,
            value: '$waterGlasses',
            delay: 50,
            onTap: () {
              HapticFeedback.lightImpact();
              provider.incrementWater();
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InteractiveStat(
            label: 'Steps',
            icon: Icons.directions_walk_rounded,
            color: LunaraColors.fertileGreen,
            value: '$dailySteps',
            delay: 100,
            onTap: () => onShowEditStatDialog('Steps'),
          ),
        ),
      ],
    );
  }
}

class InteractiveStat extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String value;
  final int delay;
  final VoidCallback? onTap;

  const InteractiveStat({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
    required this.delay,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutBack,
      tween: Tween(begin: 0.0, end: 1.0),
      child: GestureDetector(
        onTapDown: (_) => HapticFeedback.lightImpact(),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context).withOpacity(0.4),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withOpacity(0.25), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.2),
                        color.withOpacity(0.1)
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.secondaryText(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      builder: (context, animation, child) {
        return Transform.scale(
          scale: animation,
          child: child,
        );
      },
    );
  }
}

class PlusAICard extends StatelessWidget {
  final String text;
  final IconData icon;
  final Gradient gradient;
  final String prompt;
  final int delay;

  const PlusAICard({
    super.key,
    required this.text,
    required this.icon,
    required this.gradient,
    required this.prompt,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutBack,
      tween: Tween(begin: 0.0, end: 1.0),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AIChatScreen(initialPrompt: prompt),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.35),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Icon(icon, size: 30, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.auto_awesome_rounded,
                        size: 13, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'AI Powered',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      builder: (context, animation, child) {
        return Transform.scale(
          scale: animation,
          child: child,
        );
      },
    );
  }
}

class PredictionsWidget extends StatelessWidget {
  final List<String> predictions;
  final Function(String) onLogSymptom;

  const PredictionsWidget({
    super.key,
    required this.predictions,
    required this.onLogSymptom,
  });

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primary(context).withOpacity(0.12),
              AppTheme.cardColor(context).withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primary(context).withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: AppTheme.softShadow(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: AppTheme.primary(context),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  "Today's Predictions",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark(context),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "Based on your past cycles, you might experience:",
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textLight(context),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: predictions.map((symptom) {
                return ActionChip(
                  backgroundColor:
                      AppTheme.primaryGradient(context).colors.first,
                  side: BorderSide.none,
                  labelStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_circle,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text("Log $symptom"),
                    ],
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onLogSymptom(symptom);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class InsightsCardWidget extends StatelessWidget {
  const InsightsCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cycleOwnerName = context.select<CycleProvider, String>((p) => p.cycleOwnerName);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const InsightsScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 350),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              LunaraColors.textDark.withOpacity(0.85),
              const Color(0xFF5D4037).withOpacity(0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: LunaraColors.textDark.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.insights_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$cycleOwnerName Insights',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Charts, trends & cycle patterns',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
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

class WellnessPlanCardWidget extends StatelessWidget {
  const WellnessPlanCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const WellnessPlanScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 350),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6C63FF).withOpacity(0.85),
              const Color(0xFF5B52CC).withOpacity(0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.health_and_safety_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'AI Wellness Plan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Personalized nutrition, sleep & stress plans',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }
}

class FamTrackingWidget extends StatelessWidget {
  const FamTrackingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final confidence = context.select<CycleProvider, OvulationConfidence>((p) => p.ovulationConfidence);

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (confidence) {
      case OvulationConfidence.confirmed:
        statusColor = LunaraColors.fertileGreen;
        statusText = 'Ovulation Confirmed';
        statusIcon = Icons.verified_rounded;
        break;
      case OvulationConfidence.probable:
        statusColor = LunaraColors.ovulationBlue;
        statusText = 'Ovulation Probable';
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case OvulationConfidence.unconfirmed:
        statusColor = AppTheme.textLight(context);
        statusText = 'Ovulation Unconfirmed';
        statusIcon = Icons.help_outline_rounded;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BbtLogScreen()),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context).withOpacity(0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: statusColor.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: AppTheme.softShadow(context),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.device_thermostat_rounded,
                    color: statusColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'FAM Tracking',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textLight(context),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(statusIcon, size: 14, color: statusColor),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Log BBT & Mucus for medical-grade precision',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLight(context),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.add_rounded, color: statusColor, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegularActionsRowWidget extends StatelessWidget {
  const RegularActionsRowWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final symptomPromptName = context.select<CycleProvider, String>((p) => p.symptomPromptName);

    return Row(
      children: [
        Expanded(
          child: ModernActionCard(
            text: symptomPromptName,
            icon: Icons.edit_note_rounded,
            bgColor: LunaraColors.primaryLight,
            accentColor: LunaraColors.primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SymptomLogScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ModernActionCard(
            text: 'Add Note',
            icon: Icons.note_add_rounded,
            bgColor: const Color(0xFFE1BEE7),
            accentColor: const Color(0xFFB39DDB),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const NoteScreen()),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ModernActionCard extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color bgColor;
  final Color accentColor;
  final VoidCallback onTap;

  const ModernActionCard({
    super.key,
    required this.text,
    required this.icon,
    required this.bgColor,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBg = isDark ? accentColor.withOpacity(0.12) : bgColor;
    final effectiveTextColor = isDark ? accentColor : const Color(0xFF2D2D2D);
    final iconBgColor = isDark
        ? accentColor.withOpacity(0.2)
        : AppTheme.cardColor(context).withOpacity(0.85);

    return AnimatedPressableCard(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
          decoration: BoxDecoration(
            color: effectiveBg.withOpacity(isDark ? 0.3 : 0.5),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? accentColor.withOpacity(0.2)
                  : accentColor.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(isDark ? 0.05 : 0.1),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: accentColor),
              ),
              const SizedBox(height: 10),
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: effectiveTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlusUpgradeBannerWidget extends StatelessWidget {
  const PlusUpgradeBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlusScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2D1B4E).withOpacity(0.85),
              const Color(0xFF44206E).withOpacity(0.85)
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF44206E).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.amber,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upgrade to Plus',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Unlock unlimited AI, 90-day trends & more',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.white.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class IrregularPeriodWidget extends StatelessWidget {
  final GlobalKey irregularButtonKey;
  final VoidCallback onToggleIrregular;

  const IrregularPeriodWidget({
    super.key,
    required this.irregularButtonKey,
    required this.onToggleIrregular,
  });

  @override
  Widget build(BuildContext context) {
    final isIrregular = context.select<CycleProvider, bool>((p) => p.isIrregular);

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isIrregular
                ? const Color(0xFFFF8566).withOpacity(0.08)
                : AppTheme.subtleBackground(context).withOpacity(0.4),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isIrregular
                  ? const Color(0xFFFF8566).withOpacity(0.25)
                  : AppTheme.primary(context).withOpacity(0.15),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 400),
                    tween: Tween<double>(
                      begin: isIrregular ? 0.0 : 1.0,
                      end: isIrregular ? 1.0 : 0.0,
                    ),
                    builder: (context, value, child) {
                      final color = Color.lerp(
                        AppTheme.primary(context),
                        const Color(0xFFFF8566),
                        value,
                      )!;
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            isIrregular
                                ? Icons.event_busy_rounded
                                : Icons.event_available_rounded,
                            key: ValueKey<bool>(isIrregular),
                            color: color,
                            size: 26,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          child: Text(
                            isIrregular
                                ? 'Period is Irregular'
                                : 'Period is Regular',
                            key: ValueKey<bool>(isIrregular),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textDark(context),
                            ),
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          child: Text(
                            isIrregular
                                ? 'Predictions are adjusted for variability'
                                : 'Predictions follow a steady pattern',
                            key: ValueKey<bool>(isIrregular),
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textLight(context),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                key: irregularButtonKey,
                width: double.infinity,
                height: 56,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 400),
                  tween: Tween<double>(
                    begin: isIrregular ? 0.0 : 1.0,
                    end: isIrregular ? 1.0 : 0.0,
                  ),
                  builder: (context, value, child) {
                    final color = Color.lerp(
                      AppTheme.primary(context),
                      const Color(0xFFFF8566),
                      value,
                    )!;
                    return ElevatedButton(
                      onPressed: onToggleIrregular,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: child,
                    );
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: Text(
                      isIrregular
                          ? 'Mark as Regular'
                          : 'Mark as Irregular',
                      key: ValueKey<bool>(isIrregular),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'This helps Lunara adapt to your body',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textLight(context).withOpacity(0.7),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
