import 'dart:math';

import '../models/prediction_result.dart';

/// Pure, stateless menstrual-cycle prediction engine.
///
/// Takes historical cycle dates and logged wellness data, and produces a
/// [PredictionResult] containing predicted dates, confidence levels, and
/// phase descriptions. All computation is local — no network calls.
///
/// Design principles:
/// - **No outlier filtering**: Long cycles (>45d) are weighted down, not
///   discarded. This respects PCOS / anovulatory patterns.
/// - **Recency weighting**: Recent cycles influence predictions more than
///   older cycles via exponential decay.
/// - **Symptom correlation**: Pre-menstrual marker symptoms can shift the
///   predicted date by ±3 days.
/// - **Adaptive luteal phase**: Instead of assuming 14 days, the service
///   learns the actual luteal length from ovulation-proximal symptoms.
class MenstrualIntelligenceService {
  // ── Configuration constants ──────────────────────────────────────────

  /// Exponential decay factor for recency weighting (0 < λ ≤ 1).
  static const double _decayFactor = 0.80;

  /// Maximum symptom-based date adjustment (days).
  static const int _maxSymptomAdjustment = 3;

  /// Default luteal phase length when no data is available.
  static const int _defaultLutealLength = 14;

  /// Pre-menstrual marker symptoms (appearance signals period approach).
  static const Set<String> _preMenstrualMarkers = {
    'Cramps',
    'Bloating',
    'Breast Tenderness',
    'Back Pain',
    'Mood Swings',
  };

  /// Mid-cycle ovulation-proximal symptoms (used for luteal learning).
  static const Set<String> _ovulationMarkers = {
    'Nausea',
    'Breast Tenderness',
  };

  /// Minimum BBT thermal shift to confirm ovulation (°C).
  static const double _bbtThermalShift = 0.2;

  /// Number of consecutive elevated temps required (coverline rule).
  static const int _bbtConfirmationDays = 3;

  /// Number of baseline days before the shift to average.
  static const int _bbtBaselineDays = 6;

  /// Fertile cervical mucus types (indicate approaching ovulation).
  static const Set<String> _fertileCmTypes = {'EggWhite', 'Watery'};

  /// Post-ovulation cervical mucus types (confirm ovulation passed).
  static const Set<String> _infertileCmTypes = {'Dry', 'Sticky'};

  /// Days of infertile CM required after peak to confirm ovulation.
  static const int _cmConfirmationDays = 3;

  // ── Public API ───────────────────────────────────────────────────────

