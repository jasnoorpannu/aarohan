import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/prediction_response.dart';

// Provider for ApiService
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// State for prediction results
class PredictionState {
  final PredictionResponse? response;
  final bool isLoading;
  final String? error;
  final File? selectedFile;

  PredictionState({
    this.response,
    this.isLoading = false,
    this.error,
    this.selectedFile,
  });

  PredictionState copyWith({
    PredictionResponse? response,
    bool? isLoading,
    String? error,
    File? selectedFile,
  }) {
    return PredictionState(
      response: response ?? this.response,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedFile: selectedFile ?? this.selectedFile,
    );
  }

  PredictionState clearError() {
    return copyWith(error: '');
  }

  PredictionState clearFile() {
    return PredictionState(
      response: response,
      isLoading: false,
      error: null,
      selectedFile: null,
    );
  }
}

// StateNotifier for managing prediction state
class PredictionNotifier extends StateNotifier<PredictionState> {
  final ApiService _apiService;

  PredictionNotifier(this._apiService) : super(PredictionState());

  void setSelectedFile(File file) {
    state = state.copyWith(selectedFile: file, error: '');
  }

  void clearFile() {
    state = state.clearFile();
  }

  void clearError() {
    state = state.clearError();
  }

  Future<void> uploadAndPredict() async {
    if (state.selectedFile == null) {
      state = state.copyWith(error: 'Please select a CSV file first');
      return;
    }

    state = state.copyWith(isLoading: true, error: '');

    try {
      final response = await _apiService.predictFromCsv(
        csvFile: state.selectedFile!,
      );

      state = state.copyWith(
        response: response,
        isLoading: false,
        error: '',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> checkHealth() async {
    try {
      final health = await _apiService.healthCheck();
      return health['status'] == 'healthy' && health['model_loaded'] == true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void reset() {
    state = PredictionState();
  }
}

// Provider for prediction state
final predictionProvider =
    StateNotifierProvider<PredictionNotifier, PredictionState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return PredictionNotifier(apiService);
});
