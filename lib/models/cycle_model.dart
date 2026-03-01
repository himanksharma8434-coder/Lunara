/// Represents a menstrual cycle period tracked in the backend.
class CycleModel {
  final int? id;
  final String userId;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isPredicted;
  final String status; // 'active' or 'completed'

  CycleModel({
    this.id,
    required this.userId,
    required this.startDate,
    this.endDate,
    this.isPredicted = false,
    this.status = 'active',
  });

  factory CycleModel.fromJson(Map<String, dynamic> json) {
    return CycleModel(
      id: json['id'],
      userId: json['userId'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      isPredicted: json['isPredicted'] ?? false,
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'startDate': startDate.toIso8601String().split('T')[0],
      'endDate': endDate?.toIso8601String().split('T')[0],
      'isPredicted': isPredicted,
      'status': status,
    };
  }

  CycleModel copyWith({
    int? id,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    bool? isPredicted,
    String? status,
  }) {
    return CycleModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isPredicted: isPredicted ?? this.isPredicted,
      status: status ?? this.status,
    );
  }
}