  /// Generates a [PredictionResult] from the user's data.
  ///
  /// [cycleHistory] — sorted list of period-start dates (oldest first).
  /// [wellnessHistory] — date-keyed map of daily snapshots.
  /// [userSetCycleLength] — user's manually set cycle length (fallback).
  /// [periodDuration] — length of menstruation in days.
  /// [lastPeriodDate] — most recent period start (may differ from last
  ///   entry in cycleHistory if set manually).
  PredictionResult predict({
    required List<DateTime> cycleHistory,
    required Map<String, Map<String, dynamic>> wellnessHistory,
    required int userSetCycleLength,
    required int periodDuration,
    DateTime? lastPeriodDate,
  }) {
    // ─ Edge case: no data at all ─────────────────────────────────────
    if (cycleHistory.isEmpty && lastPeriodDate == null) {
      return PredictionResult(
        effectiveCycleLength: userSetCycleLength.toDouble(),
        confidenceScore: 0.0,
        confidenceLabel: 'Insufficient Data',
        cycleClassification: CycleClassification.regular,
        lutealPhaseLength: _defaultLutealLength,
        adjustmentFactors: ['No cycle data available — using defaults'],
      );
    }

    final sorted = List<DateTime>.from(cycleHistory)..sort();
    final anchor = lastPeriodDate ?? (sorted.isNotEmpty ? sorted.last : null);

    // ─ Edge case: only one data point ────────────────────────────────
    if (sorted.length < 2) {
      final len = userSetCycleLength.toDouble();
      final luteal = _defaultLutealLength;
      final nextPeriod = anchor?.add(Duration(days: userSetCycleLength));
      final ovulation =
          anchor?.add(Duration(days: userSetCycleLength - luteal));
      return PredictionResult(
        predictedNextPeriod: nextPeriod,
        windowStart: nextPeriod?.subtract(const Duration(days: 3)),
        windowEnd: nextPeriod?.add(const Duration(days: 3)),
        predictedOvulation: ovulation,
        effectiveCycleLength: len,
        confidenceScore: 0.30,
        confidenceLabel: 'Low — limited history',
        cycleClassification: CycleClassification.regular,
        lutealPhaseLength: luteal,
        adjustmentFactors: [
          'Only ${sorted.length} cycle(s) recorded — using user-set length of $userSetCycleLength days',
        ],
      );
    }

    // ─ Compute cycle gaps ────────────────────────────────────────────
    final gaps = <int>[];
    final gapTypes = <CycleGapType>[];
    for (int i = 1; i < sorted.length; i++) {
      final gap = sorted[i].difference(sorted[i - 1]).inDays;
      if (gap > 0) {
        gaps.add(gap);
        gapTypes.add(_classifyGap(gap));
      }
    }

    if (gaps.isEmpty) {
      return PredictionResult(
        effectiveCycleLength: userSetCycleLength.toDouble(),
        confidenceScore: 0.0,
        confidenceLabel: 'Insufficient Data',
        adjustmentFactors: ['Cycle gaps could not be computed'],
      );
    }

    // ─ Weighted adaptive cycle length ────────────────────────────────
    final weightedLength = _computeWeightedLength(gaps, gapTypes);

    // ─ Standard deviation & confidence ───────────────────────────────
    final stdDev = _computeStdDev(gaps);
    final confidence = _stdDevToConfidence(stdDev);
    final confidenceLabel = _confidenceLabel(confidence, stdDev);
    final classification = _classify(stdDev);

    // ─ Adaptive luteal phase ─────────────────────────────────────────
    final luteal = _computeAdaptiveLuteal(
      cycleHistory: sorted,
      wellnessHistory: wellnessHistory,
      fallbackCycleLength: weightedLength,
    );

    // ─ Base prediction ───────────────────────────────────────────────
    final adjustments = <String>[];
    final cycleLenRounded = weightedLength.round();

    DateTime? basePrediction;
    if (anchor != null) {
      final anchorNorm =
          DateTime(anchor.year, anchor.month, anchor.day);
      basePrediction = anchorNorm.add(Duration(days: cycleLenRounded));
    }

    // ─ Symptom-weighted adjustment ───────────────────────────────────
    int symptomShift = 0;
    if (basePrediction != null && wellnessHistory.isNotEmpty) {
      symptomShift = _computeSymptomAdjustment(
        basePrediction: basePrediction,
        weightedCycleLength: cycleLenRounded,
        periodDuration: periodDuration,
        wellnessHistory: wellnessHistory,
        anchor: anchor!,
      );
      if (symptomShift != 0) {
        basePrediction = basePrediction.add(Duration(days: symptomShift));
        adjustments.add(
          symptomShift < 0
              ? 'Pre-menstrual symptoms appeared early → pulled prediction '
                  '${symptomShift.abs()} day(s) closer'
              : 'Pre-menstrual symptoms absent past expected window → pushed '
                  'prediction $symptomShift day(s) further',
        );
      }
    }

    // ─ Variable window ───────────────────────────────────────────────
    final windowMargin = _windowMargin(stdDev);
    final windowStart =
        basePrediction?.subtract(Duration(days: windowMargin));
    final windowEnd = basePrediction?.add(Duration(days: windowMargin));

    // ─ Ovulation ─────────────────────────────────────────────────────
    DateTime? ovulation;
    if (anchor != null) {
      final anchorNorm =
          DateTime(anchor.year, anchor.month, anchor.day);
      ovulation = anchorNorm.add(Duration(days: cycleLenRounded - luteal));
    }

    // ─ BBT & Cervical Mucus FAM Analysis ─────────────────────────────
    DateTime? bbtConfirmed;
    DateTime? cmPeak;
    OvulationConfidence ovulationConf = OvulationConfidence.unconfirmed;
    double famBoost = 0.0;

    if (anchor != null && wellnessHistory.isNotEmpty) {
      bbtConfirmed = _detectBbtThermalShift(
        cycleStart: anchor,
        cycleLength: cycleLenRounded,
        wellnessHistory: wellnessHistory,
      );
      cmPeak = _detectCervicalMucusPeak(
        cycleStart: anchor,
        cycleLength: cycleLenRounded,
        wellnessHistory: wellnessHistory,
      );

      if (bbtConfirmed != null && cmPeak != null) {
        final dayDiff = (bbtConfirmed.difference(cmPeak).inDays).abs();
        if (dayDiff <= 2) {
          ovulationConf = OvulationConfidence.confirmed;
          famBoost = 0.15;
          // Use the average of both signals as the refined ovulation date
          final avgDays = bbtConfirmed.difference(anchor).inDays;
          final peakDays = cmPeak.difference(anchor).inDays;
          ovulation = anchor.add(Duration(days: (avgDays + peakDays) ~/ 2));
          adjustments.add(
            'Ovulation confirmed by both BBT thermal shift and cervical mucus peak (±${dayDiff}d agreement)',
          );
        } else {
          ovulationConf = OvulationConfidence.probable;
          famBoost = 0.10;
          // Trust BBT over CM when they disagree
          ovulation = bbtConfirmed;
          adjustments.add(
            'Ovulation probable — BBT and cervical mucus signals diverge by ${dayDiff}d',
          );
        }
      } else if (bbtConfirmed != null) {
        ovulationConf = OvulationConfidence.probable;
        famBoost = 0.10;
        ovulation = bbtConfirmed;
        adjustments.add(
          'Ovulation probable — BBT thermal shift detected on ${_dateKey(bbtConfirmed)}',
        );
      } else if (cmPeak != null) {
        ovulationConf = OvulationConfidence.probable;
        famBoost = 0.10;
        ovulation = cmPeak;
        adjustments.add(
          'Ovulation probable — cervical mucus peak detected on ${_dateKey(cmPeak)}',
        );
      }
    }

    // Apply FAM confidence boost (capped at 1.0)
    final finalConfidence = (confidence + famBoost).clamp(0.0, 1.0);
    final finalLabel = famBoost > 0
        ? _confidenceLabel(finalConfidence, stdDev)
        : confidenceLabel;

    // ─ Build adjustment narrative ────────────────────────────────────
    if (gaps.length >= 2) {
      adjustments.insert(
          0,
          'Weighted average of ${gaps.length} cycles '
          '(${weightedLength.toStringAsFixed(1)} days, σ=${stdDev.toStringAsFixed(1)})');
    }
    if (luteal != _defaultLutealLength) {
      adjustments.add(
          'Personalized luteal phase: $luteal days (learned from symptom data)');
    }

    // Flag notable gap types
    for (int i = 0; i < gapTypes.length; i++) {
      if (gapTypes[i] == CycleGapType.extendedLutealTransition) {
        adjustments.add(
            'Cycle ${i + 1} (${gaps[i]}d) classified as Extended Luteal Transition');
      } else if (gapTypes[i] == CycleGapType.anovulatoryGap) {
        adjustments.add(
            'Cycle ${i + 1} (${gaps[i]}d) classified as Anovulatory Gap');
      }
    }

    // ─ Phase descriptions ────────────────────────────────────────────
    final ovDay = cycleLenRounded - luteal;
    final phases = _buildPhaseDescriptions(
      periodDuration: periodDuration,
      ovulationDay: ovDay,
      cycleLength: cycleLenRounded,
      classification: classification,
    );

    return PredictionResult(
      predictedNextPeriod: basePrediction,
      windowStart: windowStart,
      windowEnd: windowEnd,
      predictedOvulation: ovulation,
      effectiveCycleLength: weightedLength,
      confidenceScore: finalConfidence,
      confidenceLabel: finalLabel,
      cycleClassification: classification,
      lutealPhaseLength: luteal,
      phaseDescriptions: phases,
      adjustmentFactors: adjustments,
      gapClassifications: gapTypes,
      standardDeviation: stdDev,
      ovulationConfidence: ovulationConf,
      bbtConfirmedOvulation: bbtConfirmed,
      cmPeakDay: cmPeak,
    );
  }

