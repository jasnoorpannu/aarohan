import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/prediction_provider.dart';
import '../models/prediction.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  String _searchQuery = '';
  String _filterRisk = 'All';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(predictionProvider);
    final theme = Theme.of(context);

    if (state.response == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Results')),
        body: const Center(
          child: Text('No predictions available'),
        ),
      );
    }

    final response = state.response!;
    
    // Apply filters
    var filteredPredictions = response.predictions.where((p) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        if (!p.studentId.toString().contains(_searchQuery)) {
          return false;
        }
      }
      
      // Risk filter
      if (_filterRisk != 'All') {
        if (p.riskLevel != _filterRisk) {
          return false;
        }
      }
      
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prediction Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(predictionProvider.notifier).reset();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            tooltip: 'New Analysis',
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Cards
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Overview Stats
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.people,
                          color: theme.colorScheme.primary,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          response.totalStudents.toString(),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          'Total Students',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Risk Distribution
                Row(
                  children: [
                    Expanded(
                      child: _buildRiskCard(
                        'High Risk',
                        response.highRiskCount.toString(),
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildRiskCard(
                        'Medium Risk',
                        response.mediumRiskCount.toString(),
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildRiskCard(
                        'Low Risk',
                        response.lowRiskCount.toString(),
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search and Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search Student ID',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Filter: '),
                      const SizedBox(width: 8),
                      ..._buildFilterChips(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Results List
          Expanded(
            child: filteredPredictions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No results found',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredPredictions.length,
                    itemBuilder: (context, index) {
                      final prediction = filteredPredictions[index];
                      return _buildPredictionCard(prediction, theme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskCard(String label, String count, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFilterChips() {
    final filters = ['All', 'High', 'Medium', 'Low'];
    return filters.map((filter) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(filter),
          selected: _filterRisk == filter,
          onSelected: (selected) {
            setState(() {
              _filterRisk = filter;
            });
          },
        ),
      );
    }).toList();
  }

  Widget _buildPredictionCard(Prediction prediction, ThemeData theme) {
    Color riskColor;
    switch (prediction.riskLevel) {
      case 'High':
        riskColor = Colors.red;
        break;
      case 'Medium':
        riskColor = Colors.orange;
        break;
      default:
        riskColor = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: riskColor.withOpacity(0.2),
          child: Icon(
            Icons.person,
            color: riskColor,
          ),
        ),
        title: Text(
          'Student ID: ${prediction.studentId}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: prediction.dropoutProbability,
              backgroundColor: riskColor.withOpacity(0.2),
              color: riskColor,
            ),
            const SizedBox(height: 8),
            Text(
              'Dropout Probability: ${(prediction.dropoutProbability * 100).toStringAsFixed(1)}%',
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: riskColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            prediction.riskLevel,
            style: TextStyle(
              color: riskColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
