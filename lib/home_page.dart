import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard/dashboard.dart';   // your dashboard file

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 2;  // Center tab = Dashboard

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? "User";

    // Screens for each navigation tab
    final screens = [
      Center(child: Text("Attendance Page")),
      Center(child: Text("Leave Application Page")),
      Dashboard(userEmail: email),
      Center(child: Text("Insights Page")),
      Center(child: Text("Profile Page")),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CBFDA),
        title: const Text(
          'ClockEase',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),

      body: screens[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF3470D9),
        unselectedItemColor: Colors.grey,

        onTap: (index) {
          setState(() => _currentIndex = index);
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "Attendance",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.beach_access),
            label: "Leave",
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
  }
}
