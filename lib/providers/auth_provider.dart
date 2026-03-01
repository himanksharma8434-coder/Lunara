import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  final SupabaseClient _supabase = Supabase.instance.client;
  final DatabaseService _db = DatabaseService();

  bool _isLoading = false;
  String _userName = '';
  DateTime? _lastAssessmentDate;
  bool _hasCompletedOnboarding = false;
  bool _assessmentDeferred = false;

  AuthProvider(this._prefs) {
    _loadUserData();
  }

  // ─── GETTERS ──────────────────────────────────────

  bool get isLoggedIn => _supabase.auth.currentSession != null;
  bool get isLoading => _isLoading;
  String get userId => _supabase.auth.currentUser?.id ?? '';
  String get userEmail => _supabase.auth.currentUser?.email ?? '';
  String get userName => _userName;
  DateTime? get lastAssessmentDate => _lastAssessmentDate;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get hasDeferredAssessment => _assessmentDeferred;

  // ─── LOAD LOCAL DATA ──────────────────────────────

  Future<void> _loadUserData() async {
    _userName = _prefs.getString('userName') ?? '';
    _hasCompletedOnboarding = _prefs.getBool('hasCompletedOnboarding') ?? false;
    _assessmentDeferred = _prefs.getBool('assessmentDeferred') ?? false;

    final lastAssessmentString = _prefs.getString('lastAssessmentDate');
    if (lastAssessmentString != null) {
      _lastAssessmentDate = DateTime.parse(lastAssessmentString);
    }

    notifyListeners();
  }

  // ─── SIGN UP ──────────────────────────────────────

  /// Sign up a new user with email and password.
  /// Also creates their profile in the `users` table.
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _setLoading(true);
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name}, // stored in auth.users metadata
      ).timeout(const Duration(seconds: 15));

      if (response.user != null) {
        // Create profile in the `users` table (best-effort)
        try {
          final userModel = UserModel(
            uid: response.user!.id,
            email: email,
            name: name,
          );
          await _db.saveUser(userModel);
        } catch (e) {
          debugPrint('Could not save user profile: $e');
        }

        // Save locally
        _userName = name;
        await _prefs.setString('userName', name);

        _setLoading(false);
        notifyListeners();
        return null; // null = success (no error)
      }

      _setLoading(false);
      return 'Sign up failed. Please try again.';
    } on TimeoutException {
      _setLoading(false);
      return 'Connection timed out. Please check your internet or try again later.';
    } on AuthException catch (e) {
      _setLoading(false);
      return e.message;
    } catch (e) {
      _setLoading(false);
      return 'An unexpected error occurred: $e';
    }
  }

  // ─── LOGIN ────────────────────────────────────────

  /// Log in with email and password.
  Future<String?> login(String email, String password) async {
    _setLoading(true);
    try {
      final response = await _supabase.auth
          .signInWithPassword(
            email: email,
            password: password,
          )
          .timeout(const Duration(seconds: 15));

      if (response.session != null) {
        // Load user name from metadata or database
        final metadata = response.user?.userMetadata;
        _userName = metadata?['name'] ?? '';
        await _prefs.setString('userName', _userName);

        _setLoading(false);
        notifyListeners();
        return null; // success
      }

      _setLoading(false);
      return 'Login failed. Please check your credentials.';
    } on TimeoutException {
      _setLoading(false);
      return 'Connection timed out. Please check your internet or try again later.';
    } on AuthException catch (e) {
      _setLoading(false);
      return e.message;
    } catch (e) {
      _setLoading(false);
      return 'An unexpected error occurred: $e';
    }
  }

  // ─── GOOGLE SIGN IN ───────────────────────────────

  /// Sign in with Google using native flow.
  /// Uses google_sign_in v7 + supabase.auth.signInWithIdToken()
  Future<String?> signInWithGoogle() async {
    _setLoading(true);
    try {
      /// Web Client ID from Google Cloud Console.
      /// This is the Web client ID (NOT Android client ID).
      const webClientId =
          '592495918096-5c03dgfsirnvblllhk3svhuovudpoadc.apps.googleusercontent.com';

      final googleSignIn = GoogleSignIn.instance;

      // Initialize with the Web Client ID
      await googleSignIn.initialize(
        serverClientId: webClientId,
      );

      // Show the Google account picker
      final googleUser = await googleSignIn.authenticate();

      final idToken = googleUser.authentication.idToken;

      if (idToken == null) {
        _setLoading(false);
        return 'No ID token received from Google.';
      }

      // Sign in to Supabase with the Google ID token
      final response = await _supabase.auth
          .signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
          )
          .timeout(const Duration(seconds: 15));

      if (response.session != null) {
        // Get user info from Google
        final name = googleUser.displayName ?? '';
        final email = googleUser.email;

        // Create profile in users table (best-effort — auth still works if table missing)
        try {
          final userModel = UserModel(
            uid: response.user!.id,
            email: email,
            name: name,
          );
          await _db.saveUser(userModel);
        } catch (e) {
          debugPrint('Could not save user profile: $e');
        }

        // Save locally
        _userName = name;
        await _prefs.setString('userName', name);

        _setLoading(false);
        notifyListeners();
        return null; // success
      }

      _setLoading(false);
      return 'Google sign-in failed.';
    } on GoogleSignInException catch (e) {
      _setLoading(false);
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return 'Google sign-in was cancelled.';
      }
      return 'Google sign-in error: ${e.description ?? e.code.name}';
    } on TimeoutException {
      _setLoading(false);
      return 'Connection timed out. Please check your internet or try again later.';
    } on AuthException catch (e) {
      _setLoading(false);
      return e.message;
    } catch (e) {
      _setLoading(false);
      return 'Google sign-in error: $e';
    }
  }

  // ─── FORGOT PASSWORD ─────────────────────────────

  /// Send a password reset email.
  Future<String?> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      _setLoading(false);
      return null; // success
    } on TimeoutException {
      _setLoading(false);
      return 'Connection timed out. Please check your internet or try again later.';
    } on AuthException catch (e) {
      _setLoading(false);
      return e.message;
    } catch (e) {
      _setLoading(false);
      return 'An unexpected error occurred: $e';
    }
  }

  // ─── LOGOUT ───────────────────────────────────────

  Future<void> logout() async {
    await _supabase.auth.signOut();

    _userName = '';
    _lastAssessmentDate = null;
    _hasCompletedOnboarding = false;

    await _prefs.clear();
    notifyListeners();
  }

  // ─── ASSESSMENT HELPERS ───────────────────────────

  bool shouldShowAssessment(bool isOnPeriod) {
    if (!isOnPeriod) return false;
    if (_lastAssessmentDate == null) return true;

    final today = DateTime.now();
    final lastAssessment = _lastAssessmentDate!;

    return today.year != lastAssessment.year ||
        today.month != lastAssessment.month ||
        today.day != lastAssessment.day;
  }

  Future<void> completeAssessment() async {
    _lastAssessmentDate = DateTime.now();
    _assessmentDeferred = false;
    await _prefs.setString(
        'lastAssessmentDate', _lastAssessmentDate!.toIso8601String());
    await _prefs.setBool('assessmentDeferred', false);
    notifyListeners();
  }

  Future<void> deferAssessment() async {
    _assessmentDeferred = true;
    await _prefs.setBool('assessmentDeferred', true);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    await _prefs.setBool('hasCompletedOnboarding', true);
    notifyListeners();
  }

  // ─── HELPERS ──────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
