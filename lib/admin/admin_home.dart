import 'package:flutter/material.dart';

import 'dashboard/admin_dashboard.dart';
import 'leave/leave_approval_page.dart';
import 'staff/staff_management_page.dart';

class AdminHome extends StatefulWidget {
  final String companyId;

  const AdminHome({
    super.key,
    required this.companyId,
  });

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      AdminDashboard(companyId: widget.companyId),
      LeaveApprovalPage(companyId: widget.companyId),
      StaffManagementPage(companyId: widget.companyId),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ======================
      // FIXED ADMIN APP BAR
      // ======================
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CBFDA),
        title: const Text(
          "ClockEase (Admin Panel)",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Back to Staff',
          onPressed: () {
            Navigator.pop(context); // 👈 BACK TO STAFF MODE
          },
        ),
      ),

      // ======================
      // BODY
      // ======================
      body: _screens[_currentIndex],

      // ======================
      // BOTTOM NAV (ADMIN)
      // ======================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: const Color(0xFF3470D9),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.approval),
            label: "Leave",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: "Staff",
          ),
        ],
      ),
    );
  }
}