  // ── Private: Weighted average ────────────────────────────────────────

  double _computeWeightedLength(List<int> gaps, List<CycleGapType> types) {
    double totalWeight = 0;
    double weightedSum = 0;

    for (int i = gaps.length - 1; i >= 0; i--) {
      // Recency weight: most recent = 1.0, decays backward
      final recencyWeight = pow(_decayFactor, (gaps.length - 1 - i)).toDouble();

      // Gap-type weight
      final typeWeight = _gapTypeWeight(types[i]);

      final combinedWeight = recencyWeight * typeWeight;
      weightedSum += gaps[i] * combinedWeight;
      totalWeight += combinedWeight;
    }

    if (totalWeight == 0) return 28.0;
    return weightedSum / totalWeight;
  }

  double _gapTypeWeight(CycleGapType type) {
    switch (type) {
      case CycleGapType.normal:
        return 1.0;
      case CycleGapType.extended:
        return 1.0;
      case CycleGapType.extendedLutealTransition:
        return 0.5;
      case CycleGapType.anovulatoryGap:
        return 0.25;
    }
  }

  CycleGapType _classifyGap(int days) {
    if (days <= 35) return CycleGapType.normal;
    if (days <= 45) return CycleGapType.extended;
    if (days <= 90) return CycleGapType.extendedLutealTransition;
    return CycleGapType.anovulatoryGap;
  }

