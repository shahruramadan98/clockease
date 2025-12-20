import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/leave_service.dart';
import 'leave_application_form.dart';

class LeavePage extends StatefulWidget {
  const LeavePage({super.key});

  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  final LeaveService _leaveService = LeaveService();
  final DateFormat dateFormatter = DateFormat('dd/MM/yyyy');

  static const int annualTotal = 15;
  static const int sickTotal = 7;

  int calculateDays(DateTime start, DateTime end) {
    return end.difference(start).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Use theme default

      appBar: AppBar(
        // backgroundColor: Use theme default
        elevation: 0,
        title: Text(
          "Leave Application",
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {},
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4FC3F7),
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LeaveApplicationForm()),
          );
        },
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _leaveService.getUserLeaves(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SelectableText(
                  "Error: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("No data found"));
          }

          final docs = snapshot.data!.docs;
          final now = DateTime.now();

          int usedAnnual = 0;
          int usedSick = 0;

          final upcoming = <QueryDocumentSnapshot>[];
          final pending = <QueryDocumentSnapshot>[];
          final past = <QueryDocumentSnapshot>[];

          for (var doc in docs) {
            final start = (doc['startDate'] as Timestamp).toDate();
            final end = (doc['endDate'] as Timestamp).toDate();
            final status = doc['status'];
            final days = calculateDays(start, end);

            if (status == 'approved') {
              if (doc['leaveType'] == 'Annual') usedAnnual += days;
              if (doc['leaveType'] == 'Sick') usedSick += days;
            }

            if (status == 'pending') {
              pending.add(doc);
            } else if (end.isAfter(now)) {
              upcoming.add(doc);
            } else {
              past.add(doc);
            }
          }

          final remainingAnnual = annualTotal - usedAnnual;
          final remainingSick = sickTotal - usedSick;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// 🔹 Leave Balance Card
                _leaveBalanceCard(
                  annualLeft: remainingAnnual,
                  sickLeft: remainingSick,
                ),

                const SizedBox(height: 24),

                _sectionTitle("Upcoming Leave"),
                upcoming.isEmpty
                    ? _emptyMessage("No upcoming leave")
                    : Column(children: upcoming.map(_leaveCardApproved).toList()),


                const SizedBox(height: 24),

                _sectionTitle("Pending Requests"),
                pending.isEmpty
                    ? _emptyMessage("No pending requests")
                    : Column(children: pending.map(_leaveCardPending).toList()),


                const SizedBox(height: 24),

                _sectionTitle("Past Leave"),
                past.isEmpty
                    ? _emptyMessage("No past leave")
                    : Column(children: past.map(_leaveCardTaken).toList()),
              ],
            ),
          );
        },
      ),
    );
  }

  /// ================= UI COMPONENTS =================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _emptyMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        message,
        textAlign: TextAlign.left,
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white70
              : Colors.grey,
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _leaveBalanceCard({
    required int annualLeft,
    required int sickLeft,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Leave Balances",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),

          Text("Annual Leave", style: TextStyle(color: Colors.white)),
          Text("$annualLeft days", style: TextStyle(color: Colors.white)),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: annualLeft / annualTotal,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),

          const Divider(color: Colors.white54, height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _smallBalance("Sick Leave", "$sickLeft days"),
              _smallBalance("Unpaid Leave", "Unlimited"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallBalance(String title, String value) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: Colors.white)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _leaveCardApproved(QueryDocumentSnapshot doc) =>
      _leaveCard(doc, "Approved", Colors.green);

  Widget _leaveCardPending(QueryDocumentSnapshot doc) =>
      _leaveCard(doc, "Pending", const Color.fromARGB(255, 235, 224, 75));

  Widget _leaveCardTaken(QueryDocumentSnapshot doc) =>
      _leaveCard(doc, "Taken", Colors.grey);

  Widget _leaveCard(
      QueryDocumentSnapshot doc, String status, Color color) {
    final start = (doc['startDate'] as Timestamp).toDate();
    final end = (doc['endDate'] as Timestamp).toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF4FC3F7), Color(0xFF42A5F5)],
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(doc['leaveType'],
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                "${dateFormatter.format(start)} - ${dateFormatter.format(end)}",
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
