import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import '../services/user_service.dart';
import '../services/leave_service.dart';
import '../services/company_settings_service.dart';
import '../models/leave_policy.dart';


class LeaveApplicationForm extends StatefulWidget {
  const LeaveApplicationForm({super.key});

  @override
  State<LeaveApplicationForm> createState() => _LeaveApplicationFormState();
}

class _LeaveApplicationFormState extends State<LeaveApplicationForm> {
  final LeaveService _leaveService = LeaveService();
  final TextEditingController _reasonController = TextEditingController();
  final CompanySettingsService _settingsService = CompanySettingsService();
  final UserService _userService = UserService();

  String? selectedLeaveType;
  DateTime? startDate;
  DateTime? endDate;
  PlatformFile? _selectedFile;
  LeavePolicy? _leavePolicy;

  double _remainingLeaveDays = 0.0;
  bool _policyLoading = true;
  bool _isSubmitting = false;
  double _durationDays = 1.0; // default full day

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
    if (startDate == null || endDate == null) return "0";

    if (_durationDays == 0.5) return "0.5";

    return '${endDate!.difference(startDate!).inDays + 1}';
  }

  Future<void> _loadLeavePolicy() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final companyId = await _userService.getCompanyIdForUser(user.uid);
    if (companyId == null) return;

    final policy = await _settingsService.getLeavePolicy(companyId);

    if (!mounted) return;
    setState(() {
      _leavePolicy = policy;
      _policyLoading = false; 
    });

    if (selectedLeaveType != null) {
      await _recalculateRemainingLeave();
    }
  }

  Future<void> _recalculateRemainingLeave() async {
    if (_leavePolicy == null || selectedLeaveType == null) return;

    if (['Unpaid', 'Emergency', 'Replacement Leave'].contains(selectedLeaveType)) {
      setState(() => _remainingLeaveDays = double.infinity);
      return;
    }

    final double used =
        await _leaveService.getUsedLeaveDays(selectedLeaveType!);

    double total = 0.0;
    if (selectedLeaveType == 'Annual') {
      total = _leavePolicy!.annualLeave.toDouble();
    } else if (selectedLeaveType == 'Sick') {
      total = _leavePolicy!.sickLeave.toDouble();
    }

    setState(() {
      _remainingLeaveDays = (total - used).clamp(0.0, total);
    });
  }

  double get _previewRemainingBalance {
    if (selectedLeaveType == null ||
        ['Unpaid', 'Emergency', 'Replacement Leave']
            .contains(selectedLeaveType)) {
      return double.infinity;
    }

    if (startDate == null || endDate == null) {
      return _remainingLeaveDays;
    }

    double previewDuration;

    if (_durationDays == 0.5) {
      previewDuration = 0.5;
    } else {
      previewDuration =
          endDate!.difference(startDate!).inDays + 1;
    }

    return (_remainingLeaveDays - previewDuration)
        .clamp(0.0, double.infinity);
  }

  List<String> get _leaveTypeOptions {
    return const [
      'Annual',
      'Sick',
      'Emergency',
      'Unpaid',
      'Replacement Leave',
    ];
  }

  bool get _canSubmit {
    if (selectedLeaveType == null || startDate == null || endDate == null) {
      return false;
    }

    if (['Unpaid', 'Emergency', 'Replacement Leave'].contains(selectedLeaveType)) {
      return true;
    }

    return _durationDays <= _remainingLeaveDays;
  }

  @override
  void initState() {
    super.initState();
    _loadLeavePolicy();
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

  String _formatDays(double days) {
    // Show 1 decimal only if needed
    if (days % 1 == 0) {
      return days.toInt().toString(); // 5.0 → "5"
    }
    return days.toStringAsFixed(1);   // 4.5 → "4.5"
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

    if (!_canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Insufficient leave balance"),
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

      if (_durationDays == 0.5 && _leavePolicy?.halfDayAllowed != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Half-day leave is not allowed by company policy"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      double calculatedDuration;

      if (_durationDays == 0.5) {
        calculatedDuration = 0.5;
      } else {
        calculatedDuration =
            endDate!.difference(startDate!).inDays + 1;
      }


      await _leaveService.submitLeave(
        companyId: companyId,
        userName: profile.fullName,
        employeeId: profile.employeeId,
        leaveType: selectedLeaveType!,
        startDate: startDate!,
        endDate: endDate!,
        durationDays: calculatedDuration,
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
    if (_policyLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
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
                  items: _leaveTypeOptions
                      .map(
                        (type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),
                  onChanged: (v) async {
                    setState(() {
                      selectedLeaveType = v;

                      if (v != 'Sick') {
                        _selectedFile = null;
                      }
                    });

                    await _recalculateRemainingLeave();
                  },
                ),
              ),
            ),

            if (_leavePolicy?.halfDayAllowed == true &&
                ['Annual', 'Sick', 'Replacement Leave'].contains(selectedLeaveType)) ...[
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
                      const Text(
                        "Duration",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      RadioGroup<double>(
                        groupValue: _durationDays,
                        onChanged: (double? value) async {
                          if (value == null) return;

                          setState(() {
                            _durationDays = value;
                          });

                          await _recalculateRemainingLeave();
                        },
                        child: const Column(
                          children: [
                            RadioListTile<double>(
                              title: Text("Full Day"),
                              value: 1.0,
                            ),
                            RadioListTile<double>(
                              title: Text("Half Day"),
                              value: 0.5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],


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

            if (startDate != null && endDate != null) ...[
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

              if (selectedLeaveType != null &&
                !['Unpaid', 'Emergency', 'Replacement Leave']
                    .contains(selectedLeaveType))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "Remaining balance: ${_formatDays(_previewRemainingBalance)} day(s)",
                  style: TextStyle(
                    color: _canSubmit ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],


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
                onPressed: (_isSubmitting || !_canSubmit) ? null : submitLeave,
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
