import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../screens/registration_screen.dart';
import '../screens/home_screen.dart';
import '../screens/schedule_list_screen.dart';
import '../screens/add_schedule_screen.dart';
import '../screens/edit_schedule_screen.dart';
import '../screens/assignment_list_screen.dart';
import '../screens/add_assignment_screen.dart';
import '../screens/edit_assignment_screen.dart';
import '../screens/account_settings_screen.dart';
import '../services/database_service.dart';
import '../data/database.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegistrationScreen(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: '/schedules',
          name: 'schedules',
          builder: (context, state) => const ScheduleListScreen(),
        ),
        GoRoute(
          path: '/add-schedule',
          name: 'add-schedule',
          builder: (context, state) => const AddScheduleScreen(),
        ),
        GoRoute(
          path: '/edit-schedule/:id',
          name: 'edit-schedule',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return EditScheduleScreen(scheduleId: id);
          },
        ),
        GoRoute(
          path: '/assignments',
          name: 'assignments',
          builder: (context, state) => const AssignmentListScreen(),
        ),
        GoRoute(
          path: '/add-assignment',
          name: 'add-assignment',
          builder: (context, state) => const AddAssignmentScreen(),
        ),
        GoRoute(
          path: '/edit-assignment/:id',
          name: 'edit-assignment',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return EditAssignmentScreen(assignmentId: id);
          },
        ),
        GoRoute(
          path: '/account-settings',
          name: 'account-settings',
          builder: (context, state) {
            final user = state.extra as User;
            return AccountSettingsScreen(user: user);
          },
        ),
      ],
    ),
  ],
);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    final database = DatabaseService().database;
    final hasUser = await database.hasUser();

    if (mounted) {
      if (hasUser) {
        context.go('/home');
      } else {
        context.go('/register');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
