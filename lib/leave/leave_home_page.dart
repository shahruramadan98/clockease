import 'package:flutter/material.dart';

class LeavePage extends StatelessWidget {
  const LeavePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Leave Application",
          style: TextStyle(color: Color(0xFF3F51B5)), // Apply color to text
        ),
        backgroundColor: Colors.white, // Set background to white
        elevation: 0, // Remove shadow for a clean look
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications,
              color: Color(0xFF3F51B5), // Change icon color to match text
            ),
            onPressed: () {
              // Handle notifications if any
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leave Balances Section
              LeaveBalancesSection(),

              const SizedBox(height: 20),

              // Upcoming Leave Section (Separate Card)
              UpcomingLeaveSection(buildLeaveCard: _buildLeaveCard),

              const SizedBox(height: 20),

              // Pending Requests Section (Separate Card)
              PendingLeaveSection(buildLeaveCard: _buildLeaveCard),

              const SizedBox(height: 20),

              // Past Leave Section (Separate Card)
              PastLeaveSection(buildLeaveCard: _buildLeaveCard),

              const SizedBox(height: 20),

              // Add Floating Action Button for "Apply for Leave"
              Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  onPressed: () {
                    // Navigate to leave application form
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LeaveApplicationForm()),
                    );
                  },
                  backgroundColor: const Color(0xFF3BAECC), // Blue background
                  child: const Icon(
                    Icons.add,
                    color: Colors.white, // White icon color
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Shared helper method for building leave cards
  Widget _buildLeaveCard(String leaveType, String date, String status, Color statusColor) {
    return Card(
      color: Color(0xFF3BAECC),  // Lighter blue color for leave cards
      child: ListTile(
        title: Text(leaveType, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(date, style: const TextStyle(color: Colors.white)),
        trailing: Chip(
          label: Text(
            status,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: statusColor,
        ),
      ),
    );
  }
}


// Leave Balances Section Widget
// Leave Balances Section Widget
class LeaveBalancesSection extends StatelessWidget {
  const LeaveBalancesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      color: const Color(0xFF3BAECC), // Background color of leave balances section
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Leave Balances",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Annual Leave Progress Bar
            _buildLeaveBalanceCard("Annual Leave", 15, 0.4, true), // Progress bar here for annual leave

            const SizedBox(height: 10),
            // Line separator between the sections
            Divider(
              color: Colors.white.withOpacity(0.5), // Light white line for separator
            ),

            // Sick Leave and Unpaid Leave without progress bar, aligned next to each other
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLeaveBalanceCard("Sick Leave", 7, 0.0, false), // No progress bar here
                _buildLeaveBalanceCard("Unpaid Leave", 0, 0.0, false), // No progress bar here
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget to build each leave balance card with or without a progress bar
  Widget _buildLeaveBalanceCard(String leaveType, int daysLeft, double progress, bool showProgress) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), // Adjusted padding
      decoration: BoxDecoration(
        color: Colors.transparent, // No background for each card
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            leaveType,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "$daysLeft days",
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 4),
          // Show progress bar only for Annual Leave
          if (showProgress)
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // White color for progress
              minHeight: 8.0,
            ),
        ],
      ),
    );
  }
}





// Upcoming Leave Section Widget (Updated Annual Leave design with dual-tone gradient)
class UpcomingLeaveSection extends StatelessWidget {
  final Widget Function(String, String, String, Color) buildLeaveCard;

  const UpcomingLeaveSection({super.key, required this.buildLeaveCard});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Adjust padding to be consistent
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Upcoming Leave",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Color(0xFF3BAECC), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          // Set height and width to match Pending Requests section
          SizedBox(
            width: double.infinity,  // Ensure the width is consistent across sections
            height: 90, // Adjusted height to match size of Pending Requests card
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6BD5E1), // Light aqua
                    Color(0xFF3A7BD5), // Blue
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side: Leave details (leave type and date)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Annual Leave",
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Nov 20, 2025 - Nov 22, 2025",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  // Right side: Status chip (Approved status)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green, // Green color for 'Approved' status button
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Approved",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// Pending Leave Section Widget (Updated design to match the image)
class PendingLeaveSection extends StatelessWidget {
  final Widget Function(String, String, String, Color) buildLeaveCard;

