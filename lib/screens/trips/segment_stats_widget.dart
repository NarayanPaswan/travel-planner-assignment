import 'package:flutter/material.dart';
import '../../models/trip_segment.dart';

class SegmentStatsWidget extends StatelessWidget {
  final List<TripSegment> segments;

  const SegmentStatsWidget({Key? key, required this.segments})
    : super(key: key);

  Map<String, int> _getSegmentTypeCounts() {
    final counts = <String, int>{};
    for (final segment in segments) {
      counts[segment.type] = (counts[segment.type] ?? 0) + 1;
    }
    return counts;
  }

  int _getSegmentsWithTime() {
    return segments
        .where(
          (segment) => segment.startTime != null || segment.endTime != null,
        )
        .length;
  }

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) {
      return const SizedBox.shrink();
    }

    final typeCounts = _getSegmentTypeCounts();
    final segmentsWithTime = _getSegmentsWithTime();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Segment Statistics',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Total segments
            Row(
              children: [
                const Icon(Icons.list_alt, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Total Segments: ${segments.length}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Segments with time
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'With Time: $segmentsWithTime',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Segment types breakdown
            if (typeCounts.isNotEmpty) ...[
              Text(
                'Segment Types:',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: typeCounts.entries.map((entry) {
                  return Chip(
                    label: Text('${entry.key}: ${entry.value}'),
                    backgroundColor: _getTypeColor(entry.key).withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: _getTypeColor(entry.key),
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'flight':
        return Colors.blue;
      case 'hotel':
        return Colors.green;
      case 'activity':
        return Colors.orange;
      case 'transport':
        return Colors.purple;
      case 'restaurant':
        return Colors.red;
      case 'meeting':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}