  // ── Private: Standard deviation & confidence ─────────────────────────

  double _computeStdDev(List<int> gaps) {
    if (gaps.length < 2) return 0.0;
    final mean = gaps.reduce((a, b) => a + b) / gaps.length;
    final variance =
        gaps.map((g) => pow(g - mean, 2)).reduce((a, b) => a + b) /
            gaps.length;
    return sqrt(variance);
  }

  double _stdDevToConfidence(double stdDev) {
    if (stdDev <= 2) return 0.95;
    if (stdDev <= 4) return 0.75;
    if (stdDev <= 7) return 0.50;
    return 0.30;
  }

  String _confidenceLabel(double confidence, double stdDev) {
    if (confidence >= 0.90) return 'High Confidence';
    if (confidence >= 0.70) return 'Moderate — within normal range';
    if (confidence >= 0.45) return 'Variable Window — track symptoms closely';
    return 'Highly Variable — prediction is a range';
  }

  CycleClassification _classify(double stdDev) {
    if (stdDev <= 2) return CycleClassification.regular;
    if (stdDev <= 4) return CycleClassification.mildlyIrregular;
    if (stdDev <= 7) return CycleClassification.irregular;
    return CycleClassification.highlyIrregular;
  }

  int _windowMargin(double stdDev) {
    // Window grows with uncertainty: min 1 day, max 7 days
    return (stdDev * 0.8).round().clamp(1, 7);
  }

  // ── Private: Adaptive luteal phase ───────────────────────────────────

  int _computeAdaptiveLuteal({
    required List<DateTime> cycleHistory,
    required Map<String, Map<String, dynamic>> wellnessHistory,
    required double fallbackCycleLength,
  }) {
    if (cycleHistory.length < 2 || wellnessHistory.isEmpty) {
      return _defaultLutealLength;
    }

    final measuredLutealLengths = <int>[];

    // For each cycle gap, look for ovulation-proximal symptoms in the
    // middle of the cycle and measure the gap to the next period start.
    for (int i = 0; i < cycleHistory.length - 1; i++) {
      final cycleStart = cycleHistory[i];
      final nextStart = cycleHistory[i + 1];
      final gapDays = nextStart.difference(cycleStart).inDays;
      if (gapDays < 18 || gapDays > 90) continue;

      // Scan the middle third of the cycle for ovulation markers
      final midStart = gapDays ~/ 3;
      final midEnd = (gapDays * 2) ~/ 3;

      DateTime? latestOvulationSignal;
      for (int d = midStart; d <= midEnd; d++) {
        final checkDate = cycleStart.add(Duration(days: d));
        final key = _dateKey(checkDate);
        final entry = wellnessHistory[key];
        if (entry == null) continue;

        final symptoms = entry['symptoms'];
        if (symptoms == null) continue;
        final symptomList = List<String>.from(symptoms);

        if (symptomList.any((s) => _ovulationMarkers.contains(s))) {
          latestOvulationSignal = checkDate;
        }
      }

      if (latestOvulationSignal != null) {
        final lutealDays =
            nextStart.difference(latestOvulationSignal).inDays;
        // Sanity-check: luteal phase is typically 10–17 days
        if (lutealDays >= 8 && lutealDays <= 20) {
          measuredLutealLengths.add(lutealDays);
        }
      }
    }

    if (measuredLutealLengths.isEmpty) return _defaultLutealLength;

    // Weighted average favoring recent measurements
    double total = 0, weight = 0;
    for (int i = measuredLutealLengths.length - 1; i >= 0; i--) {
      final w =
          pow(_decayFactor, (measuredLutealLengths.length - 1 - i)).toDouble();
      total += measuredLutealLengths[i] * w;
      weight += w;
    }

    return (total / weight).round().clamp(10, 17);
  }

