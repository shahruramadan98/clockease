import 'package:flutter/material.dart';
import '../services/leave_service.dart';

import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';


class LeaveApplicationForm extends StatefulWidget {
  const LeaveApplicationForm({super.key});

  @override
  State<LeaveApplicationForm> createState() => _LeaveApplicationFormState();
}

class _LeaveApplicationFormState extends State<LeaveApplicationForm> {
  final LeaveService _leaveService = LeaveService();

  String? selectedLeaveType;
  DateTime? startDate;
  DateTime? endDate;

  bool _isSubmitting = false;

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> submitLeave() async {
    if (selectedLeaveType == null || startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please complete all fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userService = UserService();

    final profile = await userService.getEmployeeProfile(uid);
    final companyId = await userService.getCompanyIdForUser(uid);

    if (profile == null || companyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("User profile not found"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await _leaveService.submitLeave(
      companyId: companyId,
      userName: profile.fullName,
      employeeId: profile.employeeId,
      leaveType: selectedLeaveType!,
      startDate: startDate!,
      endDate: endDate!,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Leave request submitted"),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Apply for Leave",
          style: TextStyle(color: Color(0xFF3F51B5)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF3F51B5)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Request Leave",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3BAECC),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              "Fill in the details below to submit your leave request",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // =====================
            // LEAVE TYPE
            // =====================
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String>(
                  value: selectedLeaveType,
                  decoration: const InputDecoration(
                    labelText: "Leave Type",
                    border: OutlineInputBorder(),
                  ),
                  items: const ['Annual', 'Sick', 'Emergency', 'Unpaid']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedLeaveType = v),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // =====================
            // START DATE
            // =====================
            _datePicker(
              label: "Start Date",
              date: startDate,
              onPick: (d) {
                setState(() {
                  startDate = d;
                  if (endDate != null && endDate!.isBefore(d)) {
                    endDate = null;
                  }
                });
              },
            ),

            const SizedBox(height: 16),

            // =====================
            // END DATE
            // =====================
            _datePicker(
              label: "End Date",
              date: endDate,
              disabled: startDate == null,
              minDate: startDate,
              onPick: (d) => setState(() => endDate = d),
            ),

            if (startDate != null && endDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  "Duration: ${endDate!.difference(startDate!).inDays + 1} day(s)",
                  style: const TextStyle(
                    color: Color(0xFF3BAECC),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // =====================
            // SUBMIT
            // =====================
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: submitLeave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3BAECC),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.send, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Submit Leave Request",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================
  // DATE PICKER WIDGET
  // =====================
  Widget _datePicker({
    required String label,
    required DateTime? date,
    required Function(DateTime) onPick,
    bool disabled = false,
    DateTime? minDate,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        InkWell(
          onTap: disabled
              ? null
              : () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date ?? minDate ?? DateTime.now(),
                    firstDate: minDate ?? DateTime.now(),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) onPick(picked);
                },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: disabled ? Colors.grey.shade100 : Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date == null ? "Select date" : _formatDate(date),
                  style: TextStyle(
                    color: date == null
                        ? Colors.grey.shade600
                        : Colors.black,
                  ),
                ),
                const Icon(Icons.calendar_today, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
