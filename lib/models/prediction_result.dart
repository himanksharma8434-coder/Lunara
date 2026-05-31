/// Classification of cycle regularity based on standard deviation of cycle gaps.
enum CycleClassification {
  /// σ ≤ 2 days — highly predictable cycles.
  regular,

  /// σ 2–4 days — minor variation, within clinical normal range.
  mildlyIrregular,

  /// σ 4–7 days — noticeable variation, may benefit from symptom tracking.
  irregular,

  /// σ > 7 days — PCOS / hormonal territory, predictions are windowed.
  highlyIrregular,
}

/// Classification for individual cycle-gap durations.
enum CycleGapType {
  /// 18–35 days — standard menstrual cycle.
  normal,

  /// 35–45 days — longer but still ovulatory cycle.
  extended,

  /// 45–90 days — possible extended luteal transition or delayed ovulation.
  extendedLutealTransition,

  /// 90+ days — likely anovulatory gap.
  anovulatoryGap,
}

/// Confidence level for ovulation detection based on FAM markers.
enum OvulationConfidence {
  /// No BBT or cervical mucus data available.
  unconfirmed,

  /// Either BBT thermal shift OR cervical mucus peak detected (not both).
  probable,

  /// Both BBT thermal shift AND cervical mucus peak agree within 2 days.
  confirmed,
}

/// Immutable result returned by [MenstrualIntelligenceService.predict].
///
/// Contains predicted dates, confidence scoring, cycle classification,
/// and human-readable adjustment explanations. This object is safe to
/// cache in a Provider — all fields are final.
class PredictionResult {
  /// Best-estimate next period start date.
  final DateTime? predictedNextPeriod;

  /// Lower bound of the prediction window (used when confidence is low).
  final DateTime? windowStart;

  /// Upper bound of the prediction window.
  final DateTime? windowEnd;

  /// Predicted ovulation date based on adaptive luteal phase.
  final DateTime? predictedOvulation;

  /// Weighted adaptive cycle length (non-rounded for precision).
  final double effectiveCycleLength;

  /// 0.0–1.0 confidence score derived from standard deviation.
  final double confidenceScore;

  /// Human-readable confidence label.
  final String confidenceLabel;

  /// Overall cycle regularity classification.
  final CycleClassification cycleClassification;

  /// Personalized luteal phase length (defaults to 14).
  final int lutealPhaseLength;

  /// Contextual phase descriptions keyed by phase name.
  final Map<String, String> phaseDescriptions;

  /// Human-readable list of what factors shifted the prediction date.
  final List<String> adjustmentFactors;

  /// Per-gap classifications for UI display (most recent first).
  final List<CycleGapType> gapClassifications;

  /// Standard deviation of cycle gaps (in days).
  final double standardDeviation;

  /// Confidence level for ovulation detection (FAM-based).
  final OvulationConfidence ovulationConfidence;

  /// Ovulation date confirmed by BBT thermal shift (3-day coverline rule).
  final DateTime? bbtConfirmedOvulation;

  /// Last day of fertile cervical mucus (Egg White / Watery).
  final DateTime? cmPeakDay;

  const PredictionResult({
    this.predictedNextPeriod,
    this.windowStart,
    this.windowEnd,
    this.predictedOvulation,
    this.effectiveCycleLength = 28.0,
    this.confidenceScore = 0.0,
    this.confidenceLabel = 'Insufficient Data',
    this.cycleClassification = CycleClassification.regular,
    this.lutealPhaseLength = 14,
    this.phaseDescriptions = const {},
    this.adjustmentFactors = const [],
    this.gapClassifications = const [],
    this.standardDeviation = 0.0,
    this.ovulationConfidence = OvulationConfidence.unconfirmed,
    this.bbtConfirmedOvulation,
    this.cmPeakDay,
  });

  /// Rounded effective cycle length for use in day-count arithmetic.
  int get effectiveCycleLengthRounded => effectiveCycleLength.round();

  /// Ovulation day within the cycle (1-indexed).
  int get ovulationDay => effectiveCycleLengthRounded - lutealPhaseLength;

  /// Whether the prediction is a range rather than a single date.
  bool get isVariableWindow => confidenceScore < 0.6;

  /// Privacy-safe map containing only resultant predictions.
  /// This is the ONLY data that should ever leave the device.
  Map<String, dynamic> toSyncSafeMap() {
    return {
      'predicted_next_period':
          predictedNextPeriod?.toIso8601String().split('T')[0],
      'predicted_ovulation':
          predictedOvulation?.toIso8601String().split('T')[0],
      'effective_cycle_length': effectiveCycleLengthRounded,
      'confidence_label': confidenceLabel,
    };
  }

  @override
  String toString() =>
      'PredictionResult(next: $predictedNextPeriod, '
      'confidence: ${(confidenceScore * 100).toStringAsFixed(0)}% '
      '[$confidenceLabel], cycle: ${effectiveCycleLength.toStringAsFixed(1)}d, '
      'luteal: ${lutealPhaseLength}d, '
      'classification: ${cycleClassification.name}, '
      'ovulation: ${ovulationConfidence.name})';
}
