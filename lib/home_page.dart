import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard/dashboard.dart';
import 'attendance/attendance_page.dart';
import 'leave/leave_home_page.dart';
import 'profile/profile_page.dart';
import 'insights/insights_page.dart';
import 'controllers/profile_controller.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 2;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    final screens = [
      AttendancePage(),
      LeavePage(),
      const Dashboard(),
      const InsightsPage(),
      const ProfilePage(),
    ];

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        body: Center(child: Text('Error: $err')),
      ),
      data: (profile) {
        final fullName = profile?.fullName ?? "User";

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF4CBFDA),
            title: const Text(
              "ClockEase",
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            selectedItemColor: const Color(0xFF3470D9),
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today),
                label: "Attendance",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.beach_access),
                label: "Leaves",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.insights),
                label: "Insights",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: "Profile",
              ),
            ],
          ),
        );
      },
    );
  }
}