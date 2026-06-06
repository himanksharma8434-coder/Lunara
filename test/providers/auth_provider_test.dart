import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lunara/providers/auth_provider.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockUser extends Mock implements User {}
class MockSession extends Mock implements Session {}

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;
  late StreamController<AuthState> authStateController;

  setUpAll(() async {
    registerFallbackValue(AuthChangeEvent.initialSession);
    
    // Ensure WidgetsBinding is initialized
    TestWidgetsFlutterBinding.ensureInitialized();

    // Set initial mock values for SharedPreferences so Supabase.initialize doesn't fail
    SharedPreferences.setMockInitialValues({});

    // Initialize Supabase instance once
    await Supabase.initialize(
      url: 'https://placeholder.supabase.co',
      anonKey: 'placeholder-anon-key',
    );
  });

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();
    authStateController = StreamController<AuthState>.broadcast();

    when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
    when(() => mockGoTrueClient.onAuthStateChange).thenAnswer((_) => authStateController.stream);

    // Override the client on the Supabase singleton instance
    Supabase.instance.client = mockSupabaseClient;
  });

  tearDown(() {
    authStateController.close();
  });

  group('AuthProvider Persistent Session Restoration', () {
    test('Should trust signedIn event and log in user if hasSeenOnboarding is true', () async {
      SharedPreferences.setMockInitialValues({
        'seenOnboarding': true,
        'userName': 'Jane Doe',
      });
      final prefs = await SharedPreferences.getInstance();

      final mockSession = MockSession();
      final mockUser = MockUser();
      when(() => mockSession.user).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn('user123');
      when(() => mockUser.email).thenReturn('jane@example.com');
      when(() => mockUser.userMetadata).thenReturn({'name': 'Jane Doe'});
      when(() => mockGoTrueClient.currentUser).thenReturn(mockUser);
      when(() => mockGoTrueClient.currentSession).thenReturn(mockSession);

      final authProvider = AuthProvider(prefs);

      // Verify initial state is loading
      expect(authProvider.isLoading, true);
      expect(authProvider.isLoggedIn, false);

      // Emit signedIn event with session (e.g. background session restored/refreshed)
      authStateController.add(AuthState(AuthChangeEvent.signedIn, mockSession));

      // Wait for the stream listener to process the event
      await Future.delayed(Duration.zero);

      expect(authProvider.isLoading, false);
      expect(authProvider.isLoggedIn, true);
      expect(authProvider.userId, 'user123');
    });

    test('Should trust tokenRefreshed event and log in user if hasSeenOnboarding is true', () async {
      SharedPreferences.setMockInitialValues({
        'seenOnboarding': true,
      });
      final prefs = await SharedPreferences.getInstance();

      final mockSession = MockSession();
      final mockUser = MockUser();
      when(() => mockSession.user).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn('user123');
      when(() => mockUser.email).thenReturn('jane@example.com');
      when(() => mockGoTrueClient.currentUser).thenReturn(mockUser);
      when(() => mockGoTrueClient.currentSession).thenReturn(mockSession);

      final authProvider = AuthProvider(prefs);

      // Emit tokenRefreshed event with session (e.g. background token refreshed)
      authStateController.add(AuthState(AuthChangeEvent.tokenRefreshed, mockSession));

      await Future.delayed(Duration.zero);

      expect(authProvider.isLoggedIn, true);
    });

    test('Should IGNORE signedIn event if hasSeenOnboarding is false', () async {
      SharedPreferences.setMockInitialValues({
        'seenOnboarding': false,
      });
      final prefs = await SharedPreferences.getInstance();

      final mockSession = MockSession();
      final mockUser = MockUser();
      when(() => mockSession.user).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn('user123');
      when(() => mockGoTrueClient.currentUser).thenReturn(mockUser);

      final authProvider = AuthProvider(prefs);

      // Emit signedIn event
      authStateController.add(AuthState(AuthChangeEvent.signedIn, mockSession));

      await Future.delayed(Duration.zero);

      expect(authProvider.isLoggedIn, false);
    });
  });
}
