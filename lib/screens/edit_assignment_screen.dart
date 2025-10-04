import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../data/database.dart';
import '../services/notification_service.dart';

class EditAssignmentScreen extends StatefulWidget {
  final int assignmentId;

  const EditAssignmentScreen({super.key, required this.assignmentId});

  @override
  State<EditAssignmentScreen> createState() => _EditAssignmentScreenState();
}

class _EditAssignmentScreenState extends State<EditAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _courseNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 23, minute: 59);
  bool _isLoading = true;
  Assignment? _assignment;

  final AppDatabase _database = AppDatabase();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadAssignment();
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadAssignment() async {
    final assignment = await _database.getAssignmentById(widget.assignmentId);
    if (assignment != null) {
      setState(() {
        _assignment = assignment;
        _courseNameController.text = assignment.courseName;
        _descriptionController.text = assignment.description;
        _selectedDate = assignment.dueDate;
        _selectedTime = TimeOfDay.fromDateTime(assignment.dueDate);
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  Future<void> _updateAssignment() async {
    if (_formKey.currentState!.validate() && _assignment != null) {
      final dueDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final updatedAssignment = _assignment!.copyWith(
        courseName: _courseNameController.text,
        description: _descriptionController.text,
        dueDate: dueDate,
      );

      await _database.updateAssignment(updatedAssignment);

      // Cancel old notifications and schedule new ones
      await _notificationService.cancelAssignmentReminders(widget.assignmentId);
      if (!updatedAssignment.isCompleted) {
        await _notificationService.scheduleAssignmentReminders(
          assignmentId: widget.assignmentId,
          courseName: _courseNameController.text,
          description: _descriptionController.text,
          dueDate: dueDate,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment updated successfully')),
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

    if (_assignment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Assignment Not Found')),
        body: const Center(child: Text('Assignment not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Assignment')),
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
                  prefixIcon: Icon(Icons.book),
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
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Assignment Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.assignment),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the assignment description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Due Date & Time',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selectDate,
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                DateFormat(
                                  'MMM dd, yyyy',
                                ).format(_selectedDate),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selectTime,
                              icon: const Icon(Icons.access_time),
                              label: Text(_selectedTime.format(context)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _updateAssignment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Update Assignment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
