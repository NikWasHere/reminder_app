import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'schedule_list_screen.dart';
import 'assignment_list_screen.dart';
import '../data/database.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openAccountSettings() async {
    final database = AppDatabase();
    final user = await database.getUser();
    if (user != null && mounted) {
      context.push('/home/account-settings', extra: user);
    }
  }

  void _addNewItem() {
    if (_currentIndex == 0) {
      // Add schedule
      context.push('/home/add-schedule');
    } else {
      // Add assignment
      context.push('/home/add-assignment');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder App'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: _openAccountSettings,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.schedule), text: 'Schedules'),
            Tab(icon: Icon(Icons.assignment), text: 'Assignments'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [ScheduleListScreen(), AssignmentListScreen()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewItem,
        child: const Icon(Icons.add),
      ),
    );
  }
}
