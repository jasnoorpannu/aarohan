import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prediction_response.dart';
import '../models/api_error.dart';

class ApiService {
  // Update this URL to match your backend server
  // For local development: http://localhost:5000
  // For deployed backend: your server URL
  static const String baseUrl = 'http://localhost:5000';

  /// Check if the API server is healthy and model is loaded
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw ApiError(
          'Health check failed: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw ApiError('Cannot connect to server. Please ensure the backend is running.');
    } on http.ClientException {
      throw ApiError('Network error. Please check your connection.');
    } catch (e) {
      throw ApiError('Unexpected error: ${e.toString()}');
    }
  }

  /// Upload CSV file and get predictions
  Future<PredictionResponse> predictFromCsv({
    required File csvFile,
    int? cutoffDays,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/predict');
      
      // Add cutoff parameter if provided
      if (cutoffDays != null) {
        uri = uri.replace(queryParameters: {'cutoff': cutoffDays.toString()});
      }

      var request = http.MultipartRequest('POST', uri);
      
      // Attach the CSV file
      request.files.add(
        await http.MultipartFile.fromPath('file', csvFile.path),
      );

      // Send the request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );

      // Get response
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return PredictionResponse.fromJson(jsonData);
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body) as Map<String, dynamic>;
        throw ApiError(
          errorData['error'] ?? 'Bad request',
          statusCode: 400,
        );
      } else if (response.statusCode == 500) {
        final errorData = json.decode(response.body) as Map<String, dynamic>;
        throw ApiError(
          errorData['error'] ?? 'Server error',
          statusCode: 500,
        );
      } else {
        throw ApiError(
          'Unexpected error: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw ApiError('Cannot connect to server. Please ensure the backend is running at $baseUrl');
    } on http.ClientException {
      throw ApiError('Network error. Please check your connection.');
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError('Unexpected error: ${e.toString()}');
    }
  }
}
