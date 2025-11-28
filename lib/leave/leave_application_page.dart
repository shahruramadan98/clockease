import 'package:flutter/material.dart';
import '../controllers/leave_controller.dart';

class LeaveApplicationPage extends StatefulWidget {
  const LeaveApplicationPage({Key? key}) : super(key: key);

  @override
  State<LeaveApplicationPage> createState() => _LeaveApplicationPageState();
}

class _LeaveApplicationPageState extends State<LeaveApplicationPage> {
  final controller = LeaveController();

  String? selectedLeaveType;
  DateTimeRange? selectedRange;
  bool isHalfDay = false;
  String? halfDaySlot;
  String? attachmentPath;
  final reasonController = TextEditingController();

  final leaveTypes = [
    "Annual Leave",
    "Sick Leave",
    "Emergency Leave",
    "Unpaid Leave",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Apply Leave"),
        backgroundColor: Color(0xFF3470D9),
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Leave Type
            Text("Leave Type", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),

            DropdownButtonFormField(
              value: selectedLeaveType,
              items: leaveTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              decoration: InputDecoration(border: OutlineInputBorder()),
              onChanged: (value) {
                setState(() => selectedLeaveType = value);
              },
            ),

            SizedBox(height: 20),

            // Date Picker
            Text("Select Date Range", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),

            GestureDetector(
              onTap: pickDateRange,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  selectedRange == null
                      ? "Tap to select date"
                      : "${selectedRange!.start.toString().split(' ')[0]} → ${selectedRange!.end.toString().split(' ')[0]}",
                ),
              ),
            ),

            SizedBox(height: 20),

            // Half Day Switch
            if (selectedLeaveType == "Annual Leave")
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Half Day", style: TextStyle(fontWeight: FontWeight.bold)),
                  Switch(
                    value: isHalfDay,
                    onChanged: (value) {
                      setState(() {
                        isHalfDay = value;
                      });
                    },
                  ),
                ],
              ),

            if (isHalfDay)
              DropdownButtonFormField(
                hint: Text("Choose Half Day Slot"),
                items: ["Morning", "Afternoon"]
                    .map((slot) => DropdownMenuItem(value: slot, child: Text(slot)))
                    .toList(),
                decoration: InputDecoration(border: OutlineInputBorder()),
                onChanged: (value) {
                  setState(() => halfDaySlot = value);
                },
              ),

            SizedBox(height: 20),

            // Reason
            Text("Reason", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),

            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "State your reason here",
              ),
            ),

            SizedBox(height: 20),

            // Attachment for Sick / Emergency Leave
            if (selectedLeaveType == "Sick Leave" ||
                selectedLeaveType == "Emergency Leave")
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Attachment (MC / Proof)", style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        attachmentPath = "dummy_file.pdf"; // placeholder
                      });
                    },
                    icon: Icon(Icons.upload),
                    label: Text("Upload File"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3470D9),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),

            SizedBox(height: 40),
          ],
        ),
      ),

      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF3470D9),
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text("Submit Request", style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  // Date Picker Function
  void pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() => selectedRange = picked);
    }
  }

  // Submit Handler with Validation
  void submit() {
    final error = controller.validate(
      type: selectedLeaveType,
      range: selectedRange,
      reason: reasonController.text,
      halfDay: isHalfDay,
      halfSlot: halfDaySlot,
      attachment: attachmentPath,
    );

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Leave request validated")),
    );

    // next: call Firestore save
  }
}
