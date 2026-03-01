/// Represents a doctor appointment booking.
class AppointmentModel {
  final int? id;
  final String doctorName;
  final String specialty;
  final String? hospital;
  final double? rating;
  final DateTime date;
  final String time;
  final String status; // 'upcoming', 'completed', 'cancelled'

  AppointmentModel({
    this.id,
    required this.doctorName,
    required this.specialty,
    this.hospital,
    this.rating,
    required this.date,
    required this.time,
    this.status = 'upcoming',
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'],
      doctorName: json['doctorName'] ?? '',
      specialty: json['specialty'] ?? '',
      hospital: json['hospital'],
      rating: json['rating']?.toDouble(),
      date: DateTime.parse(json['date']),
      time: json['time'] ?? '',
      status: json['status'] ?? 'upcoming',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'doctorName': doctorName,
      'specialty': specialty,
      'hospital': hospital,
      'rating': rating,
      'date': date.toIso8601String().split('T')[0],
      'time': time,
      'status': status,
    };
  }

  AppointmentModel copyWith({
    int? id,
    String? doctorName,
    String? specialty,
    String? hospital,
    double? rating,
    DateTime? date,
    String? time,
    String? status,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      doctorName: doctorName ?? this.doctorName,
      specialty: specialty ?? this.specialty,
      hospital: hospital ?? this.hospital,
      rating: rating ?? this.rating,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
    );
  }
}
