import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'results_screen.dart';
import '../providers/prediction_provider.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: false,
        withReadStream: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        ref.read(predictionProvider.notifier).setSelectedFile(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  Future<void> _uploadAndPredict() async {
    // Clear any previous errors
    ref.read(predictionProvider.notifier).clearError();

    // Upload and predict
    await ref.read(predictionProvider.notifier).uploadAndPredict();

    // Check results
    final state = ref.read(predictionProvider);
    
    if (state.error != null && state.error!.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } else if (state.response != null) {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ResultsScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(predictionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Data'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Instructions',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• CSV file must contain student activity data\n'
                      '• Required columns: id_student, gender, region, etc.\n'
                      '• Upload your file to get dropout risk predictions',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // File Selection Card
            Card(
              child: InkWell(
                onTap: state.isLoading ? null : _pickFile,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(
                        state.selectedFile != null
                            ? Icons.check_circle
                            : Icons.upload_file,
                        size: 64,
                        color: state.selectedFile != null
                            ? Colors.green
                            : theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.selectedFile != null
                            ? 'File Selected'
                            : 'Tap to Select CSV File',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (state.selectedFile != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          state.selectedFile!.path.split('/').last,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            ref.read(predictionProvider.notifier).clearFile();
                          },
                          icon: const Icon(Icons.close),
                          label: const Text('Clear'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Upload Button
            FilledButton.icon(
              onPressed: state.isLoading || state.selectedFile == null
                  ? null
                  : _uploadAndPredict,
              icon: state.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cloud_upload),
              label: Text(
                state.isLoading ? 'Processing...' : 'Upload & Predict',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            // Progress Indicator
            if (state.isLoading) ...[
              const SizedBox(height: 24),
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                'Analyzing student data...',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
