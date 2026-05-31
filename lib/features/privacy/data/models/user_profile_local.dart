import 'package:hive/hive.dart';

part 'user_profile_local.g.dart';

/// Local-first user profile stored in the encrypted Hive database.
///
/// Mirrors the Supabase `users` table schema so that data can be seamlessly
/// migrated between cloud and local storage in the future.
@HiveType(typeId: 0)
class UserProfileLocal extends HiveObject {
  /// The user's unique identifier (matches Supabase UID when syncing).
  @HiveField(0)
  String uid = '';

  @HiveField(1)
  String name = '';
  
  @HiveField(2)
  String email = '';

  @HiveField(3)
  int cycleLength = 28;
  
  @HiveField(4)
  int periodDuration = 5;
  
  @HiveField(5)
  int age = 0;
  
  @HiveField(6)
  int weight = 60;
  
  @HiveField(7)
  int height = 165;

  @HiveField(8)
  bool trackingForOthers = false;
  
  @HiveField(9)
  String trackedPersonName = '';
  
  @HiveField(10)
  String trackedPersonRelation = 'Partner';

  /// Timestamp of when this record was last modified locally.
  @HiveField(11)
  DateTime lastModified = DateTime.now();
}
