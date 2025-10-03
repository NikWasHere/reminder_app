import 'package:flutter/material.dart';
import 'package:reminder_app/screens/schedule_list_screen.dart';
import 'package:reminder_app/screens/add_schedule_screen.dart';
import 'package:reminder_app/screens/account_settings_screen.dart';
import '../database/database_helper.dart';
import '../models/user.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openAccountSettings(BuildContext context) async {
    final db = DatabaseHelper();
    final userData = await db.getUser();
    if (userData != null) {
      final user = User.fromMap(userData);
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AccountSettingsScreen(user: user),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Kelas'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => _openAccountSettings(context),
          ),
        ],
      ),
      body: const ScheduleListScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddScheduleScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
