import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/shooting_data.dart';
import '../../providers/shooting_provider.dart';
import '../../providers/trips_provider.dart';
import '../../providers/auth_provider.dart';

class AddShootingDataScreen extends StatefulWidget {
  const AddShootingDataScreen({super.key});

  @override
  State<AddShootingDataScreen> createState() => _AddShootingDataScreenState();
}

class _AddShootingDataScreenState extends State<AddShootingDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _equipmentController = TextEditingController();
  final _notesController = TextEditingController();
  final _weatherController = TextEditingController();

  String _selectedTargetType = 'static';
  String? _selectedTripId;
  DateTime _selectedDate = DateTime.now();
  int _distanceMeters = 100;
  int _shotsFired = 0;
  int _shotsHit = 0;
  double? _windSpeed;
  double? _temperature;

  List<Map<String, dynamic>> _availableTrips = [];

  final List<String> _targetTypes = [
    'static',
    'moving',
    'long_range',
    'close_range',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTrips();
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    _equipmentController.dispose();
    _notesController.dispose();
    _weatherController.dispose();
    super.dispose();
  }

  Future<void> _loadTrips() async {
    final tripsProvider = context.read<TripsProvider>();
    await tripsProvider.loadAllTrips();

    setState(() {
      _availableTrips = tripsProvider.trips
          .map(
            (trip) => {
              'id': trip.id,
              'title': trip.destination,
              'destination': trip.destination,
            },
          )
          .toList();

      if (_availableTrips.isNotEmpty) {
        _selectedTripId = _availableTrips.first['id'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Shooting Data'), elevation: 0),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Shooting Session',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Trip Selection
              _buildTripDropdown(),
              const SizedBox(height: 16),

              // Date Selection
              _buildDateField(),
              const SizedBox(height: 16),

              // Location
              _buildTextField(
                controller: _locationController,
                label: 'Location',
                hint: 'e.g., Mountain Range, Forest Area',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Target Type
              _buildTargetTypeDropdown(),
              const SizedBox(height: 16),

              // Distance
              _buildDistanceField(),
              const SizedBox(height: 16),

              // Shots
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(
                      label: 'Shots Fired',
                      value: _shotsFired,
                      onChanged: (value) => setState(() => _shotsFired = value),
                      validator: (value) {
                        if (value <= 0) {
                          return 'Must be greater than 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildNumberField(
                      label: 'Shots Hit',
                      value: _shotsHit,
                      onChanged: (value) => setState(() => _shotsHit = value),
                      validator: (value) {
                        if (value < 0) {
                          return 'Cannot be negative';
                        }
                        if (value > _shotsFired) {
                          return 'Cannot exceed shots fired';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Weather Conditions
              _buildTextField(
                controller: _weatherController,
                label: 'Weather Conditions',
                hint: 'e.g., Clear, Cloudy, Rainy',
              ),
              const SizedBox(height: 16),

              // Wind Speed and Temperature
              Row(
                children: [
                  Expanded(
                    child: _buildDoubleField(
                      label: 'Wind Speed (km/h)',
                      value: _windSpeed,
                      onChanged: (value) => setState(() => _windSpeed = value),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDoubleField(
                      label: 'Temperature (°C)',
                      value: _temperature,
                      onChanged: (value) =>
                          setState(() => _temperature = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Equipment
              _buildTextField(
                controller: _equipmentController,
                label: 'Equipment Used',
                hint: 'e.g., Rifle, Scope, Bipod',
              ),
              const SizedBox(height: 16),

              // Notes
              _buildTextField(
                controller: _notesController,
                label: 'Notes',
                hint: 'Additional observations or comments',
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Add Shooting Session',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedTripId,
      decoration: const InputDecoration(
        labelText: 'Trip',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.flight),
      ),
      items: _availableTrips.map((trip) {
        return DropdownMenuItem<String>(
          value: trip['id'] as String,
          child: Text('${trip['title']} - ${trip['destination']}'),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedTripId = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a trip';
        }
        return null;
      },
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Shooting Date',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          DateFormat('MMM dd, yyyy').format(_selectedDate),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildTargetTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedTargetType,
      decoration: const InputDecoration(
        labelText: 'Target Type',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.track_changes),
      ),
      items: _targetTypes.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(type.replaceAll('_', ' ').toUpperCase()),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedTargetType = value!;
        });
      },
    );
  }

  Widget _buildDistanceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distance: ${_distanceMeters} meters',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Slider(
          value: _distanceMeters.toDouble(),
          min: 10,
          max: 1000,
          divisions: 99,
          label: '${_distanceMeters}m',
          onChanged: (value) {
            setState(() {
              _distanceMeters = value.round();
            });
          },
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    String? Function(int)? validator,
  }) {
    return TextFormField(
      initialValue: value.toString(),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.gps_fixed),
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        final intValue = int.tryParse(value) ?? 0;
        onChanged(intValue);
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a value';
        }
        final intValue = int.tryParse(value);
        if (intValue == null) {
          return 'Please enter a valid number';
        }
        if (validator != null) {
          return validator(intValue);
        }
        return null;
      },
    );
  }

  Widget _buildDoubleField({
    required String label,
    required double? value,
    required ValueChanged<double?> onChanged,
  }) {
    return TextFormField(
      initialValue: value?.toString() ?? '',
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.speed),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (value) {
        final doubleValue = double.tryParse(value);
        onChanged(doubleValue);
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(_getFieldIcon(label)),
      ),
      maxLines: maxLines,
      validator: validator,
    );
  }

  IconData _getFieldIcon(String label) {
    switch (label.toLowerCase()) {
      case 'location':
        return Icons.location_on;
      case 'equipment used':
        return Icons.build;
      case 'notes':
        return Icons.note;
      case 'weather conditions':
        return Icons.cloud;
      default:
        return Icons.edit;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTripId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a trip')));
      return;
    }

    try {
      final shootingData = ShootingData(
        id: '', // Will be generated by the database
        userId: context.read<AuthProvider>().currentUser?.id ?? '',
        tripId: _selectedTripId!,
        shootingDate: _selectedDate,
        location: _locationController.text.trim(),
        targetType: _selectedTargetType,
        distanceMeters: _distanceMeters,
        shotsFired: _shotsFired,
        shotsHit: _shotsHit,
        accuracyPercentage: _shotsFired > 0
            ? (_shotsHit / _shotsFired) * 100
            : 0,
        weatherConditions: _weatherController.text.trim().isEmpty
            ? null
            : _weatherController.text.trim(),
        windSpeedKmh: _windSpeed,
        temperatureCelsius: _temperature,
        equipmentUsed: _equipmentController.text.trim().isEmpty
            ? null
            : _equipmentController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await context.read<ShootingProvider>().createShootingData(
        shootingData,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shooting session added successfully!')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add shooting session')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
