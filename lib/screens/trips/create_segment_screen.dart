import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/trip_segment.dart';
import '../../services/segment_service.dart';
import '../../providers/auth_provider.dart';

class CreateSegmentScreen extends StatefulWidget {
  final String tripId;
  final TripSegment? segment; // If provided, we're editing

  const CreateSegmentScreen({Key? key, required this.tripId, this.segment})
    : super(key: key);

  @override
  State<CreateSegmentScreen> createState() => _CreateSegmentScreenState();
}

class _CreateSegmentScreenState extends State<CreateSegmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _segmentService = SegmentService();

  String _selectedType = 'Activity';
  final _detailsController = TextEditingController();
  DateTime? _startTime;
  DateTime? _endTime;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.segment != null) {
      // Editing existing segment
      _selectedType = widget.segment!.type;
      _detailsController.text = widget.segment!.details ?? '';
      _startTime = widget.segment!.startTime;
      _endTime = widget.segment!.endTime;
    }
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(bool isStartTime) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isStartTime
          ? (_startTime ?? DateTime.now())
          : (_endTime ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: isStartTime
            ? (_startTime != null
                  ? TimeOfDay.fromDateTime(_startTime!)
                  : TimeOfDay.now())
            : (_endTime != null
                  ? TimeOfDay.fromDateTime(_endTime!)
                  : TimeOfDay.now()),
      );

      if (pickedTime != null) {
        setState(() {
          final combinedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );

          if (isStartTime) {
            _startTime = combinedDateTime;
            // If end time is before new start time, clear it
            if (_endTime != null && _endTime!.isBefore(combinedDateTime)) {
              _endTime = null;
            }
          } else {
            _endTime = combinedDateTime;
          }
        });
      }
    }
  }

  Future<void> _saveSegment() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate time logic
    if (_startTime != null &&
        _endTime != null &&
        _endTime!.isBefore(_startTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time cannot be before start time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // If editing, show confirmation dialog
    if (widget.segment != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Update Segment'),
          content: const Text('Are you sure you want to update this segment?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Update'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = context.read<AuthProvider>().currentUser;
      if (user == null) throw Exception('User not authenticated');

      final segment = TripSegment(
        id: widget.segment?.id ?? '',
        tripId: widget.tripId,
        userId: user.id,
        type: _selectedType,
        details: _detailsController.text.trim().isEmpty
            ? null
            : _detailsController.text.trim(),
        startTime: _startTime,
        endTime: _endTime,
        createdAt: widget.segment?.createdAt ?? DateTime.now(),
      );

      if (widget.segment != null) {
        // Update existing segment
        await _segmentService.updateSegment(segment);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Segment updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Create new segment
        await _segmentService.createSegment(segment);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Segment created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetToOriginal() {
    if (widget.segment != null) {
      setState(() {
        _selectedType = widget.segment!.type;
        _detailsController.text = widget.segment!.details ?? '';
        _startTime = widget.segment!.startTime;
        _endTime = widget.segment!.endTime;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset to original values'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.segment != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Segment' : 'Create Segment'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Segment Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Segment Type',
                  border: OutlineInputBorder(),
                ),
                items: TripSegment.segmentTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a segment type';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Details Text Field
              TextFormField(
                controller: _detailsController,
                decoration: const InputDecoration(
                  labelText: 'Details (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Enter segment details...',
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              // Start Time
              ListTile(
                title: const Text('Start Time'),
                subtitle: Text(
                  _startTime != null
                      ? '${_startTime!.toLocal().toString().split('.')[0]}'
                      : 'Not set',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_startTime != null)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _startTime = null;
                            // If end time is now before start time, clear it too
                            if (_endTime != null &&
                                _endTime!.isBefore(DateTime.now())) {
                              _endTime = null;
                            }
                          });
                        },
                        icon: const Icon(Icons.clear, size: 18),
                        tooltip: 'Clear start time',
                        color: Colors.red,
                      ),
                    const Icon(Icons.access_time),
                  ],
                ),
                onTap: () => _selectDateTime(true),
                tileColor: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),

              const SizedBox(height: 8),

              // End Time
              ListTile(
                title: const Text('End Time'),
                subtitle: Text(
                  _endTime != null
                      ? '${_endTime!.toLocal().toString().split('.')[0]}'
                      : 'Not set',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_endTime != null)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _endTime = null;
                          });
                        },
                        icon: const Icon(Icons.clear, size: 18),
                        tooltip: 'Clear end time',
                        color: Colors.red,
                      ),
                    const Icon(Icons.access_time),
                  ],
                ),
                onTap: () => _selectDateTime(false),
                tileColor: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  if (isEditing) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _resetToOriginal,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Reset to Original'),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveSegment,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isEditing ? 'Update Segment' : 'Create Segment',
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
