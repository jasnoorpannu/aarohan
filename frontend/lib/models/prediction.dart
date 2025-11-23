class Prediction {
  final int studentId;
  final double dropoutProbability;

  Prediction({
    required this.studentId,
    required this.dropoutProbability,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      studentId: json['student_id'] as int,
      dropoutProbability: (json['dropout_probability'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'dropout_probability': dropoutProbability,
    };
  }

  String get riskLevel {
    if (dropoutProbability >= 0.7) return 'High';
    if (dropoutProbability >= 0.4) return 'Medium';
    return 'Low';
  }
}