  // ── Private: Symptom-weighted adjustment ─────────────────────────────

  int _computeSymptomAdjustment({
    required DateTime basePrediction,
    required int weightedCycleLength,
    required int periodDuration,
    required Map<String, Map<String, dynamic>> wellnessHistory,
    required DateTime anchor,
  }) {
    // Expected pre-menstrual window: 7–2 days before predicted period.
    final expectedPmsStart =
        basePrediction.subtract(const Duration(days: 7));
    final expectedPmsEnd =
        basePrediction.subtract(const Duration(days: 2));

    // Check for early pre-menstrual markers (before the expected window)
    final earlyWindowStart =
        basePrediction.subtract(const Duration(days: 12));
    final earlyWindowEnd =
        basePrediction.subtract(const Duration(days: 8));

    int earlyMarkerCount = 0;
    int expectedMarkerCount = 0;
    int lateAbsenceCount = 0;

    // Scan early window
    for (DateTime d = earlyWindowStart;
        d.isBefore(earlyWindowEnd) || d.isAtSameMomentAs(earlyWindowEnd);
        d = d.add(const Duration(days: 1))) {
      // Only consider dates that have already passed
      if (d.isAfter(DateTime.now())) continue;
      final key = _dateKey(d);
      final entry = wellnessHistory[key];
      if (entry == null) continue;
      final symptoms = entry['symptoms'];
      if (symptoms == null) continue;
      final symptomList = List<String>.from(symptoms);
      if (symptomList.any((s) => _preMenstrualMarkers.contains(s))) {
        earlyMarkerCount++;
      }
    }

    // Scan expected window for presence
    for (DateTime d = expectedPmsStart;
        d.isBefore(expectedPmsEnd) || d.isAtSameMomentAs(expectedPmsEnd);
        d = d.add(const Duration(days: 1))) {
      if (d.isAfter(DateTime.now())) continue;
      final key = _dateKey(d);
      final entry = wellnessHistory[key];
      if (entry == null) {
        lateAbsenceCount++;
        continue;
      }
      final symptoms = entry['symptoms'];
      if (symptoms == null) {
        lateAbsenceCount++;
        continue;
      }
      final symptomList = List<String>.from(symptoms);
      if (symptomList.any((s) => _preMenstrualMarkers.contains(s))) {
        expectedMarkerCount++;
      } else {
        lateAbsenceCount++;
      }
    }

    // Decision logic
    if (earlyMarkerCount >= 2) {
      // Symptoms appeared early → pull prediction closer
      return -min(earlyMarkerCount, _maxSymptomAdjustment);
    }

    if (lateAbsenceCount >= 4 && expectedMarkerCount == 0) {
      // No markers in expected window → push prediction further
      return min(lateAbsenceCount ~/ 2, _maxSymptomAdjustment);
    }

    return 0;
  }

  // ── Private: Phase descriptions ──────────────────────────────────────

  Map<String, String> _buildPhaseDescriptions({
    required int periodDuration,
    required int ovulationDay,
    required int cycleLength,
    required CycleClassification classification,
  }) {
    final variableNote = classification == CycleClassification.highlyIrregular
        ? ' (timing may vary due to cycle irregularity)'
        : '';

    return {
      'Menstrual':
          'Days 1–$periodDuration: Menstruation. '
          'The uterine lining sheds. Rest and iron-rich foods are beneficial.',
      'Follicular':
          'Days ${periodDuration + 1}–${ovulationDay - 2}: Follicular phase. '
          'Estrogen rises, energy increases, and the body prepares for ovulation$variableNote.',
      'Ovulation':
          'Days ${ovulationDay - 1}–${ovulationDay + 1}: Ovulation window. '
          'Peak fertility, energy, and mood. Egg release typically occurs here$variableNote.',
      'Luteal':
          'Days ${ovulationDay + 2}–$cycleLength: Luteal phase. '
          'Progesterone rises; PMS symptoms may appear in the final days$variableNote.',
    };
  }

