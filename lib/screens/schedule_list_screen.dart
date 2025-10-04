import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/database.dart';
import '../services/notification_service.dart';
import '../services/database_service.dart';

class ScheduleListScreen extends StatefulWidget {
  const ScheduleListScreen({super.key});

  @override
  State<ScheduleListScreen> createState() => _ScheduleListScreenState();
}

class _ScheduleListScreenState extends State<ScheduleListScreen> {
  late final AppDatabase _database;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _database = DatabaseService().database;
  }

  String _selectedDay = 'Monday';
  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: DropdownButton<String>(
            value: _selectedDay,
            isExpanded: true,
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
        ),
        Expanded(
          child: StreamBuilder<List<Schedule>>(
            stream: _database.watchSchedulesByDay(_selectedDay),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.schedule, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('No classes scheduled for $_selectedDay'),
                    ],
                  ),
                );
              }

              final schedules = snapshot.data!;
              return ListView.builder(
                itemCount: schedules.length,
                itemBuilder: (context, index) {
                  final schedule = schedules[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.schedule, color: Colors.blue),
                      title: Text(schedule.courseName),
                      subtitle: Text(
                        '${schedule.lecturer}\n${schedule.room}\n${schedule.startTime} - ${schedule.endTime}',
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              context.push(
                                '/home/edit-schedule/${schedule.id}',
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteSchedule(schedule),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _deleteSchedule(Schedule schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: Text(
          'Are you sure you want to delete "${schedule.courseName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _notificationService.cancelClassReminder(schedule.id);
      await _database.deleteSchedule(schedule.id);
    }
  }
}
