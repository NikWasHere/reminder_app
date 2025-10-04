import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../data/database.dart';
import '../services/notification_service.dart';

class AssignmentListScreen extends StatefulWidget {
  const AssignmentListScreen({super.key});

  @override
  State<AssignmentListScreen> createState() => _AssignmentListScreenState();
}

class _AssignmentListScreenState extends State<AssignmentListScreen> {
  final AppDatabase _database = AppDatabase();
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assignment Deadlines')),
      body: StreamBuilder<List<Assignment>>(
        stream: _database.watchUpcomingAssignments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No upcoming assignments'));
          }

          final assignments = snapshot.data!;
          return ListView.builder(
            itemCount: assignments.length,
            itemBuilder: (context, index) {
              final assignment = assignments[index];
              final isOverdue =
                  assignment.dueDate.isBefore(DateTime.now()) &&
                  !assignment.isCompleted;
              final daysUntil = assignment.dueDate
                  .difference(DateTime.now())
                  .inDays;

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                color: isOverdue
                    ? Colors.red.shade50
                    : assignment.isCompleted
                    ? Colors.green.shade50
                    : null,
                child: ListTile(
                  leading: Icon(
                    assignment.isCompleted
                        ? Icons.check_circle
                        : isOverdue
                        ? Icons.warning
                        : Icons.assignment,
                    color: assignment.isCompleted
                        ? Colors.green
                        : isOverdue
                        ? Colors.red
                        : Colors.blue,
                  ),
                  title: Text(
                    assignment.description,
                    style: TextStyle(
                      decoration: assignment.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(assignment.courseName),
                      Text(
                        'Due: ${DateFormat('MMM dd, yyyy - HH:mm').format(assignment.dueDate)}',
                        style: TextStyle(
                          color: isOverdue ? Colors.red : null,
                          fontWeight: isOverdue ? FontWeight.bold : null,
                        ),
                      ),
                      if (!assignment.isCompleted && !isOverdue)
                        Text(
                          daysUntil == 0
                              ? 'Due today'
                              : daysUntil == 1
                              ? 'Due tomorrow'
                              : 'Due in $daysUntil days',
                          style: TextStyle(
                            color: daysUntil <= 1
                                ? Colors.orange
                                : Colors.grey.shade600,
                            fontWeight: daysUntil <= 1 ? FontWeight.bold : null,
                          ),
                        ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!assignment.isCompleted)
                        IconButton(
                          icon: const Icon(Icons.check),
                          onPressed: () => _markCompleted(assignment),
                          tooltip: 'Mark as completed',
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => context.push(
                          '/home/edit-assignment/${assignment.id}',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteAssignment(assignment),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/home/add-assignment'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _markCompleted(Assignment assignment) async {
    await _database.markAssignmentCompleted(assignment.id);
    await _notificationService.cancelAssignmentReminders(assignment.id);
  }

  Future<void> _deleteAssignment(Assignment assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assignment'),
        content: Text(
          'Are you sure you want to delete "${assignment.description}"?',
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
      await _notificationService.cancelAssignmentReminders(assignment.id);
      await _database.deleteAssignment(assignment.id);
    }
  }
}
