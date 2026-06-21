import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/database_service.dart';
import '../services/cache_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  final SupabaseClient _supabase = Supabase.instance.client;
  final DatabaseService _db = DatabaseService();

  bool _isLoading = true; // Initialize as true for session checking
  bool _isLoggedIn = false;
  String _userName = '';
  String _userAvatarUrl = '';
  DateTime? _lastAssessmentDate;
  bool _hasCompletedOnboarding = false;
  bool _assessmentDeferred = false;
  bool _isPasswordRecovery = false;
  bool _needsNamePrompt = false;
  StreamSubscription<AuthState>? _authSubscription;

  /// Tracks whether the user has explicitly authenticated in this app session
  /// (via login, signup, or Google sign-in). Background token refreshes from
  /// ghost sessions restored by Android Auto Backup will NOT set this flag.
  bool _userDidExplicitLogin = false;

  AuthProvider(this._prefs) {
    _loadUserData();
    _initializeAuthListener();
  }

  void _initializeAuthListener() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final session = data.session;
      debugPrint(
          'AuthProvider: Auth event: $event, session: ${session != null ? "exists" : "null"}, explicitLogin: $_userDidExplicitLogin');

      bool oldIsLoggedIn = _isLoggedIn;

      if (event == AuthChangeEvent.passwordRecovery) {
        _isPasswordRecovery = true;
        _isLoggedIn = true;
        _userDidExplicitLogin = true;
      } else if (event == AuthChangeEvent.initialSession) {
        // initialSession fires once when the SDK boots.
        // If a valid session exists, this is a returning user.
        if (session != null) {
          _isLoggedIn = true;
          _userDidExplicitLogin = true; // Trust the persisted session
          _prefs.setBool('seenOnboarding', true);
          if (!oldIsLoggedIn) {
            _loadUserData();
          }
        } else {
          _isLoggedIn = false;
        }
      } else if (event == AuthChangeEvent.signedIn) {
        // signedIn fires for explicit logins AND sometimes for background
        // token restores. Trust it if the user explicitly logged in, OR
        // if there is a valid session and the user has already seen onboarding.
        if (_userDidExplicitLogin || (session != null && hasSeenOnboarding)) {
          _isLoggedIn = true;
          _userDidExplicitLogin = true;
          if (!oldIsLoggedIn) {
            _loadUserData();
          }
        } else {
          debugPrint(
              'AuthProvider: IGNORING signedIn event — no explicit login yet');
        }
      } else if (event == AuthChangeEvent.tokenRefreshed) {
        // tokenRefreshed fires when Supabase refreshes an existing token
        // in the background. If the user has seen onboarding and we have a valid
        // session, we should trust it and keep/promote them to logged in.
        if (_isLoggedIn || (session != null && hasSeenOnboarding)) {
          _isLoggedIn = true;
          _userDidExplicitLogin = true;
          debugPrint('AuthProvider: tokenRefreshed — OK');
          if (!oldIsLoggedIn) {
            _loadUserData();
          }
        } else {
          debugPrint(
              'AuthProvider: IGNORING tokenRefreshed — user is not logged in');
        }
      } else if (event == AuthChangeEvent.userUpdated) {
        if (_userDidExplicitLogin || (session != null && hasSeenOnboarding)) {
          _isLoggedIn = true;
          _userDidExplicitLogin = true;
        }
      } else if (event == AuthChangeEvent.signedOut ||
          event == AuthChangeEvent.userDeleted) {
        _isLoggedIn = false;
        _isPasswordRecovery = false;
        _userDidExplicitLogin = false;
      }

      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // ─── GETTERS ──────────────────────────────────────

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String get userId => _supabase.auth.currentUser?.id ?? '';
  String get userEmail => _supabase.auth.currentUser?.email ?? '';
  String get userName => _userName;
  String get userAvatarUrl => _userAvatarUrl;
  DateTime? get lastAssessmentDate => _lastAssessmentDate;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get hasSeenOnboarding => _prefs.getBool('seenOnboarding') ?? false;
  bool get hasDeferredAssessment => _assessmentDeferred;
  bool get isPasswordRecovery => _isPasswordRecovery;
  bool get needsNamePrompt => _needsNamePrompt;

  // ─── LOAD LOCAL DATA ──────────────────────────────

  Future<void> _loadUserData() async {
    _userName = _prefs.getString('userName') ?? '';
    _userAvatarUrl = _prefs.getString('userAvatarUrl') ?? '';
    _hasCompletedOnboarding = _prefs.getBool('hasCompletedOnboarding') ?? false;
    _assessmentDeferred = _prefs.getBool('assessmentDeferred') ?? false;

    final lastAssessmentString = _prefs.getString('lastAssessmentDate');
    if (lastAssessmentString != null) {
      _lastAssessmentDate = DateTime.parse(lastAssessmentString);
    }

    // Also try to fetch name from DB if logged in and name is empty
    if (_userName.isEmpty && _supabase.auth.currentUser != null) {
      await _fetchNameFromDatabase();
    }

    notifyListeners();
  }

  /// Fetch the user's name from the database.
  Future<void> _fetchNameFromDatabase() async {
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return;

      final profile = await _db.getUserProfile(uid);
      if (profile != null) {
        if (profile['name'] != null && (profile['name'] as String).isNotEmpty) {
          _userName = profile['name'];
          await _prefs.setString('userName', _userName);
        }
        if (profile['avatar_url'] != null && (profile['avatar_url'] as String).isNotEmpty) {
          _userAvatarUrl = profile['avatar_url'];
          await _prefs.setString('userAvatarUrl', _userAvatarUrl);
        } else {
          // If profile exists but no avatar, try to get it from Google metadata
          final metadata = _supabase.auth.currentUser?.userMetadata;
          final metaAvatar = metadata?['avatar_url'] ?? metadata?['picture'] ?? '';
          if (metaAvatar.isNotEmpty) {
            _userAvatarUrl = metaAvatar;
            await _prefs.setString('userAvatarUrl', _userAvatarUrl);
            try {
              await _supabase.from('users').update({'avatar_url': metaAvatar}).eq('uid', uid);
            } catch (_) {}
          }
        }
        
        // If a profile exists, they have already completed onboarding previously
        _hasCompletedOnboarding = true;
        await _prefs.setBool('seenOnboarding', true);
        await _prefs.setBool('hasCompletedOnboarding', true);
      } else {
        // Try metadata as fallback
        final metadata = _supabase.auth.currentUser?.userMetadata;
        final metaName = metadata?['name'] ?? metadata?['full_name'] ?? '';
        if (metaName.isNotEmpty) {
          _userName = metaName;
          await _prefs.setString('userName', _userName);
        }
        final metaAvatar = metadata?['avatar_url'] ?? metadata?['picture'] ?? '';
        if (metaAvatar.isNotEmpty) {
          _userAvatarUrl = metaAvatar;
          await _prefs.setString('userAvatarUrl', _userAvatarUrl);
        }
      }
    } catch (e) {
      debugPrint('Error fetching name from database: $e');
    }
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
    _userDidExplicitLogin = true;
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
    _userDidExplicitLogin = true;
    try {
      final response = await _supabase.auth
          .signInWithPassword(
            email: email,
            password: password,
          )
          .timeout(const Duration(seconds: 15));

      if (response.session != null) {
        // Load user name from database first, then metadata
        await _fetchNameFromDatabase();
        if (_userName.isEmpty) {
          final metadata = response.user?.userMetadata;
          _userName = metadata?['name'] ?? '';
          if (_userName.isNotEmpty) {
            await _prefs.setString('userName', _userName);
          }
        }

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

  void updateUserAvatar(String newUrl) async {
    _userAvatarUrl = newUrl;
    await _prefs.setString('userAvatarUrl', newUrl);
    notifyListeners();
  }

  // ─── PHONE AUTH (OTP) ─────────────────────────────

  /// Send an OTP to the given phone number.
  Future<String?> signInWithOTP(String phone) async {
    _setLoading(true);
    _userDidExplicitLogin = true;
    try {
      await _supabase.auth.signInWithOtp(
        phone: phone,
      ).timeout(const Duration(seconds: 15));
      
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

  /// Verify the OTP sent to the phone.
  Future<String?> verifyOTP(String phone, String otp) async {
    _setLoading(true);
    _userDidExplicitLogin = true;
    try {
      final response = await _supabase.auth.verifyOTP(
        phone: phone,
        token: otp,
        type: OtpType.sms,
      ).timeout(const Duration(seconds: 15));

      if (response.session != null) {
        // Logged in!
        await _fetchNameFromDatabase();
        if (_userName.isEmpty) {
          final metadata = response.user?.userMetadata;
          _userName = metadata?['name'] ?? '';
          if (_userName.isNotEmpty) {
            await _prefs.setString('userName', _userName);
          }
        }

        // Create profile only if they haven't completed onboarding (i.e. profile doesn't exist)
        if (!hasSeenOnboarding) {
          try {
            final userModel = UserModel(
              uid: response.user!.id,
              email: response.user?.email,
              phone: response.user?.phone ?? phone,
              name: _userName,
            );
            await _db.saveUser(userModel);
          } catch (e) {
             debugPrint('Could not save user profile: $e');
          }
        }

        if (_userName.isEmpty) {
          _needsNamePrompt = true;
        }

        _setLoading(false);
        notifyListeners();
        return null; // success
      }
      _setLoading(false);
      return 'OTP Verification failed.';
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
    _userDidExplicitLogin = true;
    try {
      /// Web Client ID from Google Cloud Console.
      /// This is the Web client ID (NOT Android client ID).
      const webClientId =
          '592495918096-13ov72hqkckc847lhl89328h5g4gdtkc.apps.googleusercontent.com';

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
        final googleName = googleUser.displayName ?? '';
        final email = googleUser.email;
        final googlePhotoUrl = googleUser.photoUrl ?? '';

        // Try to fetch existing name from the database first
        await _fetchNameFromDatabase();

        // If no name in DB, use Google's name
        if (_userName.isEmpty && googleName.isNotEmpty) {
          _userName = googleName;
          await _prefs.setString('userName', _userName);
        }

        // If no avatar in DB, use Google's avatar
        if (_userAvatarUrl.isEmpty && googlePhotoUrl.isNotEmpty) {
          _userAvatarUrl = googlePhotoUrl;
          await _prefs.setString('userAvatarUrl', _userAvatarUrl);
        }

        // Create profile only if they haven't completed onboarding (i.e. profile doesn't exist)
        if (!hasSeenOnboarding) {
          try {
            final userModel = UserModel(
              uid: response.user!.id,
              email: email,
              name: _userName,
              avatarUrl: _userAvatarUrl.isNotEmpty ? _userAvatarUrl : null,
            );
            await _db.saveUser(userModel);
          } catch (e) {
            debugPrint('Could not save user profile: $e');
          }
        } else {
          // Just update the name/avatar if they were empty but we found them from Google
          final updates = <String, dynamic>{};
          if (_userName.isEmpty && googleName.isNotEmpty) {
            updates['name'] = googleName;
          }
          if (_userAvatarUrl.isEmpty && googlePhotoUrl.isNotEmpty) {
            updates['avatar_url'] = googlePhotoUrl;
          }
          
          if (updates.isNotEmpty) {
            try {
              await _supabase.from('users').update(updates).eq('uid', response.user!.id);
            } catch (_) {}
          }
        }

        // If still no name after Google + DB, prompt the user
        if (_userName.isEmpty) {
          _needsNamePrompt = true;
        }

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
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.lunara://login-callback/',
      );
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

  /// Update the user's password (used after password recovery).
  Future<String?> updatePassword(String newPassword) async {
    _setLoading(true);
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      _isPasswordRecovery = false;
      _setLoading(false);
      notifyListeners();
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

  /// Clear the password recovery flag (e.g. after navigating away).
  void clearPasswordRecovery() {
    _isPasswordRecovery = false;
    notifyListeners();
  }

  // ─── NAME PROMPT ──────────────────────────────────

  /// Set the user's name (called from the name prompt dialog).
  /// Saves to local prefs and to the database.
  Future<void> setUserName(String name) async {
    _userName = name;
    _needsNamePrompt = false;
    await _prefs.setString('userName', name);

    final uid = _supabase.auth.currentUser?.id;
    if (uid != null) {
      try {
        await _supabase.from('users').update({'name': name}).eq('uid', uid);
        await CacheService.instance.clearCache('api_cache_user_profile_$uid');
      } catch (e) {
        debugPrint('Could not save user name to database: $e');
      }
    }

    notifyListeners();
  }

  // ─── LOGOUT ───────────────────────────────────────

  Future<void> logout() async {
    await _supabase.auth.signOut();

    _userName = '';
    _lastAssessmentDate = null;
    _hasCompletedOnboarding = false;
    _needsNamePrompt = false;

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

  /// Mark onboarding slides as seen (pre-login, device-local).
  /// If the user completes onboarding, we must guarantee they are taken
  /// to the Login page. If there's a phantom session lingering, we forcefully
  /// clear it locally so it doesn't try to log them back in automatically.
  Future<void> markOnboardingSeen() async {
    debugPrint('🔵 markOnboardingSeen: START');
    await _prefs.setBool('seenOnboarding', true);

    if (_supabase.auth.currentSession != null) {
      debugPrint(
          '🔵 markOnboardingSeen: Ghost session detected. Wiping it locally.');
      try {
        // SignOutScope.local guarantees the local token is destroyed without
        // making a network request that could throw a "JWT expired" exception.
        await _supabase.auth.signOut(scope: SignOutScope.local);
      } catch (e) {
        debugPrint('🔵 markOnboardingSeen: Error local signOut: $e');
      }
    }

    _isLoggedIn = false;
    notifyListeners();
  }

  // ─── HELPERS ──────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// FOR TESTING ONLY: Completely wipes app state so onboarding shows again
  Future<void> testWipeAppState() async {
    await _prefs.clear();
    if (_supabase.auth.currentSession != null) {
      try {
        await _supabase.auth.signOut();
      } catch (e) {
        debugPrint('🔵 testWipeAppState: signOut error (ignoring): $e');
      }
    }
    _isLoggedIn = false;
    _hasCompletedOnboarding = false;
    _assessmentDeferred = false;
    notifyListeners();
  }
}
