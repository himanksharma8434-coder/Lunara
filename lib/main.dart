import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lunara/services/app_notification_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Your local files
import 'config/app_config.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_screen.dart';
import 'screens/assessment_screen.dart';
import 'package:lunara/providers/auth_provider.dart';
import 'package:lunara/providers/cycle_provider.dart';
import 'package:lunara/providers/theme_provider.dart';
import 'package:lunara/theme/app_theme.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  await AppNotificationService().init();
  final prefs = await SharedPreferences.getInstance();

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  runApp(MyApp(prefs: prefs));
}

// Global helper to access the Supabase client anywhere
final supabase = Supabase.instance.client;

class MyApp extends StatefulWidget {
  final SharedPreferences prefs;
  const MyApp({super.key, required this.prefs});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();

    // Check initial session
    final session = supabase.auth.currentSession;
    _isLoggedIn = session != null;
    _isLoading = false;

    // Listen for future auth state changes (login, logout, token refresh)
    supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      debugPrint('Auth event: $event');

      if (mounted) {
        setState(() {
          if (event == AuthChangeEvent.signedIn ||
              event == AuthChangeEvent.tokenRefreshed) {
            _isLoggedIn = true;
          } else if (event == AuthChangeEvent.signedOut) {
            _isLoggedIn = false;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: AppNotificationService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(widget.prefs)),
        ChangeNotifierProvider(create: (_) => AuthProvider(widget.prefs)),
        ChangeNotifierProvider(create: (_) => CycleProvider(widget.prefs)),
      ],
      child: Builder(
        builder: (context) {
          final themeProvider = context.watch<ThemeProvider>();
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: _isLoading
                ? const SplashScreen()
                : _isLoggedIn
                    ? const InitialRouter()
                    : const LoginScreen(),
          );
        },
      ),
    );
  }
}

class InitialRouter extends StatelessWidget {
  const InitialRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final cycleProvider = context.watch<CycleProvider>();

    if (!authProvider.hasCompletedOnboarding) {
      return const OnboardingScreen();
    }

    if (authProvider.shouldShowAssessment(cycleProvider.isOnPeriod)) {
      return const AssessmentScreen();
    }

    return const MainScreen();
  }
}
