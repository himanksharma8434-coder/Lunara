import 'package:hive/hive.dart';

part 'assessment_local.g.dart';

/// A daily health assessment stored locally in the encrypted Hive database.
///
/// Mirrors the Supabase `assessments` table.
@HiveType(typeId: 2)
class AssessmentLocal extends HiveObject {
  /// The user's unique identifier.
  @HiveField(0)
  String userId = '';

  /// The date of this assessment (time component is ignored).
  @HiveField(1)
  DateTime date = DateTime.now();

  /// Mood label for the day (e.g., 'happy', 'sad', 'anxious').
  @HiveField(2)
  String? mood;

  /// List of symptom tags logged for the day.
  @HiveField(3)
  List<String> symptoms = [];

  /// Glasses of water consumed.
  @HiveField(4)
  int waterIntake = 0;

  /// Hours of sleep logged.
  @HiveField(5)
  double sleepHours = 0;

  /// Step count for the day.
  @HiveField(6)
  int steps = 0;

  /// Calorie intake (for Pillar 3 cross-referencing).
  @HiveField(7)
  int? caloriesConsumed;

  /// Cramp severity on a 0–10 scale (for Pillar 3 analytics).
  @HiveField(8)
  int? crampSeverity;

  /// Optional free-text notes.
  @HiveField(9)
  String? notes;

  /// Timestamp of when this record was last modified locally.
  @HiveField(10)
  DateTime lastModified = DateTime.now();
}
