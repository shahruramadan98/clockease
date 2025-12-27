import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/staff_attendance_info.dart';
import '../../../services/admin_attendance_service.dart';

class EditAttendanceDialog extends StatefulWidget {
  final StaffAttendanceInfo staffInfo;
  final VoidCallback onSaved;

  const EditAttendanceDialog({
    super.key,
    required this.staffInfo,
    required this.onSaved,
  });

  @override
  State<EditAttendanceDialog> createState() => _EditAttendanceDialogState();
}

class _EditAttendanceDialogState extends State<EditAttendanceDialog> {
  final _adminService = AdminAttendanceService();
  
  late DateTime? _clockInTime;
  late DateTime? _clockOutTime;
  late int _totalHours;
  late int _totalMinutes;
  late TextEditingController _notesController;
  late String? _selectedStatus; // null = auto-calculate, or "onTime", "late", "absent", "halfDay"
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    
    _clockInTime = widget.staffInfo.effectiveClockIn;
    _clockOutTime = widget.staffInfo.effectiveClockOut;
    
    // Initialize total working hours
    final totalDuration = widget.staffInfo.totalWorkingHours;
    _totalHours = totalDuration.inHours;
    _totalMinutes = totalDuration.inMinutes.remainder(60);
    
    // Initialize status override
    _selectedStatus = widget.staffInfo.clockInLog?.adminOverrideStatus;
    
    _notesController = TextEditingController(
      text: widget.staffInfo.adminNotes ?? '',
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isClockIn) async {
    final initialDate = isClockIn 
        ? (_clockInTime ?? DateTime.now())
        : (_clockOutTime ?? DateTime.now());
    
    // Pick date
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (date == null) return;
    
    // Pick time
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    
    if (time == null) return;
    
    final newDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    
    setState(() {
      if (isClockIn) {
        _clockInTime = newDateTime;
      } else {
        _clockOutTime = newDateTime;
      }
    });
  }

  Future<void> _save() async {
    // Validation
    if (_clockInTime != null && _clockOutTime != null) {
      if (_clockOutTime!.isBefore(_clockInTime!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clock out time must be after clock in time'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    
    if (_totalHours < 0 || _totalHours > 24 || _totalMinutes < 0 || _totalMinutes > 59) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid total working hours'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      final totalMinutes = (_totalHours * 60) + _totalMinutes;
      
      // Update clock in log if it exists
      if (widget.staffInfo.clockInLog != null) {
        await _adminService.updateAttendanceLogAsAdmin(
          logId: widget.staffInfo.clockInLog!.id!,
          amendedClockIn: _clockInTime,
          amendedTotalMinutes: totalMinutes,
          notes: _notesController.text.trim(),
          overrideStatus: _selectedStatus, // Pass the status override
        );
      }
      
      // Update clock out log if it exists
      if (widget.staffInfo.clockOutLog != null) {
        await _adminService.updateAttendanceLogAsAdmin(
          logId: widget.staffInfo.clockOutLog!.id!,
          amendedClockOut: _clockOutTime,
        );
      }
      
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Edit Attendance - ${widget.staffInfo.fullName}',
        style: const TextStyle(fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Employee Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Employee ID: ${widget.staffInfo.employeeId}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Schedule: ${widget.staffInfo.schedule.displayString}'),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              const Text(
                'Clock Times',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              
              // Clock In Time
              _buildTimeField(
                label: 'Clock In',
                time: _clockInTime,
                original: widget.staffInfo.clockInLog?.timestamp,
                onTap: () => _pickDateTime(true),
              ),
              
              const SizedBox(height: 12),
              
              // Clock Out Time
              _buildTimeField(
                label: 'Clock Out',
                time: _clockOutTime,
                original: widget.staffInfo.clockOutLog?.timestamp,
                onTap: () => _pickDateTime(false),
              ),
              
              const SizedBox(height: 20),
              const Text(
                'Attendance Status',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              
              // Status Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    isExpanded: true,
                    value: _selectedStatus,
                    hint: const Text('Auto-calculate (based on clock in time)'),
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text('Auto-calculate'),
                      ),
                      DropdownMenuItem(
                        value: 'onTime',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 18),
                            SizedBox(width: 8),
                            Text('On Time'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'late',
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange, size: 18),
                            SizedBox(width: 8),
                            Text('Late'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'halfDay',
                        child: Row(
                          children: [
                            Icon(Icons.schedule, color: Colors.amber, size: 18),
                            SizedBox(width: 8),
                            Text('Half Day'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'absent',
                        child: Row(
                          children: [
                            Icon(Icons.cancel, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text('Absent'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value;
                      });
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              const Text(
                'Total Working Hours',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              
              // Working Hours Input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Hours',
                        border: OutlineInputBorder(),
                        suffixText: 'h',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      controller: TextEditingController(text: _totalHours.toString())
                        ..selection = TextSelection.fromPosition(
                          TextPosition(offset: _totalHours.toString().length),
                        ),
                      onChanged: (value) {
                        setState(() {
                          _totalHours = int.tryParse(value) ?? 0;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Minutes',
                        border: OutlineInputBorder(),
                        suffixText: 'm',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      controller: TextEditingController(text: _totalMinutes.toString())
                        ..selection = TextSelection.fromPosition(
                          TextPosition(offset: _totalMinutes.toString().length),
                        ),
                      onChanged: (value) {
                        setState(() {
                          _totalMinutes = int.tryParse(value) ?? 0;
                        });
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              const Text(
                'Admin Notes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              
              // Notes Field
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  hintText: 'Add any notes or comments...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3BAECC),
            foregroundColor: Colors.white,
          ),
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }

  Widget _buildTimeField({
    required String label,
    required DateTime? time,
    DateTime? original,
    required VoidCallback onTap,
  }) {
    final bool isAmended = time != null && original != null && time != original;
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                label == 'Clock In' ? Icons.login : Icons.logout,
                color: const Color(0xFF3BAECC),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          label,
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        if (isAmended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'AMENDED',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      time != null
                          ? _formatDateTime(time)
                          : 'Not set',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (isAmended && original != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Original: ${_formatDateTime(original)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.edit, color: Color(0xFF3470D9)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day}/${dt.month}/${dt.year} $hour:$minute $period';
  }
}
