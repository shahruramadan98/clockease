import 'package:flutter/material.dart';
import '../../models/staff_attendance_info.dart';
import '../../services/admin_attendance_service.dart';
import 'widgets/edit_attendance_dialog.dart';

class AttendanceManagementPage extends StatefulWidget {
  final String companyId;

  const AttendanceManagementPage({
    super.key,
    required this.companyId,
  });

  @override
  State<AttendanceManagementPage> createState() =>
      _AttendanceManagementPageState();
}

class _AttendanceManagementPageState extends State<AttendanceManagementPage> {
  final _adminService = AdminAttendanceService();
  late DateTime _selectedDate;
  Stream<List<StaffAttendanceInfo>>? _attendanceStream;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _startStream();
  }

  void _startStream() {
    setState(() {
      _attendanceStream = _adminService.streamStaffAttendanceForDate(
        widget.companyId,
        _selectedDate,
      );
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _startStream(); // Restart stream with new date
    }
  }

  void _showEditDialog(StaffAttendanceInfo staffInfo) {
    showDialog(
      context: context,
      builder: (context) => EditAttendanceDialog(
        staffInfo: staffInfo,
        onSaved: () {
          // No need to manually reload - stream will update automatically
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CBFDA),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Management',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 2),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      isToday ? 'Today' : _formatDate(_selectedDate),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_attendanceStream == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<StaffAttendanceInfo>>(
      stream: _attendanceStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _startStream,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final staffList = snapshot.data;
        
        if (staffList == null || staffList.isEmpty) {
          return const Center(
            child: Text(
              'No staff found',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: staffList.length,
          itemBuilder: (context, index) {
            final staff = staffList[index];
            return _buildStaffCard(staff);
          },
        );
      },
    );
  }

  Widget _buildStaffCard(StaffAttendanceInfo staff) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name, ID, Status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            staff.fullName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (staff.hasAmendments) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'AMENDED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${staff.employeeId} • ${staff.designation}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: staff.statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: staff.statusColor),
                  ),
                  child: Text(
                    staff.statusText,
                    style: TextStyle(
                      color: staff.statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const Divider(height: 24),
            
            // Attendance Details
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Schedule',
                    staff.schedule.displayString,
                    Icons.schedule,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Total Hours',
                    staff.formattedWorkingHours,
                    Icons.timelapse,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Clock In',
                    staff.effectiveClockIn != null
                        ? _formatTime(staff.effectiveClockIn!)
                        : '-',
                    Icons.login,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Clock Out',
                    staff.effectiveClockOut != null
                        ? _formatTime(staff.effectiveClockOut!)
                        : '-',
                    Icons.logout,
                  ),
                ),
              ],
            ),
            
            // Notes Section
            if (staff.adminNotes != null && staff.adminNotes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        staff.adminNotes!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: staff.isOnLeave ? null : () => _showEditDialog(staff),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3BAECC),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF3BAECC)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }
}
