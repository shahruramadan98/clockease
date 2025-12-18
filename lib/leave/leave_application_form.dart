import 'package:flutter/material.dart';
import '../services/leave_service.dart';

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

  final startDateController = TextEditingController();
  final endDateController = TextEditingController();

  Future<void> submitLeave() async {
    if (selectedLeaveType == null || startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields")),
      );
      return;
    }

    await _leaveService.submitLeave(
      leaveType: selectedLeaveType!,
      startDate: startDate!,
      endDate: endDate!,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Leave request submitted")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Leave Application Form")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text("Leave Type", style: TextStyle(fontSize: 18)),
            DropdownButton<String>(
              isExpanded: true,
              value: selectedLeaveType,
              hint: const Text("Select Leave Type"),
              items: ['Annual', 'Sick', 'Emergency']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) => setState(() => selectedLeaveType = value),
            ),

            const SizedBox(height: 20),
            const Text("Start Date", style: TextStyle(fontSize: 18)),
            TextField(
              controller: startDateController,
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2101),
                );
                if (date != null) {
                  setState(() {
                    startDate = date;
                    startDateController.text = date.toString().split(' ')[0];
                  });
                }
              },
              decoration: const InputDecoration(
                suffixIcon: Icon(Icons.calendar_today),
              ),
            ),

            const SizedBox(height: 20),
            const Text("End Date", style: TextStyle(fontSize: 18)),
            TextField(
              controller: endDateController,
              readOnly: true,
              onTap: () async {
                if (startDate == null) return;

                final date = await showDatePicker(
                  context: context,
                  initialDate: startDate!,
                  firstDate: startDate!,
                  lastDate: DateTime(2101),
                );
                if (date != null) {
                  setState(() {
                    endDate = date;
                    endDateController.text = date.toString().split(' ')[0];
                  });
                }
              },
              decoration: const InputDecoration(
                suffixIcon: Icon(Icons.calendar_today),
              ),
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: submitLeave,
              child: const Text("Submit Leave Request"),
            ),
          ],
        ),
      ),
    );
  }
}
