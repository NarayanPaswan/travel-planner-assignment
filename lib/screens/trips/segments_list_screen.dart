import 'package:flutter/material.dart';
import '../../models/trip_segment.dart';
import '../../services/segment_service.dart';
import 'create_segment_screen.dart';
import 'segment_card.dart';

class SegmentsListScreen extends StatefulWidget {
  final String tripId;
  final String tripDestination;

  const SegmentsListScreen({
    Key? key,
    required this.tripId,
    required this.tripDestination,
  }) : super(key: key);

  @override
  State<SegmentsListScreen> createState() => _SegmentsListScreenState();
}

class _SegmentsListScreenState extends State<SegmentsListScreen> {
  final SegmentService _segmentService = SegmentService();
  List<TripSegment> _segments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSegments();
  }

  Future<void> _loadSegments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final segments = await _segmentService.getSegmentsForTrip(widget.tripId);
      setState(() {
        _segments = segments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addSegment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateSegmentScreen(tripId: widget.tripId),
      ),
    );

    if (result == true) {
      // Refresh the segments list
      _loadSegments();
    }
  }

  Future<void> _editSegment(TripSegment segment) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateSegmentScreen(
          tripId: widget.tripId,
          segment: segment,
        ),
      ),
    );

    if (result == true) {
      // Refresh the segments list
      _loadSegments();
    }
  }

  Future<void> _deleteSegment(TripSegment segment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Segment'),
        content: Text(
          'Are you sure you want to delete this ${segment.type.toLowerCase()} segment? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _segmentService.deleteSegment(segment.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Segment deleted successfully!')),
          );
          _loadSegments();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting segment: $e')),
          );
        }
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No segments yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first segment to start planning your trip',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addSegment,
            icon: const Icon(Icons.add),
            label: const Text('Add First Segment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentsList() {
    if (_segments.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _segments.length,
      itemBuilder: (context, index) {
        final segment = _segments[index];
        return SegmentCard(
          segment: segment,
          onEdit: () => _editSegment(segment),
          onDelete: () => _deleteSegment(segment),
        );
      },
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading segments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadSegments,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return _buildSegmentsList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Segments - ${widget.tripDestination}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _loadSegments,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh segments',
          ),
        ],
      ),
      body: _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSegment,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
