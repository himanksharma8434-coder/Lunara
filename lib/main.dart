import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lunara/services/app_notification_service.dart';
import 'package:lunara/services/health_service.dart';
import 'package:lunara/services/logger_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lunara/services/plus_service.dart';
import 'package:lunara/services/saved_posts_service.dart';
import 'package:lunara/services/patch_service.dart';

// local files
import 'config/app_config.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_screen.dart';
import 'screens/assessment_screen.dart';
import 'screens/reset_password_screen.dart';
import 'widgets/pink_loading_animation.dart';
import 'package:lunara/providers/auth_provider.dart';
import 'package:lunara/providers/cycle_provider.dart';
import 'package:lunara/providers/theme_provider.dart';
import 'package:lunara/theme/app_theme.dart';

// Pillar 1: Ghost Mode (Local-First Privacy)
import 'package:lunara/services/database/hive_service.dart';
import 'package:lunara/features/privacy/presentation/providers/privacy_provider.dart';
import 'package:lunara/features/privacy/presentation/screens/lock_screen.dart';

void main() {
  final log = LoggerService.instance;

  // Catch all uncaught asynchronous errors
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Catch Flutter framework errors (e.g. build/layout/paint failures)
    FlutterError.onError = (details) {
      log.error(
        'Flutter framework error',
        error: details.exception,
        stackTrace: details.stack,
        tag: 'FlutterError',
      );
      // Forward to the default handler so red-screen still shows in debug
      FlutterError.presentError(details);
    };

    final prefs = await SharedPreferences.getInstance();
    await SavedPostsService.instance.init();

    // Load environment variables
    await dotenv.load(fileName: ".env");

    // Initialize Supabase
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );

    // Initialize notifications (requires Supabase to be initialized)
    try {
      // Wait for initialization so the logo test and listeners are properly set up
      await AppNotificationService().init();
      AppNotificationService().scheduleDailyGuidance();
    } catch (e, st) {
      log.error('Notification Service Startup Failed (non-fatal)',
          error: e, stackTrace: st, tag: 'Notifications');
    }

    // Initialize real-time listeners for notifications
    AppNotificationService().setupRealtimeListener();

    // Pillar 1: Initialize encrypted local database (Ghost Mode)
    try {
      await HiveService.instance.init();
      log.info('Encrypted Hive database initialized', tag: 'GhostMode');
    } catch (e, st) {
      log.error('Hive init error (non-fatal)',
          error: e, stackTrace: st, tag: 'GhostMode');
    }

    // Initialize health service (silent config) in the background
    try {
      final healthService = HealthService();
      healthService.configure(); // Fire and forget
      log.info('Health service configured', tag: 'Health');
    } catch (e, st) {
      log.error('Health startup config error (non-fatal)',
          error: e, stackTrace: st, tag: 'Health');
    }

    // Initialize PatchService for Shorebird updates
    await PatchService.instance.init();

    // Initialize Plus Service (reads cached status + cloud sync)
    await PlusService.instance.init();

    runApp(MyApp(prefs: prefs));
  }, (error, stack) {
    log.error('Uncaught async error',
        error: error, stackTrace: stack, tag: 'Zone');
  });
}

// Global helper to access the Supabase client anywhere
final supabase = Supabase.instance.client;

class MyApp extends StatefulWidget {
  final SharedPreferences prefs;
  const MyApp({super.key, required this.prefs});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final PrivacyProvider _privacyProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _privacyProvider = PrivacyProvider();

    // Initialize privacy provider after Hive is ready
    if (HiveService.instance.isInitialized) {
      _privacyProvider.initialize();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Ghost Mode auto-lock: lock when backgrounded, check timeout on resume
    if (state == AppLifecycleState.paused) {
      _privacyProvider.lock();
    } else if (state == AppLifecycleState.resumed) {
      _privacyProvider.onAppLifecycleChanged(true);
      
      // If the app was left open overnight, ensure daily metrics (sleep, water) reset
      if (mounted) {
        try {
          Provider.of<CycleProvider>(context, listen: false).checkNewDay();
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: AppNotificationService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(widget.prefs)),
        ChangeNotifierProvider(create: (_) => AuthProvider(widget.prefs)),
        ChangeNotifierProvider(create: (_) => CycleProvider(widget.prefs)),
        ChangeNotifierProvider.value(value: PlusService.instance),
        ChangeNotifierProvider.value(value: _privacyProvider),
        ChangeNotifierProvider.value(value: PatchService.instance),
      ],
      child: Builder(
        builder: (context) {
          final authProvider = context.watch<AuthProvider>();
          final themeProvider = context.watch<ThemeProvider>();
          final privacyProvider = context.watch<PrivacyProvider>();
          final seenOnboarding = authProvider.hasSeenOnboarding;
          final isLoggedIn = authProvider.isLoggedIn;
          final isLoading = authProvider.isLoading;

          debugPrint('[MainRouter] loading=$isLoading onboarding=$seenOnboarding loggedIn=$isLoggedIn recovery=${authProvider.isPasswordRecovery} ghost=${privacyProvider.ghostModeEnabled} locked=${privacyProvider.shouldShowLockScreen}');

          // Ghost Mode Lock Gate: intercept ALL routes when locked
          if (privacyProvider.shouldShowLockScreen) {
            return MaterialApp(
              key: const ValueKey('lock'),
              debugShowCheckedModeBanner: false,
              themeMode: themeProvider.themeMode,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              home: const LockScreen(),
              builder: _buildGlobalOverlay,
            );
          }

          // Determine which screen to show
          final String routeKey;
          final Widget homeScreen;

          if (isLoading) {
            routeKey = 'splash';
            homeScreen = const SplashScreen();
          } else if (authProvider.isPasswordRecovery) {
            routeKey = 'reset_password';
            homeScreen = const ResetPasswordScreen();
          } else if (!seenOnboarding) {
            routeKey = 'onboarding';
            homeScreen = const OnboardingScreen();
          } else if (isLoggedIn) {
            routeKey = 'initial_router';
            homeScreen = const InitialRouter();
          } else {
            routeKey = 'login';
            homeScreen = const LoginScreen();
          }

          debugPrint('🎯 ROUTING TO: $routeKey');

          return MaterialApp(
            key: ValueKey(routeKey),
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: homeScreen,
            builder: _buildGlobalOverlay,
          );
        },
      ),
    );
  }

