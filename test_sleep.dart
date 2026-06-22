import 'package:health/health.dart';

void main() {
  print(HealthDataType.values.where((v) => v.toString().contains('SLEEP')));
}
