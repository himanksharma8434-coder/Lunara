import 'package:flutter_test/flutter_test.dart';
import 'package:lunara/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('fromMap creates model with correct values', () {
      final map = {
        'uid': 'abc123',
        'email': 'test@example.com',
        'name': 'Test User',
        'cycle_length': 30,
      };

      final user = UserModel.fromMap(map);

      expect(user.uid, 'abc123');
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test User');
      expect(user.cycleLength, 30);
    });

    test('fromMap handles missing fields with defaults', () {
      final map = <String, dynamic>{
        'uid': 'abc123',
        'email': 'test@example.com',
      };

      final user = UserModel.fromMap(map);

      expect(user.name, '');
      expect(user.cycleLength, 28);
    });

    test('toMap includes all fields', () {
      final user = UserModel(
        uid: 'abc123',
        email: 'test@example.com',
        name: 'Test User',
        cycleLength: 30,
      );

      final map = user.toMap();

      expect(map['uid'], 'abc123');
      expect(map['email'], 'test@example.com');
      expect(map['name'], 'Test User');
      expect(map['cycle_length'], 30);
      expect(map.containsKey('created_at'), true);
    });
  });
}
