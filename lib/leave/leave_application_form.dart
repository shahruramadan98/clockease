import 'package:flutter/material.dart';
import '../services/leave_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import 'package:file_picker/file_picker.dart';


class LeaveApplicationForm extends StatefulWidget {
  const LeaveApplicationForm({super.key});

  @override
  State<LeaveApplicationForm> createState() => _LeaveApplicationFormState();
}

class _LeaveApplicationFormState extends State<LeaveApplicationForm> {
  final LeaveService _leaveService = LeaveService();
  final TextEditingController _reasonController = TextEditingController();

  String? selectedLeaveType;
  DateTime? startDate;
  DateTime? endDate;
  PlatformFile? _selectedFile;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _calculateDuration() {
    if (startDate == null || endDate == null) return '0';
    
    // Check if it's a half-day leave
    if (selectedLeaveType == 'Half Day (AM)' || selectedLeaveType == 'Half Day (PM)') {
      return '0.5';
    }
    
    // Normal day calculation
    return '${endDate!.difference(startDate!).inDays + 1}';
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true, // Important: load file bytes
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.single;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error picking file: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
    });
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

    setState(() => _isSubmitting = true);

    try {
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

      // Upload attachment if file is selected
      String? attachmentUrl;
      if (_selectedFile != null) {
        attachmentUrl = await _leaveService.uploadAttachment(_selectedFile!);
        if (attachmentUrl == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to upload attachment. Please try again."),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      await _leaveService.submitLeave(
        companyId: companyId,
        userName: profile.fullName,
        employeeId: profile.employeeId,
        leaveType: selectedLeaveType!,
        startDate: startDate!,
        endDate: endDate!,
        reason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
        attachmentUrl: attachmentUrl,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Leave request submitted"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
                  items: const ['Annual', 'Sick', 'Emergency', 'Unpaid', 'Replacement Leave', 'Half Day (AM)', 'Half Day (PM)']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedLeaveType = v;
                      // Clear attachment if switching away from sick leave
                      if (v != 'Sick') {
                        _selectedFile = null;
                      }
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // =====================
            // REASON FIELD
            // =====================
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    labelText: "Reason for Leave",
                    hintText: "Enter the reason for your leave (optional)",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
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
                  "Duration: ${_calculateDuration()} day(s)",
                  style: const TextStyle(
                    color: Color(0xFF3BAECC),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            // =====================
            // ATTACHMENT (SICK LEAVE ONLY)
            // =====================
            if (selectedLeaveType == 'Sick') ...[
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.attach_file, color: Color(0xFF3BAECC)),
                          const SizedBox(width: 8),
                          Text(
                            "Attachment (Optional)",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Upload medical certificate or supporting document",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_selectedFile == null)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _pickFile,
                            icon: const Icon(Icons.upload_file),
                            label: const Text("Choose File"),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3BAECC).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF3BAECC).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.insert_drive_file,
                                color: Color(0xFF3BAECC),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedFile!.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                onPressed: _removeFile,
                                icon: const Icon(Icons.close),
                                color: Colors.red.shade400,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        "Supported formats: PDF, JPG, PNG",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // =====================
            // SUBMIT
            // =====================
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : submitLeave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3BAECC),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
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
