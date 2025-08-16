import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/trips_provider.dart';
import '../../models/trip.dart';
import 'create_trip_screen.dart';
import 'trip_detail_screen.dart';
import 'edit_trip_screen.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy =
      'startDate'; // 'startDate', 'endDate', 'destination', 'duration', 'createdAt'
  bool _sortAscending = false;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  int? _filterMinDuration;
  int? _filterMaxDuration;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripsProvider>().loadUserTrips();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Trip> _getFilteredAndSortedTrips(List<Trip> trips) {
    List<Trip> filteredTrips = List.from(trips);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredTrips = filteredTrips
          .where(
            (trip) =>
                trip.destination.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                (trip.description?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false),
          )
          .toList();
    }

    // Apply date range filter
    if (_filterStartDate != null) {
      filteredTrips = filteredTrips
          .where(
            (trip) =>
                trip.startDate.isAfter(_filterStartDate!) ||
                trip.startDate.isAtSameMomentAs(_filterStartDate!),
          )
          .toList();
    }
    if (_filterEndDate != null) {
      filteredTrips = filteredTrips
          .where(
            (trip) =>
                trip.endDate.isBefore(_filterEndDate!) ||
                trip.endDate.isAtSameMomentAs(_filterEndDate!),
          )
          .toList();
    }

    // Apply duration filter
    if (_filterMinDuration != null) {
      filteredTrips = filteredTrips
          .where((trip) => trip.durationInDays >= _filterMinDuration!)
          .toList();
    }
    if (_filterMaxDuration != null) {
      filteredTrips = filteredTrips
          .where((trip) => trip.durationInDays <= _filterMaxDuration!)
          .toList();
    }

    // Apply sorting
    filteredTrips.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'startDate':
          comparison = a.startDate.compareTo(b.startDate);
          break;
        case 'endDate':
          comparison = a.endDate.compareTo(b.endDate);
          break;
        case 'destination':
          comparison = a.destination.compareTo(b.destination);
          break;
        case 'duration':
          comparison = a.durationInDays.compareTo(b.durationInDays);
          break;
        case 'createdAt':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filteredTrips;
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _filterStartDate = null;
      _filterEndDate = null;
      _filterMinDuration = null;
      _filterMaxDuration = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<TripsProvider>().loadUserTrips();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          _buildSearchAndFilterBar(),

          // Expanded content
          Expanded(
            child: Consumer<TripsProvider>(
              builder: (context, tripsProvider, child) {
                if (tripsProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (tripsProvider.error != null) {
                  return _buildErrorWidget(tripsProvider);
                }

                if (tripsProvider.trips.isEmpty) {
                  return _buildEmptyStateWidget();
                }

                final filteredTrips = _getFilteredAndSortedTrips(
                  tripsProvider.trips,
                );

                if (filteredTrips.isEmpty) {
                  return _buildNoResultsWidget();
                }

                return RefreshIndicator(
                  onRefresh: () => tripsProvider.loadUserTrips(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTrips.length,
                    itemBuilder: (context, index) {
                      final trip = filteredTrips[index];
                      return _buildTripCard(context, trip);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateTrip(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search trips by destination or description...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),

          const SizedBox(height: 12),

          // Sort and Filter Controls
          Row(
            children: [
              // Sort Dropdown
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: InputDecoration(
                    labelText: 'Sort by',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'startDate',
                      child: Text('Start Date'),
                    ),
                    DropdownMenuItem(value: 'endDate', child: Text('End Date')),
                    DropdownMenuItem(
                      value: 'destination',
                      child: Text('Destination'),
                    ),
                    DropdownMenuItem(
                      value: 'duration',
                      child: Text('Duration'),
                    ),
                    DropdownMenuItem(
                      value: 'createdAt',
                      child: Text('Created Date'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                    });
                  },
                ),
              ),

              const SizedBox(width: 8),

              // Sort Direction Toggle
              IconButton(
                onPressed: () {
                  setState(() {
                    _sortAscending = !_sortAscending;
                  });
                },
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                ),
                tooltip: _sortAscending ? 'Sort Ascending' : 'Sort Descending',
              ),

              const SizedBox(width: 8),

              // Filter Toggle
              IconButton(
                onPressed: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
                icon: Icon(
                  _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
                ),
                tooltip: 'Toggle Filters',
              ),
            ],
          ),

          // Filter Options
          if (_showFilters) ...[
            const SizedBox(height: 16),
            _buildFilterOptions(),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Filters',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear All'),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Date Range Filters
        Row(
          children: [
            Expanded(
              child: _buildDateFilter(
                label: 'From Date',
                value: _filterStartDate,
                onChanged: (date) {
                  setState(() {
                    _filterStartDate = date;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDateFilter(
                label: 'To Date',
                value: _filterEndDate,
                onChanged: (date) {
                  setState(() {
                    _filterEndDate = date;
                  });
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Duration Filters
        Row(
          children: [
            Expanded(
              child: _buildDurationFilter(
                label: 'Min Duration (days)',
                value: _filterMinDuration,
                onChanged: (value) {
                  setState(() {
                    _filterMinDuration = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDurationFilter(
                label: 'Max Duration (days)',
                value: _filterMaxDuration,
                onChanged: (value) {
                  setState(() {
                    _filterMaxDuration = value;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateFilter({
    required String label,
    required DateTime? value,
    required Function(DateTime?) onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date != null) {
          onChanged(date);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value != null ? _formatDate(value) : label,
                style: TextStyle(
                  color: value != null ? Colors.black : Colors.grey.shade500,
                ),
              ),
            ),
            if (value != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 16),
                onPressed: () => onChanged(null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationFilter({
    required String label,
    required int? value,
    required Function(int?) onChanged,
  }) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        suffixIcon: value != null
            ? IconButton(
                icon: const Icon(Icons.clear, size: 16),
                onPressed: () => onChanged(null),
              )
            : null,
      ),
      keyboardType: TextInputType.number,
      onChanged: (text) {
        if (text.isEmpty) {
          onChanged(null);
        } else {
          final intValue = int.tryParse(text);
          if (intValue != null && intValue > 0) {
            onChanged(intValue);
          }
        }
      },
    );
  }

  Widget _buildErrorWidget(TripsProvider tripsProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error loading trips',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            tripsProvider.error!,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              tripsProvider.clearError();
              tripsProvider.loadUserTrips();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flight_takeoff, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'No trips yet',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Start planning your next adventure!',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreateTrip(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Your First Trip'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'No trips found',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _clearFilters,
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, Trip trip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _navigateToTripDetail(context, trip),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip Image or Placeholder
            if (trip.tripImageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  trip.tripImageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.image_not_supported,
                        size: 64,
                        color: Colors.grey[500],
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Icon(
                  Icons.flight_takeoff,
                  size: 64,
                  color: Colors.grey[500],
                ),
              ),

            // Trip Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trip Title and Destination
                  Text(
                    trip.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trip.destination,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
                  ),

                  // Dates
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${trip.durationInDays} days',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Description
                  if (trip.description != null &&
                      trip.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      trip.description!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Action Buttons
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () => _navigateToTripDetail(context, trip),
                        icon: const Icon(Icons.visibility),
                        label: const Text('View Details'),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => _editTrip(context, trip),
                            icon: const Icon(Icons.edit),
                            tooltip: 'Edit Trip',
                          ),
                          IconButton(
                            onPressed: () => _deleteTrip(context, trip),
                            icon: const Icon(Icons.delete),
                            tooltip: 'Delete Trip',
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToCreateTrip(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CreateTripScreen()));
  }

  void _navigateToTripDetail(BuildContext context, Trip trip) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)));
  }

  void _editTrip(BuildContext context, Trip trip) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => EditTripScreen(trip: trip)))
        .then((result) {
          if (result == true) {
            // Refresh trips after successful edit
            context.read<TripsProvider>().loadUserTrips();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Trip updated successfully')),
            );
          }
        });
  }

  void _deleteTrip(BuildContext context, Trip trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: Text(
          'Are you sure you want to delete your trip to ${trip.destination}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await context.read<TripsProvider>().deleteTrip(
                trip.id,
              );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Trip deleted successfully')),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.read<TripsProvider>().error ??
                          'Failed to delete trip',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}
