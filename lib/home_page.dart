import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard/dashboard.dart';
import 'services/user_service.dart';
import 'attendance/attendance_page.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 2;
  String? fullName;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final data = await UserService().getEmployeeProfile();
    setState(() {
      fullName = data?["fullName"] ?? "User";
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screens = [
      const AttendancePage(),
      const Center(child: Text("Leave Application Page")),
      const Dashboard(), 
      const Center(child: Text("Insights Page")),
      const Center(child: Text("Profile Page")),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CBFDA),
        title: const Text("ClockEase", style: TextStyle(color: Colors.white)),
      ),

      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: const Color(0xFF3470D9),
        unselectedItemColor: Colors.grey,

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Attendance"),
          BottomNavigationBarItem(icon: Icon(Icons.beach_access), label: "Leave"),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.insights), label: "Insights"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
