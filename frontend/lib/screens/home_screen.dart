import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'upload_screen.dart';
import '../providers/prediction_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isCheckingHealth = false;
  String? _healthMessage;

  @override
  void initState() {
    super.initState();
    _checkBackendHealth();
  }

  Future<void> _checkBackendHealth() async {
    setState(() {
      _isCheckingHealth = true;
      _healthMessage = null;
    });

    try {
      final isHealthy = await ref.read(predictionProvider.notifier).checkHealth();
      
      if (mounted) {
        setState(() {
          _healthMessage = isHealthy 
              ? 'Backend is ready!' 
              : 'Backend is running but model is not loaded';
          _isCheckingHealth = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _healthMessage = 'Cannot connect to backend';
          _isCheckingHealth = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.secondaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.school,
                      size: 80,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Student Dropout Predictor',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Subtitle
                  Text(
                    'Upload student data to predict dropout risk using machine learning',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Health Status Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isCheckingHealth)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Icon(
                              _healthMessage == 'Backend is ready!'
                                  ? Icons.check_circle
                                  : Icons.error_outline,
                              color: _healthMessage == 'Backend is ready!'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          const SizedBox(width: 12),
                          Text(
                            _healthMessage ?? 'Checking backend...',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 20),
                            onPressed: _checkBackendHealth,
                            tooltip: 'Refresh',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Get Started Button
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const UploadScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Get Started'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 20,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info Button
                  TextButton.icon(
                    onPressed: () => _showInfoDialog(context),
                    icon: const Icon(Icons.info_outline),
                    label: const Text('How it works'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How It Works'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoItem(
                '1. Upload CSV File',
                'Select a CSV file containing student activity data',
              ),
              const SizedBox(height: 12),
              _buildInfoItem(
                '2. Get Predictions',
                'Our ML model analyzes the data and predicts dropout risk for each student',
              ),
              const SizedBox(height: 12),
              _buildInfoItem(
                '3. View Results',
                'See detailed predictions with risk levels for all students',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
