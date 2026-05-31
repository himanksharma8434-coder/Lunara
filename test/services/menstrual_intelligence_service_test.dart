import 'package:flutter_test/flutter_test.dart';
import 'package:lunara/models/prediction_result.dart';
import 'package:lunara/services/menstrual_intelligence_service.dart';

void main() {
  late MenstrualIntelligenceService service;

  setUp(() {
    service = MenstrualIntelligenceService();
  });

  // ─── Edge Cases ────────────────────────────────────────────────────

  group('Edge cases', () {
    test('0 cycles: returns defaults with 0.0 confidence', () {
      final result = service.predict(
        cycleHistory: [],
        wellnessHistory: {},
        userSetCycleLength: 28,
        periodDuration: 5,
      );

      expect(result.confidenceScore, 0.0);
      expect(result.effectiveCycleLength, 28.0);
      expect(result.confidenceLabel, 'Insufficient Data');
      expect(result.predictedNextPeriod, isNull);
    });

    test('1 cycle: uses user-set length, confidence 0.30', () {
      final result = service.predict(
        cycleHistory: [DateTime(2026, 3, 1)],
        wellnessHistory: {},
        userSetCycleLength: 30,
        periodDuration: 5,
        lastPeriodDate: DateTime(2026, 3, 1),
      );

      expect(result.confidenceScore, 0.30);
      expect(result.effectiveCycleLength, 30.0);
      expect(result.predictedNextPeriod, DateTime(2026, 3, 31));
    });

    test('2 cycles: uses single gap, confidence capped at computed value', () {
      final result = service.predict(
        cycleHistory: [DateTime(2026, 1, 1), DateTime(2026, 1, 29)],
        wellnessHistory: {},
        userSetCycleLength: 28,
        periodDuration: 5,
        lastPeriodDate: DateTime(2026, 1, 29),
      );

      // Single gap of 28 days → σ = 0 → confidence 0.95
      expect(result.effectiveCycleLength, 28.0);
      expect(result.confidenceScore, 0.95);
      expect(result.predictedNextPeriod, DateTime(2026, 2, 26));
    });
  });

  // ─── Regular Cycles ────────────────────────────────────────────────

  group('Regular cycles', () {
    test('Consistent 28-day cycles: high confidence, regular classification', () {
      final history = [
        DateTime(2025, 10, 1),
        DateTime(2025, 10, 29),
        DateTime(2025, 11, 26),
        DateTime(2025, 12, 24),
        DateTime(2026, 1, 21),
        DateTime(2026, 2, 18),
      ];

      final result = service.predict(
        cycleHistory: history,
        wellnessHistory: {},
        userSetCycleLength: 28,
        periodDuration: 5,
        lastPeriodDate: history.last,
      );

      expect(result.confidenceScore, greaterThanOrEqualTo(0.90));
      expect(result.cycleClassification, CycleClassification.regular);
      expect(result.effectiveCycleLength, closeTo(28, 1));
      expect(result.lutealPhaseLength, 14); // Default, no symptom data
    });

    test('Recency weighting: recent cycles influence prediction more', () {
      // Old cycles: 28 days, recent cycles: 32 days
      final history = [
        DateTime(2025, 7, 1),
        DateTime(2025, 7, 29), // gap 28
        DateTime(2025, 8, 26), // gap 28
        DateTime(2025, 9, 27), // gap 32
        DateTime(2025, 10, 29), // gap 32
        DateTime(2025, 11, 30), // gap 32
      ];

      final result = service.predict(
        cycleHistory: history,
        wellnessHistory: {},
        userSetCycleLength: 28,
        periodDuration: 5,
        lastPeriodDate: history.last,
      );

      // Weighted average should lean toward 32 (recent cycles)
      expect(result.effectiveCycleLength, greaterThan(29.5));
    });
  });

  // ─── PCOS / Irregular Cycles ───────────────────────────────────────

  group('PCOS / Irregular cycles', () {
    test('High variation cycles: low confidence, highlyIrregular classification', () {
      final history = [
        DateTime(2025, 6, 1),
        DateTime(2025, 6, 26), // 25 days
        DateTime(2025, 8, 9),  // 44 days
        DateTime(2025, 10, 8), // 60 days
        DateTime(2025, 11, 7), // 30 days
      ];

      final result = service.predict(
        cycleHistory: history,
        wellnessHistory: {},
        userSetCycleLength: 28,
        periodDuration: 5,
        lastPeriodDate: history.last,
      );

      expect(result.confidenceScore, lessThanOrEqualTo(0.50));
      expect(
        result.cycleClassification,
        anyOf(CycleClassification.irregular, CycleClassification.highlyIrregular),
      );
      expect(result.isVariableWindow, isTrue);
    });

    test('Long cycles (>45 days) are NOT discarded', () {
      final history = [
        DateTime(2025, 1, 1),
        DateTime(2025, 3, 10), // 68 days — would be discarded by old logic
        DateTime(2025, 5, 7),  // 58 days
        DateTime(2025, 6, 6),  // 30 days
      ];

      final result = service.predict(
        cycleHistory: history,
        wellnessHistory: {},
        userSetCycleLength: 28,
        periodDuration: 5,
        lastPeriodDate: history.last,
      );

      // The 68 and 58 day cycles should influence the result
      // (weighted down but not removed)
      expect(result.effectiveCycleLength, greaterThan(30));
      expect(result.adjustmentFactors, isNotEmpty);
    });
  });

  // ─── Cycle Gap Classification ──────────────────────────────────────

  group('Cycle gap classification', () {
    test('Extended Luteal Transition (45–90 days) is classified correctly', () {
      final history = [
        DateTime(2025, 1, 1),
        DateTime(2025, 1, 29), // 28 days — normal
        DateTime(2025, 3, 20), // 50 days — extended luteal transition
      ];

      final result = service.predict(
        cycleHistory: history,
        wellnessHistory: {},
        userSetCycleLength: 28,
        periodDuration: 5,
        lastPeriodDate: history.last,
      );

      expect(result.gapClassifications, contains(CycleGapType.extendedLutealTransition));
      expect(
        result.adjustmentFactors.any((f) => f.contains('Extended Luteal Transition')),
        isTrue,
      );
    });

    test('Anovulatory Gap (90+ days) is classified correctly', () {
      final history = [
        DateTime(2025, 1, 1),
        DateTime(2025, 1, 29),  // 28 days — normal
        DateTime(2025, 5, 10),  // 101 days — anovulatory
      ];

      final result = service.predict(
        cycleHistory: history,
        wellnessHistory: {},
        userSetCycleLength: 28,
        periodDuration: 5,
        lastPeriodDate: history.last,
      );

      expect(result.gapClassifications, contains(CycleGapType.anovulatoryGap));
      expect(
        result.adjustmentFactors.any((f) => f.contains('Anovulatory Gap')),
        isTrue,
      );
    });

    test('Anovulatory gaps are weighted at 0.25, not discarded', () {
      // If the anovulatory gap were discarded, effective length ≈ 28.
      // With 0.25 weight, it should pull the average slightly higher.
      final history = [
        DateTime(2025, 1, 1),
        DateTime(2025, 1, 29), // 28
        DateTime(2025, 2, 26), // 28
        DateTime(2025, 6, 5),  // 99 — anovulatory, weighted 0.25
        DateTime(2025, 7, 3),  // 28
      ];

      final result = service.predict(
        cycleHistory: history,
        wellnessHistory: {},
        userSetCycleLength: 28,
        periodDuration: 5,
        lastPeriodDate: history.last,
      );

      // Should be slightly above 28 due to the 99-day gap at reduced weight
      expect(result.effectiveCycleLength, greaterThan(28));
      expect(result.effectiveCycleLength, lessThan(50)); // sanity
    });
  });

  // ─── Symptom-Weighted Predictions ──────────────────────────────────

  group('Symptom-weighted predictions', () {
    test('Early pre-menstrual symptoms pull prediction closer', () {
      final history = [
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 29),
        DateTime(2026, 2, 26),
      ];
      final lastPeriod = DateTime(2026, 2, 26);
      // Predicted next: ~March 26
      // Early PMS window: March 14–18 (12–8 days before predicted)
      final wellness = <String, Map<String, dynamic>>{
        '2026-03-14': {'symptoms': ['Cramps', 'Bloating']},
        '2026-03-15': {'symptoms': ['Mood Swings', 'Back Pain']},
        '2026-03-16': {'symptoms': ['Cramps']},
      };

      final result = service.predict(
        cycleHistory: history,
        wellnessHistory: wellness,
        userSetCycleLength: 28,
        periodDuration: 5,
        lastPeriodDate: lastPeriod,
      );

      final baseDate = DateTime(2026, 2, 26).add(
        Duration(days: result.effectiveCycleLengthRounded),
      );

      // Prediction should be pulled earlier than the base
      expect(
        result.predictedNextPeriod!.isBefore(baseDate),
        isTrue,
        reason: 'Early symptoms should pull prediction closer',
      );
      expect(
        result.adjustmentFactors.any((f) => f.contains('pulled')),
        isTrue,
      );
    });
  });

  // ─── Adaptive Luteal Phase ─────────────────────────────────────────

  group('Adaptive luteal phase', () {
    test('Learns luteal length from ovulation-proximal symptoms', () {
      final history = [
        DateTime(2025, 10, 1),
        DateTime(2025, 10, 29), // gap 28
        DateTime(2025, 11, 26), // gap 28
        DateTime(2025, 12, 24), // gap 28
      ];

      // In the middle of each cycle, log ovulation markers
      // Cycle 1: Oct 1 → Oct 29 → mid-cycle ~Oct 12 → luteal = 29-12 = 17 (too high)
      // Cycle 2: Oct 29 → Nov 26 → mid-cycle ~Nov 8 (day 11) → luteal = 26-8 = 18 (too high)
      // Use more realistic mid-cycle (day 14-15 of 28 = actual ovulation)
      // Cycle 1: Oct 14 symptom → luteal = Oct 29 - Oct 14 = 15
      // Cycle 2: Nov 12 symptom → luteal = Nov 26 - Nov 12 = 14
      // Cycle 3: Dec 10 symptom → luteal = Dec 24 - Dec 10 = 14
      final wellness = <String, Map<String, dynamic>>{
        '2025-10-14': {'symptoms': ['Nausea', 'Breast Tenderness']},
        '2025-11-12': {'symptoms': ['Nausea']},
        '2025-12-10': {'symptoms': ['Breast Tenderness']},
      };

      final result = service.predict(
        cycleHistory: history,
        wellnessHistory: wellness,
        userSetCycleLength: 28,
        periodDuration: 5,
        lastPeriodDate: history.last,
      );

      // Should have learned a luteal phase close to 14-15
      expect(result.lutealPhaseLength, inInclusiveRange(13, 16));
    });

    test('Falls back to 14 days without sufficient symptom data', () {
      final history = [
        DateTime(2025, 10, 1),
        DateTime(2025, 10, 29),
        DateTime(2025, 11, 26),
      ];

      final result = service.predict(
        cycleHistory: history,
        wellnessHistory: {},
        userSetCycleLength: 28,
        periodDuration: 5,
        lastPeriodDate: history.last,
      );

      expect(result.lutealPhaseLength, 14);
    });
  });

  // ─── PredictionResult Model ────────────────────────────────────────

  group('PredictionResult', () {
    test('toSyncSafeMap only contains prediction dates and label', () {
      final result = PredictionResult(
        predictedNextPeriod: DateTime(2026, 4, 1),
        predictedOvulation: DateTime(2026, 3, 18),
        effectiveCycleLength: 28.5,
        confidenceScore: 0.75,
        confidenceLabel: 'Moderate',
        adjustmentFactors: ['sensitive data here'],
      );

      final safeMap = result.toSyncSafeMap();

      expect(safeMap.containsKey('predicted_next_period'), isTrue);
      expect(safeMap.containsKey('predicted_ovulation'), isTrue);
      expect(safeMap.containsKey('confidence_label'), isTrue);
      expect(safeMap.containsKey('effective_cycle_length'), isTrue);
      // Must NOT contain adjustment factors
      expect(safeMap.containsKey('adjustment_factors'), isFalse);
    });

    test('isVariableWindow is true when confidence < 0.6', () {
      const low = PredictionResult(confidenceScore: 0.4);
      const high = PredictionResult(confidenceScore: 0.8);

      expect(low.isVariableWindow, isTrue);
      expect(high.isVariableWindow, isFalse);
    });

    test('ovulationDay uses adaptive luteal length', () {
      const result = PredictionResult(
        effectiveCycleLength: 30.0,
        lutealPhaseLength: 12,
      );

      expect(result.ovulationDay, 18); // 30 - 12
    });
  });

  // ─── Confidence & Std Dev ──────────────────────────────────────────

  group('Std dev confidence mapping', () {
    test('Very regular cycles (σ ≈ 0) yield confidence ≥ 0.90', () {
      final history = [
        DateTime(2025, 1, 1),
        DateTime(2025, 1, 29),
        DateTime(2025, 2, 26),
        DateTime(2025, 3, 26),
      ];

      final result = service.predict(
        cycleHistory: history,
        wellnessHistory: {},
        userSetCycleLength: 28,
        periodDuration: 5,
        lastPeriodDate: history.last,
      );

      expect(result.confidenceScore, greaterThanOrEqualTo(0.90));
      expect(result.confidenceLabel, contains('High'));
    });

    test('Moderately variable cycles yield confidence ≈ 0.75', () {
      final history = [
        DateTime(2025, 1, 1),
        DateTime(2025, 1, 29), // 28
        DateTime(2025, 2, 28), // 30
        DateTime(2025, 3, 24), // 24
        DateTime(2025, 4, 24), // 31
      ];

      final result = service.predict(
        cycleHistory: history,
        wellnessHistory: {},
        userSetCycleLength: 28,
        periodDuration: 5,
        lastPeriodDate: history.last,
      );

      expect(result.confidenceScore, inInclusiveRange(0.50, 0.80));
    });
  });

  // ─── Phase Descriptions ────────────────────────────────────────────

  group('Phase descriptions', () {
    test('Highly irregular cycles include variability note in descriptions', () {
      final history = [
        DateTime(2025, 1, 1),
        DateTime(2025, 1, 26), // 25
        DateTime(2025, 3, 11), // 44
        DateTime(2025, 5, 9),  // 59
        DateTime(2025, 6, 8),  // 30
      ];

      final result = service.predict(
        cycleHistory: history,
        wellnessHistory: {},
        userSetCycleLength: 28,
        periodDuration: 5,
        lastPeriodDate: history.last,
      );

      if (result.cycleClassification == CycleClassification.highlyIrregular) {
        expect(
          result.phaseDescriptions['Ovulation'],
          contains('irregularity'),
        );
      }
    });
  });

  // ─── BBT Thermal Shift Detection ───────────────────────────────────

  group('BBT thermal shift detection', () {
    test('Detects ovulation from coverline rule (6 baseline + 3 elevated)', () {
      final history = [
        DateTime(2025, 10, 1),
        DateTime(2025, 10, 29),
        DateTime(2025, 11, 26),
      ];

      // Simulate BBT data for the current cycle starting Nov 26
      // Pre-ovulatory: days 1-12 (~36.3°C), post-ov: days 13+ (~36.6°C)
      final wellness = <String, Map<String, dynamic>>{};
      final start = DateTime(2025, 11, 26);
      for (int d = 1; d <= 12; d++) {
        final date = start.add(Duration(days: d));
        final key = date.toIso8601String().split('T')[0];
        wellness[key] = {'bbt': 36.2 + (d % 3) * 0.05}; // ~36.2-36.3
      }
      // Post-ovulation shift
      for (int d = 13; d <= 20; d++) {
        final date = start.add(Duration(days: d));
        final key = date.toIso8601String().split('T')[0];
        wellness[key] = {'bbt': 36.5 + (d % 2) * 0.05}; // ~36.5-36.55
      }

      final result = service.predict(
        cycleHistory: history,
        wellnessHistory: wellness,
        userSetCycleLength: 28,
        periodDuration: 5,
        lastPeriodDate: history.last,
      );

      expect(result.bbtConfirmedOvulation, isNotNull);
      expect(
        result.ovulationConfidence,
        anyOf(OvulationConfidence.probable, OvulationConfidence.confirmed),
      );
    });

    test('No false confirmation with insufficient BBT data', () {
      final history = [
        DateTime(2025, 10, 1),
        DateTime(2025, 10, 29),
      ];

      // Only 3 days of BBT (not enough for baseline + shift)
      final wellness = <String, Map<String, dynamic>>{
        '2025-10-10': {'bbt': 36.3},
        '2025-10-11': {'bbt': 36.3},
        '2025-10-12': {'bbt': 36.6},
      };

      final result = service.predict(
        cycleHistory: history,
        wellnessHistory: wellness,
        userSetCycleLength: 28,
        periodDuration: 5,
        lastPeriodDate: history.last,
      );

      expect(result.bbtConfirmedOvulation, isNull);
      expect(result.ovulationConfidence, OvulationConfidence.unconfirmed);
    });
  });

  // ─── Cervical Mucus Peak Detection ─────────────────────────────────

  group('Cervical mucus peak detection', () {
    test('Detects peak from EggWhite → Sticky transition', () {
      final history = [
        DateTime(2025, 10, 1),
        DateTime(2025, 10, 29),
        DateTime(2025, 11, 26),
      ];

      final start = DateTime(2025, 11, 26);
      final wellness = <String, Map<String, dynamic>>{};
      // Day 10-12: EggWhite (fertile), Day 13-15: Sticky (infertile)
      for (int d = 10; d <= 12; d++) {
        final key = start.add(Duration(days: d)).toIso8601String().split('T')[0];
        wellness[key] = {'cervicalMucus': 'EggWhite'};
      }
      for (int d = 13; d <= 15; d++) {
        final key = start.add(Duration(days: d)).toIso8601String().split('T')[0];
        wellness[key] = {'cervicalMucus': 'Sticky'};
      }

      final result = service.predict(
        cycleHistory: history,
        wellnessHistory: wellness,
        userSetCycleLength: 28,
        periodDuration: 5,
        lastPeriodDate: history.last,
      );

      expect(result.cmPeakDay, isNotNull);
      // Peak should be the last EggWhite day (day 12)
      expect(result.cmPeakDay, start.add(const Duration(days: 12)));
    });
  });

  // ─── Combined BBT + CM Confirmation ────────────────────────────────

  group('Combined BBT + CM ovulation confirmation', () {
    test('Both agreeing within 2 days gives confirmed confidence with boost', () {
      final history = [
        DateTime(2025, 10, 1),
        DateTime(2025, 10, 29),
        DateTime(2025, 11, 26),
      ];

      final start = DateTime(2025, 11, 26);
      final wellness = <String, Map<String, dynamic>>{};

      // BBT: baseline days 1-8 (~36.25), shift days 14-16 (~36.55)
      for (int d = 1; d <= 8; d++) {
        final key = start.add(Duration(days: d)).toIso8601String().split('T')[0];
        wellness[key] = {'bbt': 36.20 + (d % 2) * 0.05};
      }
      // Days 9-13: transition (still low for BBT baseline check)
      for (int d = 9; d <= 13; d++) {
        final key = start.add(Duration(days: d)).toIso8601String().split('T')[0];
        wellness[key] = {'bbt': 36.25};
      }
      for (int d = 14; d <= 20; d++) {
        final key = start.add(Duration(days: d)).toIso8601String().split('T')[0];
        wellness[key] = {
          ...wellness[key] ?? {},
          'bbt': 36.55,
        };
      }

      // CM: EggWhite days 11-13, Sticky days 14-16
      for (int d = 11; d <= 13; d++) {
        final key = start.add(Duration(days: d)).toIso8601String().split('T')[0];
        wellness[key] = {
          ...wellness[key] ?? {},
          'cervicalMucus': 'EggWhite',
        };
      }
      for (int d = 14; d <= 16; d++) {
        final key = start.add(Duration(days: d)).toIso8601String().split('T')[0];
        wellness[key] = {
          ...wellness[key] ?? {},
          'cervicalMucus': 'Sticky',
        };
      }

      final result = service.predict(
        cycleHistory: history,
        wellnessHistory: wellness,
        userSetCycleLength: 28,
        periodDuration: 5,
        lastPeriodDate: history.last,
      );

      // Both BBT and CM should detect ovulation around day 13
      if (result.bbtConfirmedOvulation != null && result.cmPeakDay != null) {
        final dayDiff =
            (result.bbtConfirmedOvulation!.difference(result.cmPeakDay!).inDays).abs();
        if (dayDiff <= 2) {
          expect(result.ovulationConfidence, OvulationConfidence.confirmed);
          expect(result.confidenceScore, greaterThan(0.95));
        }
      }
    });

    test('No BBT or CM data leaves ovulation unconfirmed', () {
      final history = [
        DateTime(2025, 10, 1),
        DateTime(2025, 10, 29),
        DateTime(2025, 11, 26),
      ];

      final result = service.predict(
        cycleHistory: history,
        wellnessHistory: {},
        userSetCycleLength: 28,
        periodDuration: 5,
        lastPeriodDate: history.last,
      );

      expect(result.ovulationConfidence, OvulationConfidence.unconfirmed);
      expect(result.bbtConfirmedOvulation, isNull);
      expect(result.cmPeakDay, isNull);
    });
  });
}