  // ── Utility ──────────────────────────────────────────────────────────

  String _dateKey(DateTime date) =>
      DateTime(date.year, date.month, date.day)
          .toIso8601String()
          .split('T')[0];

  // ── Private: BBT Thermal Shift Detection ─────────────────────────────

  /// Detects ovulation via the "coverline" rule:
  /// If 3 consecutive BBT readings are ≥ 0.2°C above the preceding
  /// 6-day average, ovulation is confirmed on the day before the shift.
  ///
  /// Returns the confirmed ovulation date, or null if no shift detected.
  DateTime? _detectBbtThermalShift({
    required DateTime cycleStart,
    required int cycleLength,
    required Map<String, Map<String, dynamic>> wellnessHistory,
  }) {
    // Collect BBT data for the current cycle
    final bbtData = <int, double>{}; // day offset → temperature
    for (int d = 0; d < cycleLength; d++) {
      final date = cycleStart.add(Duration(days: d));
      if (date.isAfter(DateTime.now())) break;
      final key = _dateKey(date);
      final entry = wellnessHistory[key];
      if (entry == null) continue;
      final bbt = entry['bbt'];
      if (bbt == null) continue;
      bbtData[d] = (bbt as num).toDouble();
    }

    if (bbtData.length < _bbtBaselineDays + _bbtConfirmationDays) return null;

    final sortedDays = bbtData.keys.toList()..sort();

    // Slide through the cycle looking for a thermal shift
    for (int i = _bbtBaselineDays; i <= sortedDays.length - _bbtConfirmationDays; i++) {
      // Compute baseline: average of previous 6 recorded temps
      final baselineDays = sortedDays.sublist(
        (i - _bbtBaselineDays).clamp(0, i),
        i,
      );
      if (baselineDays.length < _bbtBaselineDays) continue;

      final baseline = baselineDays
              .map((d) => bbtData[d]!)
              .reduce((a, b) => a + b) /
          baselineDays.length;

      // Check if next 3 temps are all ≥ baseline + shift
      final shiftDays = sortedDays.sublist(i, i + _bbtConfirmationDays);
      final allElevated = shiftDays.every(
        (d) => bbtData[d]! >= baseline + _bbtThermalShift,
      );

      if (allElevated) {
        // Ovulation occurred on the day before the first elevated temp
        final ovulationDayOffset = sortedDays[i] - 1;
        if (ovulationDayOffset >= 0) {
          return cycleStart.add(Duration(days: ovulationDayOffset));
        }
      }
    }

    return null;
  }

  // ── Private: Cervical Mucus Peak Detection ───────────────────────────

  /// Detects the "Peak Day" — the last day of fertile cervical mucus
  /// (Egg White or Watery), confirmed by 3 subsequent days of
  /// infertile mucus (Dry or Sticky).
  ///
  /// Returns the peak day date, or null if no confirmed peak.
  DateTime? _detectCervicalMucusPeak({
    required DateTime cycleStart,
    required int cycleLength,
    required Map<String, Map<String, dynamic>> wellnessHistory,
  }) {
    DateTime? lastFertileDay;
    int infertileStreakAfterPeak = 0;

    for (int d = 0; d < cycleLength; d++) {
      final date = cycleStart.add(Duration(days: d));
      if (date.isAfter(DateTime.now())) break;
      final key = _dateKey(date);
      final entry = wellnessHistory[key];
      if (entry == null) continue;

      final cm = entry['cervicalMucus'] as String?;
      if (cm == null) continue;

      if (_fertileCmTypes.contains(cm)) {
        lastFertileDay = date;
        infertileStreakAfterPeak = 0; // Reset streak
      } else if (_infertileCmTypes.contains(cm) && lastFertileDay != null) {
        infertileStreakAfterPeak++;
        if (infertileStreakAfterPeak >= _cmConfirmationDays) {
          return lastFertileDay; // Confirmed peak
        }
      }
    }

    return null;
  }
}
