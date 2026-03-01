/// Represents a daily health assessment logged by the user.
class AssessmentModel {
  final int? id;
  final String userId;
  final DateTime date;
  final String? mood;
  final Map<String, dynamic>? symptoms;
  final int waterIntake;
  final double sleepHours;
  final int steps;

  AssessmentModel({
    this.id,
    required this.userId,
    required this.date,
    this.mood,
    this.symptoms,
    this.waterIntake = 0,
    this.sleepHours = 0,
    this.steps = 0,
  });

  factory AssessmentModel.fromJson(Map<String, dynamic> json) {
    return AssessmentModel(
      id: json['id'],
      userId: json['userId'],
      date: DateTime.parse(json['date']),
      mood: json['mood'],
      symptoms: json['symptoms'] != null
          ? Map<String, dynamic>.from(json['symptoms'])
          : null,
      waterIntake: json['waterIntake'] ?? 0,
      sleepHours: (json['sleepHours'] ?? 0).toDouble(),
      steps: json['steps'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'date': date.toIso8601String().split('T')[0],
      'mood': mood,
      'symptoms': symptoms,
      'waterIntake': waterIntake,
      'sleepHours': sleepHours,
      'steps': steps,
    };
  }

  AssessmentModel copyWith({
    int? id,
    String? userId,
    DateTime? date,
    String? mood,
    Map<String, dynamic>? symptoms,
    int? waterIntake,
    double? sleepHours,
    int? steps,
  }) {
    return AssessmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      mood: mood ?? this.mood,
      symptoms: symptoms ?? this.symptoms,
      waterIntake: waterIntake ?? this.waterIntake,
      sleepHours: sleepHours ?? this.sleepHours,
      steps: steps ?? this.steps,
    );
  }
}
