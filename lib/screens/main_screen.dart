// lib/screens/main_screen.dart - ENHANCED INTERACTIVE VERSION

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import 'ai_chat_screen.dart';
import 'appointment_screen.dart';
import 'community_screen.dart';
import 'profile_screen.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../providers/cycle_provider.dart';
import 'tabs/home_tab.dart';
import '../services/app_notification_service.dart';
import '../widgets/custom_toast.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _breathingController;
  late AnimationController _entryController;
  late AnimationController _fabController;
  StreamSubscription<String>? _actionSubscription;

  @override
  void initState() {
    super.initState();
    // Request all permissions after a short delay to ensure Activity is ready
    Future.delayed(const Duration(milliseconds: 500), _requestAllPermissions);

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _entryController.forward();

    // Listen for notification action taps
    _actionSubscription = AppNotificationService().actionStream.stream.listen((action) {
      if (!mounted) return;
      final provider = Provider.of<CycleProvider>(context, listen: false);
      
      if (action == 'action_period_started') {
        provider.confirmPeriodStarted();
        CustomToast.show(
          context,
          message: "Period start logged successfully!",
          icon: Icons.check_circle,
          backgroundColor: Colors.green.shade600,
        );
      } else if (action == 'action_not_yet') {
        provider.dismissPeriodConfirmation();
        CustomToast.show(
          context,
          message: "Noted! Lunara's intelligence will adjust your predictions.",
          icon: Icons.auto_awesome,
          backgroundColor: const Color(0xFF6C63FF),
          duration: const Duration(seconds: 4),
        );
      }
    });
  }

  Future<void> _requestAllPermissions() async {
    try {
      // 1. Notification permission (Android 13+)
      await AppNotificationService().requestPermissions();
    } catch (_) {}

    try {
      // 2. Location permission (for nearby doctors)
      final locationEnabled = await Geolocator.isLocationServiceEnabled();
      if (locationEnabled) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _actionSubscription?.cancel();
    _breathingController.dispose();
    _entryController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.background(context),
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          HomeTab(),
          AppointmentScreen(),
          CommunityScreen(),
          ProfileScreen(),
        ],
      ),
      floatingActionButton: _buildEnhancedFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildModernBottomBar(),
    );
  }

  Widget _buildEnhancedFAB() {
    return GestureDetector(
      onTapDown: (_) {
        _fabController.forward();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        _fabController.reverse();
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const AIChatScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                    CurvedAnimation(
                        parent: animation, curve: Curves.easeOutBack),
                  ),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      },
      onTapCancel: () => _fabController.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_breathingController, _fabController]),
        builder: (context, child) {
          final scale = 1.0 - (_fabController.value * 0.1);
          final glowIntensity = 0.3 + (_breathingController.value * 0.2);

          return Transform.scale(
            scale: scale,
            child: Container(
              width: 64,
              height: 64,
              margin: const EdgeInsets.only(top: 30),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient(context),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary(context).withOpacity(glowIntensity),
                    blurRadius: 20 + (_breathingController.value * 10),
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated pulse ring
                  Container(
                    width: 64 + (_breathingController.value * 10),
                    height: 64 + (_breathingController.value * 10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(
                            0.3 * (1 - _breathingController.value)),
                        width: 2,
                      ),
                    ),
                  ),
                  // Icon
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                  // AI Badge
                  Positioned(
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.5), width: 1),
                      ),
                      child: const Text(
                        'AI',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
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
        },
      ),
    );
  }

  Widget _buildModernBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: AppTheme.softShadow(context),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BottomAppBar(
          height: 83,
          color: AppTheme.cardColor(context),
          elevation: 0,
          notchMargin: 8,
          shape: const CircularNotchedRectangle(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 0),
              _buildNavItem(Icons.local_hospital_rounded, 1),
              const SizedBox(width: 48),
              _buildNavItem(Icons.people_rounded, 2),
              _buildNavItem(Icons.person_rounded, 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _selectedIndex = index);
        },
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 1.0 + (value * 0.15),
                    child: Container(
                      padding: EdgeInsets.all(10 + (value * 3)),
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          Colors.transparent,
                          AppTheme.primary(context).withOpacity(0.15),
                          value,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: Color.lerp(
                          Colors.grey[400],
                          AppTheme.primary(context),
                          value,
                        ),
                        size: 24,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
                builder: (context, value, child) {
                  return Container(
                    width: 4 + (value * 16),
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.lerp(Colors.transparent,
                              AppTheme.primary(context), value)!,
                          Color.lerp(Colors.transparent,
                              Theme.of(context).colorScheme.secondary, value)!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