  const PendingLeaveSection({super.key, required this.buildLeaveCard});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Adjust padding to match Upcoming Leave section
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Pending Requests",
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: Color(0xFF3BAECC), fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          // Updated Sick Leave card with dual-tone gradient background
          SizedBox(
            width: double.infinity, // Ensure the width is consistent across sections
            height: 90, // Adjusted height to match the Upcoming Leave card size
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6BD5E1), // Light aqua
                    Color(0xFF3A7BD5), // Blue
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side: Leave details (leave type and date)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Sick Leave",
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Oct 30, 2025 - Oct 30, 2025",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  // Right side: Status chip (Pending status)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFFB0F39A), // Light green color for Pending status
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Pending",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// Past Leave Section Widget (Ensuring same size for "Taken" and "Pending" buttons)
class PastLeaveSection extends StatelessWidget {
  final Widget Function(String, String, String, Color) buildLeaveCard;

  const PastLeaveSection({super.key, required this.buildLeaveCard});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Past Leave",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Color(0xFF3BAECC), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          // Design based on Picture 1
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF6BD5E1), // Light aqua
                  Color(0xFF3A7BD5), // Blue
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side: Leave details (leave type and date)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Annual Leave",
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Sept 16, 2025 - Sept 18, 2025",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                // Right side: Status chip (Taken status with consistent size as Pending)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6), // Same padding for size consistency
                  decoration: BoxDecoration(
                    color: Colors.grey, // Grey for 'Taken' status
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Taken",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// Leave Application Form Screen
class LeaveApplicationForm extends StatefulWidget {
  const LeaveApplicationForm({super.key});

  @override
  _LeaveApplicationFormState createState() => _LeaveApplicationFormState();
}

class _LeaveApplicationFormState extends State<LeaveApplicationForm> {
  String? selectedLeaveType = 'Annual'; // Default leave type
  DateTime? startDate;
  DateTime? endDate;

  // Controller for date fields
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Leave Application Form")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Leave Type",
              style: TextStyle(fontSize: 18),
            ),
            // Dropdown for Leave Type
            DropdownButton<String>(
              isExpanded: true,
              value: selectedLeaveType,
              items: <String>['Annual', 'Sick', 'Emergency']
                  .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedLeaveType = value;
                });
              },
            ),
            const SizedBox(height: 20),
            const Text(
              "Start Date",
              style: TextStyle(fontSize: 18),
            ),
            // TextField for Start Date with Date Picker
            TextField(
              controller: startDateController,
              readOnly: true,
              decoration: InputDecoration(
                hintText: "Select Start Date",
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () async {
                DateTime? selectedDate = await showDatePicker(
                  context: context,
                  initialDate: startDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2101),
                );
                if (selectedDate != null) {
                  setState(() {
                    startDate = selectedDate;
                    startDateController.text = '${selectedDate.toLocal()}'.split(' ')[0]; // Format date as YYYY-MM-DD
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            const Text(
              "End Date",
              style: TextStyle(fontSize: 18),
            ),
            // TextField for End Date with Date Picker
            TextField(
              controller: endDateController,
              readOnly: true,
              decoration: InputDecoration(
                hintText: "Select End Date",
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () async {
                DateTime? selectedDate = await showDatePicker(
                  context: context,
                  initialDate: endDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2101),
                );
                if (selectedDate != null) {
                  setState(() {
                    endDate = selectedDate;
                    endDateController.text = '${selectedDate.toLocal()}'.split(' ')[0]; // Format date as YYYY-MM-DD
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            // Submit Button
            ElevatedButton(
              onPressed: () {
                // Submit leave request
                // Handle the submit action here, e.g., save the form data
              },
              child: const Text("Submit Leave Request"),
            ),
          ],
        ),
      ),
    );
  }
}