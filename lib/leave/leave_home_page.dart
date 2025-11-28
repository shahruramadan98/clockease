import 'package:flutter/material.dart';
import 'leave_application_page.dart';

class LeaveHomePage extends StatelessWidget {
  LeaveHomePage({super.key});

  final List<Map<String, dynamic>> mockUpcoming = [
    {"type": "Annual Leave", "date": "23 Feb 2025"},
  ];

  final List<Map<String, dynamic>> mockPending = [
    {"type": "Sick Leave", "date": "10 Jan 2025"},
  ];

  final List<Map<String, dynamic>> mockPast = [
    {"type": "Emergency Leave", "date": "3 Jan 2025"},
    {"type": "Annual Leave", "date": "20 Dec 2024"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     floatingActionButton: FloatingActionButton(
  backgroundColor: Color(0xFF3470D9),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LeaveApplicationPage()),
    );
  },
  child: Icon(Icons.add, color: Colors.white),
),


      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _buildHeader(context),

            SizedBox(height: 25),
            _buildLeaveBalanceCard(),

            SizedBox(height: 30),
            _sectionTitle("Upcoming Leave"),
            _buildList(mockUpcoming),

            SizedBox(height: 25),
            _sectionTitle("Pending Leave"),
            _buildList(mockPending),

            SizedBox(height: 25),
            _sectionTitle("Past Leave"),
            _buildList(mockPast),

            SizedBox(height: 70),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Employee ID: 1583",
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            SizedBox(height: 4),
            Text("Ali Najmi",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.grey.shade300,
          child: Icon(Icons.person, color: Colors.white),
        )
      ],
    );
  }

  Widget _buildLeaveBalanceCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF4CBFDA),
            Color(0xFF3470D9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: Offset(0, 4),
          )
        ],
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _circleCount("14", "Annual"),
          _circleCount("2", "Medical"),
          _circleCount("0", "Emergency"),
        ],
      ),
    );
  }

  Widget _circleCount(String value, String label) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
              )
            ],
          ),
          child: Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF3470D9))),
        ),
        SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 10),
        child: Text("No records", style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: data.map((item) {
        return Container(
          margin: EdgeInsets.only(top: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                blurRadius: 6,
                color: Colors.black.withOpacity(0.05),
                offset: Offset(0, 3),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item["type"],
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(item["date"], style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
