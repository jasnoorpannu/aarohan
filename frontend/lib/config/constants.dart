class AppConstants {
  // API Configuration
  static const String apiBaseUrl = 'http://localhost:5000';
  static const int apiTimeout = 60;

  // UI Constants
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double borderRadius = 12.0;

  // Risk Thresholds
  static const double highRiskThreshold = 0.7;
  static const double mediumRiskThreshold = 0.4;

  // File Upload
  static const List<String> allowedExtensions = ['csv'];
  static const int maxFileSizeMB = 50;
}
