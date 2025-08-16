import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:intl/intl.dart';
import '../../models/trip.dart';
import '../../models/trip_segment.dart';
import '../../models/expense.dart';

import '../../services/segment_service.dart';
import '../../services/expense_service.dart';
import '../../providers/trips_provider.dart';

import 'create_segment_screen.dart';
import 'create_expense_screen.dart';
import 'edit_trip_screen.dart';
import 'segment_card.dart';
import 'segments_list_screen.dart';
import 'segment_stats_widget.dart';

class TripDetailScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TripSegment> _segments = [];
  List<Expense> _expenses = [];
  bool _isLoading = false;
  double _totalExpenses = 0.0;

  final SegmentService _segmentService = SegmentService();
  final ExpenseService _expenseService = ExpenseService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTripData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTripData() async {
    setState(() => _isLoading = true);
    try {
      final segments = await _segmentService.getSegmentsForTrip(widget.trip.id);
      final expenses = await _expenseService.getExpensesByTrip(widget.trip.id);
      final total = await _expenseService.getTotalExpenses(widget.trip.id);

      setState(() {
        _segments = segments;
        _expenses = expenses;
        _totalExpenses = total;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading trip data: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSegment(String segmentId) async {
    try {
      await _segmentService.deleteSegment(segmentId);
      await _loadTripData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Segment deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting segment: $e')));
      }
    }
  }

  Future<void> _deleteExpense(String expenseId) async {
    try {
      await _expenseService.deleteExpense(expenseId);
      await _loadTripData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting expense: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trip.destination),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EditTripScreen(trip: widget.trip),
                ),
              );
              if (result == true) {
                // Refresh the trip data after successful edit
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => TripDetailScreen(trip: widget.trip),
                  ),
                );
              }
            },
            tooltip: 'Edit Trip',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Segments'),
            Tab(text: 'Expenses'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildSegmentsTab(),
                _buildExpensesTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_tabController.index == 1) {
            // Add segment
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CreateSegmentScreen(tripId: widget.trip.id),
              ),
            );
            if (result == true) {
              _loadTripData();
            }
          } else if (_tabController.index == 2) {
            // Add expense
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CreateExpenseScreen(tripId: widget.trip.id),
              ),
            );
            if (result == true) {
              _loadTripData();
            }
          }
        },
        child: Icon(_tabController.index == 1 ? Icons.add_location : Icons.add),
        tooltip: _tabController.index == 1 ? 'Add Segment' : 'Add Expense',
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trip Image
          if (widget.trip.tripImageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.trip.tripImageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 50),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Trip Details Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trip Details',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Destination', widget.trip.destination),
                  _buildDetailRow(
                    'Duration',
                    '${widget.trip.durationInDays} days',
                  ),
                  _buildDetailRow(
                    'Start Date',
                    DateFormat('MMM dd, yyyy').format(widget.trip.startDate),
                  ),
                  _buildDetailRow(
                    'End Date',
                    DateFormat('MMM dd, yyyy').format(widget.trip.endDate),
                  ),
                  if (widget.trip.description != null &&
                      widget.trip.description!.isNotEmpty)
                    _buildDetailRow('Description', widget.trip.description!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Quick Stats
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(Icons.route, size: 32, color: Colors.blue),
                        const SizedBox(height: 8),
                        Text(
                          '${_segments.length}',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const Text('Segments'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.attach_money,
                          size: 32,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${_totalExpenses.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const Text('Total Expenses'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Segment Statistics
          if (_segments.isNotEmpty) SegmentStatsWidget(segments: _segments),
        ],
      ),
    );
  }

  Widget _buildSegmentsTab() {
    return Column(
      children: [
        // Header with view all button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Trip Segments (${_segments.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_segments.isNotEmpty)
                TextButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SegmentsListScreen(
                          tripId: widget.trip.id,
                          tripDestination: widget.trip.destination,
                        ),
                      ),
                    );
                    if (result == true) {
                      _loadTripData();
                    }
                  },
                  icon: const Icon(Icons.list),
                  label: const Text('View All'),
                ),
            ],
          ),
        ),

        // Segments list or empty state
        Expanded(
          child: _segments.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.route, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No segments yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      Text(
                        'Tap the + button to add your first segment',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _segments.length,
                  itemBuilder: (context, index) {
                    final segment = _segments[index];
                    return SegmentCard(
                      segment: segment,
                      onEdit: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateSegmentScreen(
                              tripId: widget.trip.id,
                              segment: segment,
                            ),
                          ),
                        );
                        if (result == true) {
                          _loadTripData();
                        }
                      },
                      onDelete: () => _showDeleteDialog(
                        'Delete Segment',
                        'Are you sure you want to delete this segment?',
                        () => _deleteSegment(segment.id),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildExpensesTab() {
    if (_expenses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.attach_money, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No expenses yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'Tap the + button to add your first expense',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _expenses.length,
      itemBuilder: (context, index) {
        final expense = _expenses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getExpenseCategoryColor(expense.category),
              child: Icon(
                _getExpenseCategoryIcon(expense.category),
                color: Colors.white,
              ),
            ),
            title: Text(expense.description),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (expense.category != null)
                  Text(expense.category!, style: const TextStyle(fontSize: 12)),
                Text(
                  DateFormat('MMM dd, yyyy').format(expense.createdAt),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${expense.currency} ${expense.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) async {
                    if (value == 'edit') {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CreateExpenseScreen(
                            tripId: widget.trip.id,
                            expense: expense,
                          ),
                        ),
                      );
                      if (result == true) {
                        // Refresh expenses after edit
                        await _loadTripData();
                      }
                    } else if (value == 'delete') {
                      _showDeleteDialog(
                        'Delete Expense',
                        'Are you sure you want to delete this expense?',
                        () => _deleteExpense(expense.id),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
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

  void _showDeleteDialog(String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getSegmentTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'flight':
        return Colors.blue;
      case 'hotel':
        return Colors.green;
      case 'activity':
        return Colors.orange;
      case 'transport':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getSegmentTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'flight':
        return Icons.flight;
      case 'hotel':
        return Icons.hotel;
      case 'activity':
        return Icons.explore;
      case 'transport':
        return Icons.directions_car;
      default:
        return Icons.place;
    }
  }

  Color _getExpenseCategoryColor(String? category) {
    if (category == null) return Colors.grey;
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'transport':
        return Colors.blue;
      case 'accommodation':
        return Colors.green;
      case 'entertainment':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getExpenseCategoryIcon(String? category) {
    if (category == null) return Icons.attach_money;
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'accommodation':
        return Icons.hotel;
      case 'entertainment':
        return Icons.movie;
      default:
        return Icons.attach_money;
    }
  }
}
