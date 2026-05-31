import 'package:hive/hive.dart';

part 'cycle_record_local.g.dart';

/// A single menstrual cycle record stored locally in the encrypted Hive database.
///
/// Mirrors the Supabase `cycles` table.
@HiveType(typeId: 1)
class CycleRecordLocal extends HiveObject {
  /// The user's unique identifier.
  @HiveField(0)
  String userId = '';

  /// When this cycle began.
  @HiveField(1)
  DateTime startDate = DateTime.now();

  /// When this cycle ended (null if currently active).
  @HiveField(2)
  DateTime? endDate;

  /// Length of this cycle in days (calculated after completion).
  @HiveField(3)
  int? cycleLength;

  /// Status: 'active', 'completed'.
  @HiveField(4)
  String status = 'active';

  /// Timestamp of when this record was last modified locally.
  @HiveField(5)
  DateTime lastModified = DateTime.now();
}
