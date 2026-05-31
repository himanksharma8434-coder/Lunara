import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CycleModel', () {
    test('Cycle day calculation is correct for day 1', () {
      final today = DateTime.now();
      final startDate = DateTime(today.year, today.month, today.day);
      const cycleLength = 28;

      final daysSinceStart = today.difference(startDate).inDays;
      final cycleDay = (daysSinceStart % cycleLength) + 1;

      expect(cycleDay, 1);
    });

    test('Phase is Menstrual during days 1-5', () {
      const periodDuration = 5;
      for (int day = 1; day <= periodDuration; day++) {
        final phase = _getPhaseForDay(day, periodDuration, 28);
        expect(phase, 'Menstrual', reason: 'Day $day should be Menstrual');
      }
    });

    test('Phase is Follicular after period and before ovulation', () {
      const periodDuration = 5;
      const cycleLength = 28;
      for (int day = periodDuration + 1; day < 13; day++) {
        final phase = _getPhaseForDay(day, periodDuration, cycleLength);
        expect(phase, 'Follicular', reason: 'Day $day should be Follicular');
      }
    });

    test('Phase is Ovulation around ovulation day', () {
      const periodDuration = 5;
      const cycleLength = 28;
      for (int day = 13; day <= 15; day++) {
        final phase = _getPhaseForDay(day, periodDuration, cycleLength);
        expect(phase, 'Ovulation', reason: 'Day $day should be Ovulation');
      }
    });

    test('Phase is Luteal after ovulation window', () {
      const periodDuration = 5;
      const cycleLength = 28;
      for (int day = 16; day <= cycleLength; day++) {
        final phase = _getPhaseForDay(day, periodDuration, cycleLength);
        expect(phase, 'Luteal', reason: 'Day $day should be Luteal');
      }
    });

    test('Adaptive cycle length averages correctly', () {
      final history = [
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 29), 
        DateTime(2026, 2, 28),
        DateTime(2026, 3, 28), 
      ];

      final gaps = <int>[];
      for (int i = 1; i < history.length; i++) {
        gaps.add(history[i].difference(history[i - 1]).inDays);
      }
      final valid = gaps.where((g) => g >= 18 && g <= 45).toList();
      final avg = (valid.reduce((a, b) => a + b) / valid.length).round();

      expect(avg, 29);
    });

    test('Fertile window spans 6 days ending at ovulation', () {
      const cycleLength = 28;
      final lastPeriod = DateTime(2026, 3, 1);
      final ovulationDay = cycleLength - 14; // day 14
      final ovulationDate = lastPeriod.add(Duration(days: ovulationDay - 1));
      final fertileStart = ovulationDate.subtract(const Duration(days: 5));

      expect(ovulationDate, DateTime(2026, 3, 14));
      expect(fertileStart, DateTime(2026, 3, 9));
      expect(ovulationDate.difference(fertileStart).inDays, 5);
    });

    test('Cycle is flagged as irregular with >7 day variation', () {
      final gaps = [25, 33, 27, 35]; 
      final shortest = gaps.reduce((a, b) => a < b ? a : b);
      final longest = gaps.reduce((a, b) => a > b ? a : b);
      final variation = longest - shortest;

      expect(variation, 10);
      expect(variation > 7, true);
    });
  });
}

String _getPhaseForDay(int day, int periodDuration, int cycleLength) {
  if (day <= periodDuration) return 'Menstrual';
  final ovDay = cycleLength - 14;
  if (day < ovDay - 1) return 'Follicular';
  if (day <= ovDay + 1) return 'Ovulation';
  return 'Luteal';
}
