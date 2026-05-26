class UserModel {
  final String uid;
  final String? email;
  final String? phone;
  final String name;
  final int cycleLength;
  final String? avatarUrl;

  UserModel({
    required this.uid,
    this.email,
    this.phone,
    this.name = '',
    this.cycleLength = 28,
    this.avatarUrl,
  });

  /// Convert to Map to send to Supabase
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email ?? '',
      'phone': phone ?? '',
      'name': name,
      'cycle_length': cycleLength,
      'avatar_url': avatarUrl,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  /// Create from Supabase response map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'],
      phone: map['phone'],
      name: map['name'] ?? '',
      cycleLength: map['cycle_length'] ?? 28,
      avatarUrl: map['avatar_url'],
    );
  }
}
