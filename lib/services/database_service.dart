import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class DatabaseService {
  final SupabaseClient _db = Supabase.instance.client;

  // ─── USER PROFILE ──────────────────────────────────

  /// Create or update the full user profile (upsert).
  Future<void> saveUserProfile({
    required String uid,
    required String email,
    String name = '',
    int cycleLength = 28,
    int periodDuration = 5,
    int age = 0,
    int weight = 60,
    int height = 165,
    bool trackingForOthers = false,
    String trackedPersonName = '',
    String trackedPersonRelation = 'Partner',
  }) async {
    try {
      await _db.from('users').upsert({
        'uid': uid,
        'email': email,
        'name': name,
        'cycle_length': cycleLength,
        'period_duration': periodDuration,
        'age': age,
        'weight': weight,
        'height': height,
        'tracking_for_others': trackingForOthers,
        'tracked_person_name': trackedPersonName,
        'tracked_person_relation': trackedPersonRelation,
      });
    } catch (e) {
      debugPrint('Cloud sync error (saveUserProfile): $e');
    }
  }

  /// Create or update user profile (upsert) — legacy method.
  Future<void> saveUser(UserModel user) async {
    try {
      await _db.from('users').upsert(user.toMap());
    } catch (e) {
      debugPrint('Cloud sync error (saveUser): $e');
    }
  }

  /// Get user data as a one-time fetch.
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final response =
          await _db.from('users').select().eq('uid', uid).maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Cloud fetch error (getUserProfile): $e');
      return null;
    }
  }

  /// Get user data as UserModel.
  Future<UserModel?> getUser(String uid) async {
    try {
      final response =
          await _db.from('users').select().eq('uid', uid).maybeSingle();
      if (response != null) {
        return UserModel.fromMap(response);
      }
    } catch (e) {
      debugPrint('Cloud fetch error (getUser): $e');
    }
    return null;
  }

  /// Listen to user data in real-time.
  Stream<UserModel?> getUserStream(String uid) {
    return _db
        .from('users')
        .stream(primaryKey: ['uid'])
        .eq('uid', uid)
        .map((data) {
          if (data.isNotEmpty) {
            return UserModel.fromMap(data.first);
          }
          return null;
        });
  }

  // ─── CYCLES ────────────────────────────────────────

  /// Upsert a cycle record (avoids duplicates by user_id + start_date).
  Future<void> upsertCycle({
    required String userId,
    required DateTime startDate,
    DateTime? endDate,
    int? cycleLength,
  }) async {
    try {
      await _db.from('cycles').upsert(
        {
          'user_id': userId,
          'start_date': startDate.toIso8601String().split('T')[0],
          'end_date': endDate?.toIso8601String().split('T')[0],
          'cycle_length': cycleLength,
          'status': 'completed',
        },
        onConflict: 'user_id, start_date',
      );
    } catch (e) {
      debugPrint('Cloud sync error (upsertCycle): $e');
    }
  }

  /// Sync a batch of cycle start dates at once.
  Future<void> syncCycleHistory({
    required String userId,
    required List<DateTime> cycleStartDates,
  }) async {
    try {
      final rows = cycleStartDates.map((d) => {
        'user_id': userId,
        'start_date': d.toIso8601String().split('T')[0],
        'status': 'completed',
      }).toList();

      await _db.from('cycles').upsert(
        rows,
        onConflict: 'user_id, start_date',
      );
    } catch (e) {
      debugPrint('Cloud sync error (syncCycleHistory): $e');
    }
  }

  /// Get all cycles for a user, sorted newest first.
  Future<List<Map<String, dynamic>>> getCycles(String userId) async {
    try {
      final response = await _db
          .from('cycles')
          .select()
          .eq('user_id', userId)
          .order('start_date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Cloud fetch error (getCycles): $e');
      return [];
    }
  }

  /// Log a new cycle period.
  Future<void> addCycle(String userId, Map<String, dynamic> data) async {
    try {
      data['user_id'] = userId;
      await _db.from('cycles').insert(data);
    } catch (e) {
      debugPrint('Cloud sync error (addCycle): $e');
    }
  }

  /// Update a cycle record.
  Future<void> updateCycle(int id, Map<String, dynamic> data) async {
    try {
      await _db.from('cycles').update(data).eq('id', id);
    } catch (e) {
      debugPrint('Cloud sync error (updateCycle): $e');
    }
  }

  // ─── ASSESSMENTS ───────────────────────────────────

  /// Upsert a daily assessment (avoids duplicates by user_id + date).
  Future<void> upsertAssessment({
    required String userId,
    required DateTime date,
    String? mood,
    List<String>? symptoms,
    int waterIntake = 0,
    double sleepHours = 0,
    int steps = 0,
  }) async {
    try {
      await _db.from('assessments').upsert(
        {
          'user_id': userId,
          'date': date.toIso8601String().split('T')[0],
          'mood': mood,
          'symptoms': symptoms ?? [],
          'water_intake': waterIntake,
          'sleep_hours': sleepHours,
          'steps': steps,
        },
        onConflict: 'user_id, date',
      );
    } catch (e) {
      debugPrint('Cloud sync error (upsertAssessment): $e');
    }
  }

  /// Get assessment history for a user.
  Future<List<Map<String, dynamic>>> getAssessments(String userId) async {
    try {
      final response = await _db
          .from('assessments')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Cloud fetch error (getAssessments): $e');
      return [];
    }
  }

  /// Save a daily assessment (legacy insert).
  Future<void> addAssessment(String userId, Map<String, dynamic> data) async {
    try {
      data['user_id'] = userId;
      await _db.from('assessments').insert(data);
    } catch (e) {
      debugPrint('Cloud sync error (addAssessment): $e');
    }
  }

  // ─── APPOINTMENTS ──────────────────────────────────

  /// Add a new appointment.
  Future<void> addAppointment(String userId, Map<String, dynamic> data) async {
    try {
      data['user_id'] = userId;
      await _db.from('appointments').insert(data);
    } catch (e) {
      debugPrint('Cloud sync error (addAppointment): $e');
    }
  }

  /// Get all appointments for a user.
  Future<List<Map<String, dynamic>>> getAppointments(String userId) async {
    try {
      final response = await _db
          .from('appointments')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Cloud fetch error (getAppointments): $e');
      return [];
    }
  }

  /// Update an appointment.
  Future<void> updateAppointment(int id, Map<String, dynamic> data) async {
    try {
      await _db.from('appointments').update(data).eq('id', id);
    } catch (e) {
      debugPrint('Cloud sync error (updateAppointment): $e');
    }
  }

  /// Delete an appointment.
  Future<void> deleteAppointment(int id) async {
    try {
      await _db.from('appointments').delete().eq('id', id);
    } catch (e) {
      debugPrint('Cloud sync error (deleteAppointment): $e');
    }
  }

  // ─── GENERIC HELPERS ───────────────────────────────

  /// Stream any table's data in real-time for a specific user.
  Stream<List<Map<String, dynamic>>> streamUserData(
      String table, String userId) {
    return _db.from(table).stream(primaryKey: ['id']).eq('user_id', userId);
  }

  // ─── PARTNER SYNC ─────────────────────────────────────

  /// Generate a 6-digit invite code and create a pending partner link.
  Future<String?> createPartnerInvite(String trackerUid) async {
    try {
      // Generate a random 6-digit code
      final random = DateTime.now().millisecondsSinceEpoch;
      final code = ((random % 900000) + 100000).toString();

      await _db.from('partner_links').insert({
        'tracker_uid': trackerUid,
        'invite_code': code,
        'status': 'pending',
      });
      return code;
    } catch (e) {
      debugPrint('Partner invite error: $e');
      return null;
    }
  }

  /// Accept a pending invite by entering the 6-digit code.
  Future<Map<String, dynamic>?> acceptPartnerInvite(
      String partnerUid, String code) async {
    try {
      // Find the pending invite
      final results = await _db
          .from('partner_links')
          .select()
          .eq('invite_code', code)
          .eq('status', 'pending')
          .limit(1);

      if (results.isEmpty) return null;

      final linkId = results.first['id'];

      // Update to active with the partner's uid
      await _db.from('partner_links').update({
        'partner_uid': partnerUid,
        'status': 'active',
      }).eq('id', linkId);

      return results.first;
    } catch (e) {
      debugPrint('Accept invite error: $e');
      return null;
    }
  }

  /// Get the active partner link for a user (as tracker OR partner).
  Future<Map<String, dynamic>?> getActivePartnerLink(String uid) async {
    try {
      // Check as tracker first
      final asTracker = await _db
          .from('partner_links')
          .select()
          .eq('tracker_uid', uid)
          .eq('status', 'active')
          .limit(1);

      if (asTracker.isNotEmpty) {
        return {...asTracker.first, 'role': 'tracker'};
      }

      // Check as partner
      final asPartner = await _db
          .from('partner_links')
          .select()
          .eq('partner_uid', uid)
          .eq('status', 'active')
          .limit(1);

      if (asPartner.isNotEmpty) {
        return {...asPartner.first, 'role': 'partner'};
      }

      return null;
    } catch (e) {
      debugPrint('Get partner link error: $e');
      return null;
    }
  }

  /// Revoke (disconnect) a partner link.
  Future<void> revokePartnerLink(String linkId) async {
    try {
      await _db
          .from('partner_links')
          .update({'status': 'revoked'})
          .eq('id', linkId);
    } catch (e) {
      debugPrint('Revoke partner error: $e');
    }
  }

  /// Fetch the profile of a linked partner by their UID.
  Future<Map<String, dynamic>?> getPartnerProfile(String uid) async {
    try {
      final result =
          await _db.from('users').select().eq('uid', uid).limit(1);
      if (result.isNotEmpty) return result.first;
      return null;
    } catch (e) {
      debugPrint('Get partner profile error: $e');
      return null;
    }
  }

  /// Stream the partner's assessments in real-time.
  Stream<List<Map<String, dynamic>>> streamPartnerAssessments(
      String partnerUserId) {
    return _db
        .from('assessments')
        .stream(primaryKey: ['id'])
        .eq('user_id', partnerUserId);
  }

  /// Fetch partner's cycle history.
  Future<List<Map<String, dynamic>>> getPartnerCycles(
      String partnerUserId) async {
    try {
      return await _db
          .from('cycles')
          .select()
          .eq('user_id', partnerUserId)
          .order('start_date', ascending: false);
    } catch (e) {
      debugPrint('Get partner cycles error: $e');
      return [];
    }
  }
}
