import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/database.dart';
import '../services/notification_service.dart';

class EditScheduleScreen extends StatefulWidget {
  final int scheduleId;

  const EditScheduleScreen({super.key, required this.scheduleId});

  @override
  State<EditScheduleScreen> createState() => _EditScheduleScreenState();
}

class _EditScheduleScreenState extends State<EditScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _courseNameController = TextEditingController();
  final _lecturerController = TextEditingController();
  final _roomController = TextEditingController();

  String _selectedDay = 'Monday';
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 9, minute: 30);
  bool _isLoading = true;
  Schedule? _schedule;

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final AppDatabase _database = AppDatabase();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _lecturerController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _loadSchedule() async {
    final schedule = await _database.getScheduleById(widget.scheduleId);
    if (schedule != null) {
      setState(() {
        _schedule = schedule;
        _courseNameController.text = schedule.courseName;
        _lecturerController.text = schedule.lecturer;
        _roomController.text = schedule.room;
        _selectedDay = schedule.day;

        final startTimeParts = schedule.startTime.split(':');
        _startTime = TimeOfDay(
          hour: int.parse(startTimeParts[0]),
          minute: int.parse(startTimeParts[1]),
        );

        final endTimeParts = schedule.endTime.split(':');
        _endTime = TimeOfDay(
          hour: int.parse(endTimeParts[0]),
          minute: int.parse(endTimeParts[1]),
        );

        _isLoading = false;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _updateSchedule() async {
    if (_formKey.currentState!.validate() && _schedule != null) {
      final updatedSchedule = _schedule!.copyWith(
        courseName: _courseNameController.text,
        lecturer: _lecturerController.text,
        room: _roomController.text,
        day: _selectedDay,
        startTime: _formatTimeOfDay(_startTime),
        endTime: _formatTimeOfDay(_endTime),
      );

      await _database.updateSchedule(updatedSchedule);

      // Cancel old notification and schedule new one
      await _notificationService.cancelClassReminder(widget.scheduleId);
      await _notificationService.scheduleClassReminder(
        id: widget.scheduleId,
        courseName: _courseNameController.text,
        lecturer: _lecturerController.text,
        room: _roomController.text,
        day: _selectedDay,
        startTime: _formatTimeOfDay(_startTime),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule updated successfully')),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_schedule == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Schedule Not Found')),
        body: const Center(child: Text('Schedule not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Class Schedule')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _courseNameController,
                decoration: const InputDecoration(
                  labelText: 'Course Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the course name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lecturerController,
                decoration: const InputDecoration(
                  labelText: 'Lecturer',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the lecturer name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _roomController,
                decoration: const InputDecoration(
                  labelText: 'Room',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the room';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedDay,
                decoration: const InputDecoration(
                  labelText: 'Day',
                  border: OutlineInputBorder(),
                ),
                items: _days.map((String day) {
                  return DropdownMenuItem<String>(value: day, child: Text(day));
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedDay = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _selectTime(context, true),
                      child: Text(
                        'Start Time: ${_formatTimeOfDay(_startTime)}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _selectTime(context, false),
                      child: Text('End Time: ${_formatTimeOfDay(_endTime)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _updateSchedule,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Update Schedule'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