  Widget _buildGlobalOverlay(BuildContext context, Widget? child) {
    final patchService = context.watch<PatchService>();

    return Stack(
      children: [
        if (child != null) child,
        if (patchService.isUpdateReadyToInstall)
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: LunaraColors.primary.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: LunaraColors.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.system_update, color: LunaraColors.primary),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'An update is ready — restart to apply',
                        style: TextStyle(
                          color: LunaraColors.textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // In a real app we might gracefully restart or exit,
                        // but usually just exiting the app works or user kills it.
                        // For a gentle approach, we just provide the instruction
                        // since we can't reliably force-restart a Flutter app cross-platform nicely.
                      },
                      child: const Text('Restart now', style: TextStyle(color: LunaraColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class InitialRouter extends StatefulWidget {
  const InitialRouter({super.key});

  @override
  State<InitialRouter> createState() => _InitialRouterState();
}

class _InitialRouterState extends State<InitialRouter> {
  bool _dialogShown = false;
  bool _cloudLoadTriggered = false;
  bool _loading = true;
  bool _showOverlay = true;
  bool _hasShownMainScreen = false;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Trigger a cloud restore the first time we land on this screen after
    // a fresh login (SharedPreferences were wiped by uninstall/reinstall).
    if (!_cloudLoadTriggered) {
      _cloudLoadTriggered = true;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.hasCompletedOnboarding) {
        // Wait for cloud data before showing the UI to prevent sudden state jumps
      }
      _loadData();
    }
  }

  Future<void> _loadData() async {
    try {
      // Run the cloud load and a minimum timer simultaneously
      await Future.wait([
        Provider.of<CycleProvider>(context, listen: false)
            .loadFromCloud()
            .timeout(const Duration(seconds: 10)),
        Future.delayed(const Duration(milliseconds: 3000)), // Minimum splash duration
      ]);
    } catch (e) {
      debugPrint('Error loading cloud data (proceeding anyway): $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[InitialRouter] building');
    final authProvider = context.watch<AuthProvider>();
    final cycleProvider = context.watch<CycleProvider>();

    // Determine the underlying screen (only instantiated after loading finishes)
    Widget? baseScreen;
    if (!_loading) {
      if (!_hasShownMainScreen && authProvider.shouldShowAssessment(cycleProvider.isOnPeriod)) {
        baseScreen = const AssessmentScreen();
      } else {
        baseScreen = const MainScreen();
      }
    }

    // Show name prompt dialog if needed (after loading and frame builds)
    if (!_loading && authProvider.needsNamePrompt && !_dialogShown) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNamePromptDialog(context);
      });
    }

    // Lock main screen choice
    if (!_loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasShownMainScreen) {
          setState(() {
            _hasShownMainScreen = true;
          });
        }
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: Stack(
        children: [
          // Base Screen renders underneath the loading overlay
          if (baseScreen != null) baseScreen,

          // Loading Overlay Transition
          if (_showOverlay)
            Positioned.fill(
              child: PinkLoadingAnimation(
                isLoading: _loading,
                onAnimationComplete: () {
                  if (mounted) {
                    setState(() {
                      _showOverlay = false;
                    });
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showNamePromptDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('👋 ', style: TextStyle(fontSize: 24)),
            Text(
              'Welcome!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: LunaraColors.textDark,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "What should we call you?",
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Enter your name',
                prefixIcon: const Icon(Icons.person_outline,
                    color: LunaraColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide:
                      const BorderSide(color: LunaraColors.primary, width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                await Provider.of<AuthProvider>(ctx, listen: false)
                    .setUserName(name);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: LunaraColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
