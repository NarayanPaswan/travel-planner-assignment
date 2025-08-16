import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/shooting_provider.dart';
import '../../models/shooting_data.dart';
import 'add_shooting_data_screen.dart';

class ShootingDataScreen extends StatefulWidget {
  const ShootingDataScreen({super.key});

  @override
  State<ShootingDataScreen> createState() => _ShootingDataScreenState();
}

class _ShootingDataScreenState extends State<ShootingDataScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedTargetType = 'All';
  String _selectedLocation = 'All';
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _targetTypes = [
    'All',
    'static',
    'moving',
    'long_range',
    'close_range',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShootingProvider>().loadAllShootingData();
      context.read<ShootingProvider>().loadShootingStatistics();
      context.read<ShootingProvider>().loadAggregatedAnalytics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shooting Data Analytics'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Statistics', icon: Icon(Icons.analytics)),
            Tab(text: 'Data', icon: Icon(Icons.list)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildOverviewTab(), _buildStatisticsTab(), _buildDataTab()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddShootingDataScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Shooting Session',
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer<ShootingProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading data',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  provider.error!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    provider.clearError();
                    provider.loadAllShootingData();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final analytics = provider.aggregatedAnalytics;
        final totalSessions = analytics['totalSessions'] ?? 0;
        final locations =
            (analytics['locations'] as List<dynamic>?)?.length ?? 0;
        final targetTypes =
            (analytics['targetTypes'] as List<dynamic>?)?.length ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shooting Analytics Overview',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Sessions',
                      totalSessions.toString(),
                      Icons.sports_esports,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      'Locations',
                      locations.toString(),
                      Icons.location_on,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Target Types',
                      targetTypes.toString(),
                      Icons.track_changes,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      'Avg Accuracy',
                      '${provider.getAverageAccuracy().toStringAsFixed(1)}%',
                      Icons.trending_up,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Performance Metrics
              _buildPerformanceMetrics(provider),
              const SizedBox(height: 24),

              // Target Type Distribution
              _buildTargetTypeDistribution(provider),
              const SizedBox(height: 24),

              // Location Distribution
              _buildLocationDistribution(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatisticsTab() {
    return Consumer<ShootingProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final statistics = provider.shootingStatistics;

        if (statistics.isEmpty) {
          return const Center(child: Text('No shooting statistics available'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: statistics.length,
          itemBuilder: (context, index) {
            final stat = statistics[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            stat.fullName.isNotEmpty
                                ? stat.fullName
                                : stat.email,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${stat.totalSessions} sessions',
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Trip: ${stat.tripTitle}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),

                    // Statistics Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'Accuracy',
                            '${stat.avgAccuracy.toStringAsFixed(1)}%',
                            Icons.track_changes,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Best',
                            '${stat.bestAccuracy.toStringAsFixed(1)}%',
                            Icons.star,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Distance',
                            '${stat.avgDistance.toStringAsFixed(0)}m',
                            Icons.straighten,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Shots Summary
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'Shots Fired',
                            stat.totalShotsFired.toString(),
                            Icons.gps_fixed,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Shots Hit',
                            stat.totalShotsHit.toString(),
                            Icons.check_circle,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Overall',
                            '${stat.overallAccuracy.toStringAsFixed(1)}%',
                            Icons.analytics,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDataTab() {
    return Consumer<ShootingProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final shootingData = provider.shootingData;

        if (shootingData.isEmpty) {
          return const Center(child: Text('No shooting data available'));
        }

        return Column(
          children: [
            // Search and Filter Bar
            _buildSearchAndFilterBar(provider),

            // Data List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: shootingData.length,
                itemBuilder: (context, index) {
                  final data = shootingData[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getTargetTypeColor(data.targetType),
                        child: Icon(
                          _getTargetTypeIcon(data.targetType),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        data.location,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${data.targetType} • ${data.distanceMeters}m'),
                          Text(
                            DateFormat(
                              'MMM dd, yyyy',
                            ).format(data.shootingDate),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${data.accuracyPercentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getAccuracyColor(data.accuracyPercentage),
                            ),
                          ),
                          Text(
                            '${data.shotsHit}/${data.shotsFired}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _showShootingDataDetails(data),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetrics(ShootingProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Metrics',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Best Accuracy',
                    '${provider.getBestAccuracy().toStringAsFixed(1)}%',
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Worst Accuracy',
                    '${provider.getWorstAccuracy().toStringAsFixed(1)}%',
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Total Shots',
                    provider.getTotalShotsFired().toString(),
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Overall Accuracy',
                    '${provider.getOverallAccuracyPercentage().toStringAsFixed(1)}%',
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTargetTypeDistribution(ShootingProvider provider) {
    final targetTypes =
        provider.aggregatedAnalytics['targetTypes'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Target Type Distribution',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...targetTypes.map((type) {
              final count = provider
                  .getShootingDataByTargetType(type.toString())
                  .length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        type.toString().replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: LinearProgressIndicator(
                        value: provider.shootingData.isEmpty
                            ? 0.0
                            : count / provider.shootingData.length,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getTargetTypeColor(type.toString()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 40,
                      child: Text(
                        count.toString(),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationDistribution(ShootingProvider provider) {
    final locations =
        provider.aggregatedAnalytics['locations'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location Distribution',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...locations.map((location) {
              final count = provider
                  .getShootingDataByLocation(location.toString())
                  .length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        location.toString(),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: LinearProgressIndicator(
                        value: provider.shootingData.isEmpty
                            ? 0.0
                            : count / provider.shootingData.length,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 40,
                      child: Text(
                        count.toString(),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.blue[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterBar(ShootingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by location, equipment, or notes...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              // Implement search functionality
            },
          ),
          const SizedBox(height: 16),

          // Filters
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedTargetType,
                  decoration: const InputDecoration(
                    labelText: 'Target Type',
                    border: OutlineInputBorder(),
                  ),
                  items: _targetTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(
                        type == 'All'
                            ? 'All Types'
                            : type.replaceAll('_', ' ').toUpperCase(),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTargetType = value!;
                    });
                    _applyFilters(provider);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedLocation,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'All',
                      child: Text('All Locations'),
                    ),
                    ...(provider.aggregatedAnalytics['locations']
                                as List<dynamic>? ??
                            [])
                        .map(
                          (location) => DropdownMenuItem(
                            value: location.toString(),
                            child: Text(location.toString()),
                          ),
                        )
                        .toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedLocation = value!;
                    });
                    _applyFilters(provider);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date Range
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, true),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _startDate == null
                          ? 'Select Date'
                          : DateFormat('MMM dd, yyyy').format(_startDate!),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, false),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'End Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _endDate == null
                          ? 'Select Date'
                          : DateFormat('MMM dd, yyyy').format(_endDate!),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _applyFilters(ShootingProvider provider) {
    provider.searchShootingData(
      targetType: _selectedTargetType == 'All' ? null : _selectedTargetType,
      location: _selectedLocation == 'All' ? null : _selectedLocation,
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      _applyFilters(context.read<ShootingProvider>());
    }
  }

  void _showShootingDataDetails(ShootingData data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Shooting Session Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Location', data.location),
              _buildDetailRow(
                'Target Type',
                data.targetType.replaceAll('_', ' ').toUpperCase(),
              ),
              _buildDetailRow('Distance', '${data.distanceMeters} meters'),
              _buildDetailRow('Shots Fired', data.shotsFired.toString()),
              _buildDetailRow('Shots Hit', data.shotsHit.toString()),
              _buildDetailRow(
                'Accuracy',
                '${data.accuracyPercentage.toStringAsFixed(1)}%',
              ),
              if (data.weatherConditions != null)
                _buildDetailRow('Weather', data.weatherConditions!),
              if (data.windSpeedKmh != null)
                _buildDetailRow('Wind Speed', '${data.windSpeedKmh} km/h'),
              if (data.temperatureCelsius != null)
                _buildDetailRow('Temperature', '${data.temperatureCelsius}°C'),
              if (data.equipmentUsed != null)
                _buildDetailRow('Equipment', data.equipmentUsed!),
              if (data.notes != null) _buildDetailRow('Notes', data.notes!),
              _buildDetailRow(
                'Date',
                DateFormat('MMM dd, yyyy').format(data.shootingDate),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color _getTargetTypeColor(String targetType) {
    switch (targetType) {
      case 'static':
        return Colors.blue;
      case 'moving':
        return Colors.green;
      case 'long_range':
        return Colors.orange;
      case 'close_range':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getTargetTypeIcon(String targetType) {
    switch (targetType) {
      case 'static':
        return Icons.track_changes;
      case 'moving':
        return Icons.directions_run;
      case 'long_range':
        return Icons.straighten;
      case 'close_range':
        return Icons.near_me;
      default:
        return Icons.sports_esports;
    }
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 80) return Colors.green;
    if (accuracy >= 60) return Colors.orange;
    return Colors.red;
  }
}
