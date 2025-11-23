import 'prediction.dart';

class PredictionResponse {
  final bool success;
  final int? cutoffDays;
  final int totalStudents;
  final List<Prediction> predictions;

  PredictionResponse({
    required this.success,
    this.cutoffDays,
    required this.totalStudents,
    required this.predictions,
  });

  factory PredictionResponse.fromJson(Map<String, dynamic> json) {
    return PredictionResponse(
      success: json['success'] as bool,
      cutoffDays: json['cutoff_days'] as int?,
      totalStudents: json['total_students'] as int,
      predictions: (json['predictions'] as List)
          .map((p) => Prediction.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'cutoff_days': cutoffDays,
      'total_students': totalStudents,
      'predictions': predictions.map((p) => p.toJson()).toList(),
    };
  }

  int get highRiskCount =>
      predictions.where((p) => p.dropoutProbability >= 0.7).length;

  int get mediumRiskCount => predictions
      .where((p) => p.dropoutProbability >= 0.4 && p.dropoutProbability < 0.7)
      .length;

  int get lowRiskCount =>
      predictions.where((p) => p.dropoutProbability < 0.4).length;
}
