import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/community_post_model.dart';

class DatabaseService {
  final SupabaseClient _db = Supabase.instance.client;

  // ─── USER PROFILE ──────────────────────────────────

  /// Upload a profile avatar to Supabase storage.
  Future<String?> uploadAvatar(String uid, File imageFile) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${uid}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$uid/$fileName';

      await _db.storage.from('avatars').upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600'),
          );

      final imageUrl = _db.storage.from('avatars').getPublicUrl(filePath);
      
      // Update the user's profile with the new avatar URL
      await _db.from('users').update({'avatar_url': imageUrl}).eq('uid', uid);
      
      return imageUrl;
    } on StorageException catch (e) {
      debugPrint('Storage error uploading avatar: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      throw Exception('An unexpected error occurred during upload.');
    }
  }


  /// Create or update the full user profile (upsert).
  Future<void> saveUserProfile({
    required String uid,
    required String email,
    String name = '',
    String gender = 'Female',
    int cycleLength = 28,
    int periodDuration = 5,
    int age = 0,
    int weight = 60,
    int height = 165,
    bool trackingForOthers = false,
    String trackedPersonName = '',
    String trackedPersonRelation = 'Partner',
    bool isIrregular = false,
  }) async {
    try {
      final safeAge = age.clamp(13, 120);
      final safeWeight = weight.clamp(20, 300);
      final safeHeight = height.clamp(50, 250);
      final safeCycleLength = cycleLength.clamp(15, 60);
      final safePeriodDuration = periodDuration.clamp(1, 15);

      await _db.from('users').upsert({
        'uid': uid,
        'email': email,
        'name': name,
        'gender': gender,
        'cycle_length': safeCycleLength,
        'period_duration': safePeriodDuration,
        'age': safeAge,
        'weight': safeWeight,
        'height': safeHeight,
        'tracking_for_others': trackingForOthers,
        'tracked_person_name': trackedPersonName,
        'tracked_person_relation': trackedPersonRelation,
        'is_irregular': isIrregular,
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
      final rows = cycleStartDates
          .map((d) => {
                'user_id': userId,
                'start_date': d.toIso8601String().split('T')[0],
                'status': 'completed',
              })
          .toList();

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

  // ─── PERIOD DELAY EVENTS ────────────────────────────

  /// Log a period delay event when the user dismisses the
  /// "Did your period start?" prompt with "Not yet".
  /// This feeds the backend intelligence engine so it can
  /// learn from prediction misses and adjust future cycles.
  Future<void> logPeriodDelay({
    required String userId,
    required DateTime predictedDate,
    required DateTime dismissedAt,
  }) async {
    try {
      await _db.from('period_delay_events').insert({
        'user_id': userId,
        'predicted_date': predictedDate.toIso8601String().split('T')[0],
        'dismissed_at': dismissedAt.toIso8601String(),
        'event_type': 'not_yet',
      });
    } catch (e) {
      debugPrint('Cloud sync error (logPeriodDelay): $e');
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
          .update({'status': 'revoked'}).eq('id', linkId);
    } catch (e) {
      debugPrint('Revoke partner error: $e');
    }
  }

  /// Fetch the profile of a linked partner by their UID.
  Future<Map<String, dynamic>?> getPartnerProfile(String uid) async {
    try {
      final result = await _db.from('users').select().eq('uid', uid).limit(1);
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
        .stream(primaryKey: ['id']).eq('user_id', partnerUserId);
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

  // ─── COMMUNITY ───────────────────────────────────────

  /// Stream community posts for real-time updates
  Stream<List<Map<String, dynamic>>> streamCommunityPosts(String category) {
    return _db
        .from('community_posts')
        .stream(primaryKey: ['id'])
        .eq('category', category)
        .order('created_at', ascending: false);
  }

  /// Fetch community posts (legacy one-time fetch)
  Future<List<Map<String, dynamic>>> getCommunityPosts(String category) async {
    try {
      final response = await _db
          .from('community_posts')
          .select()
          .eq('category', category)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      return [];
    }
  }

  /// Check if the current user has liked a specific post
  Future<bool> hasUserLikedPost(int postId, String userId) async {
     try {
       final response = await _db
           .from('community_likes')
           .select()
           .eq('post_id', postId)
           .eq('user_id', userId)
           .limit(1);
       return response.isNotEmpty;
     } catch (e) {
       debugPrint('Error checking like status: $e');
       return false;
     }
  }

  /// Create a new community post
  Future<void> createCommunityPost({
    required String authorId,
    required String authorName,
    String? authorAvatar,
    required String category,
    required String content,
  }) async {
    try {
      await _db.from('community_posts').insert({
        'author_id': authorId,
        'author_name': authorName,
        'author_avatar': authorAvatar,
        'category': category,
        'content': content,
      });
    } catch (e) {
      debugPrint('Error creating post: $e');
    }
  }

  /// Toggle like status for a post
  Future<void> toggleLikePost(int postId, String userId, bool currentlyLiked) async {
    try {
      if (currentlyLiked) {
        // Remove like record, database trigger handles the decrement
        await _db
            .from('community_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
      } else {
        // Add like record, database trigger handles the increment
        await _db.from('community_likes').insert({
          'post_id': postId,
          'user_id': userId,
        });
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
      rethrow;
    }
  }

  /// Fetch comments for a post
  Future<List<Map<String, dynamic>>> getComments(int postId) async {
    try {
      final response = await _db
          .from('community_comments')
          .select()
          .eq('post_id', postId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching comments: $e');
      return [];
    }
  }

  /// Add a comment to a post
  Future<void> addComment({
    required int postId,
    required String authorId,
    required String authorName,
    String? authorAvatar,
    required String content,
  }) async {
    try {
      // Database trigger handles comments_count increment
      await _db.from('community_comments').insert({
        'post_id': postId,
        'author_id': authorId,
        'author_name': authorName,
        'author_avatar': authorAvatar,
        'content': content,
      });
    } catch (e) {
      debugPrint('Error adding comment: $e');
    }
  }

  /// Fetch a single community post by ID
  Future<CommunityPostModel?> getCommunityPostById(int postId) async {
    try {
      final response = await _db
          .from('community_posts')
          .select()
          .eq('id', postId)
          .maybeSingle();
      if (response != null) {
        return CommunityPostModel.fromJson(response);
      }
    } catch (e) {
      debugPrint('Error fetching post by id: $e');
    }
    return null;
  }

  /// Fetch replies to the current user's community posts
  Future<List<Map<String, dynamic>>> getRepliesToUserPosts(String userId) async {
    try {
      // 1. Get the user's post IDs
      final postsResponse = await _db
          .from('community_posts')
          .select('id')
          .eq('author_id', userId);
      
      final posts = List<Map<String, dynamic>>.from(postsResponse);
      if (posts.isEmpty) return [];

      final postIds = posts.map((p) => p['id'] as int).toList();

      // 2. Get comments on those posts, excluding the user's own comments
      final commentsResponse = await _db
          .from('community_comments')
          .select()
          .inFilter('post_id', postIds)
          .neq('author_id', userId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(commentsResponse);
    } catch (e) {
      debugPrint('Error fetching replies to user posts: $e');
      return [];
    }
  }

  // ─── CUSTOM NOTIFICATIONS ──────────────────────────

  /// Fetch all custom notifications for the user.
  Future<List<Map<String, dynamic>>> fetchCustomNotifications(String userId) async {
    try {
      // Clean up notifications older than 1 day
      final oneDayAgo = DateTime.now().subtract(const Duration(days: 1)).toUtc().toIso8601String();
      try {
        await _db
            .from('custom_notifications')
            .delete()
            .eq('user_id', userId)
            .lt('created_at', oneDayAgo);
      } catch (e) {
        debugPrint('Warning: Client-side custom notifications cleanup failed: $e');
      }

      final response = await _db
          .from('custom_notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching custom notifications: $e');
      return [];
    }
  }

  /// Insert a new custom notification.
  Future<void> addCustomNotification(String userId, String content) async {
    try {
      await _db.from('custom_notifications').insert({
        'user_id': userId,
        'content': content,
      });
    } catch (e) {
      debugPrint('Error adding custom notification: $e');
      rethrow;
    }
  }

  /// Delete a custom notification by ID.
  Future<void> deleteCustomNotification(int id) async {
    try {
      await _db.from('custom_notifications').delete().eq('id', id);
    } catch (e) {
      debugPrint('Error deleting custom notification: $e');
      rethrow;
    }
  }
}

