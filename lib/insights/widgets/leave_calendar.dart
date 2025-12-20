import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/leave_info.dart';
import '../../services/leave_service.dart';
import 'leave_detail_modal.dart';

class LeaveCalendar extends StatefulWidget {
  final String companyId;

  const LeaveCalendar({
    super.key,
    required this.companyId,
  });

  @override
  State<LeaveCalendar> createState() => _LeaveCalendarState();
}

class _LeaveCalendarState extends State<LeaveCalendar> {
  final _leaveService = LeaveService();
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  Map<DateTime, List<LeaveInfo>> _leavesByDate = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print('LeaveCalendar initialized with companyId: ${widget.companyId}');
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _loadLeavesForMonth(_focusedDay.year, _focusedDay.month);
  }

  Future<void> _loadLeavesForMonth(int year, int month) async {
    print('Loading leaves for $year-$month, companyId: ${widget.companyId}');
    setState(() => _isLoading = true);
    
    final leaves = await _leaveService.getCompanyLeavesForMonth(
      year,
      month,
      widget.companyId,
    );
    
    print('Loaded ${leaves.length} dates with leaves');
    setState(() {
      _leavesByDate = leaves;
      _isLoading = false;
    });
  }

  List<LeaveInfo> _getLeavesForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _leavesByDate[dateKey] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    // Show modal with leave details
    final leaves = _getLeavesForDay(selectedDay);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LeaveDetailModal(
        selectedDate: selectedDay,
        leaves: leaves,
      ),
    );
  }

  void _onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
    _loadLeavesForMonth(focusedDay.year, focusedDay.month);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Calendar
            TableCalendar<LeaveInfo>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: _getLeavesForDay,
              onDaySelected: _onDaySelected,
              onPageChanged: _onPageChanged,
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              
              // Styling
              calendarStyle: CalendarStyle(
                // Today
                todayDecoration: BoxDecoration(
                  color: const Color(0xFF4CBFDA).withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3470D9),
                ),
                
                // Selected day
                selectedDecoration: const BoxDecoration(
                  color: Color(0xFF3470D9),
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                
                // Default days
                defaultTextStyle: const TextStyle(
                  color: Colors.black87,
                ),
                
                // Weekend days
                weekendTextStyle: TextStyle(
                  color: Colors.red.shade400,
                ),
                
                // Outside days (other months)
                outsideTextStyle: TextStyle(
                  color: Colors.grey.shade400,
                ),
                
                // Marker (event indicator)
                markerDecoration: const BoxDecoration(
                  color: Color(0xFFE57373),
                  shape: BoxShape.circle,
                ),
                markerSize: 6,
                markersMaxCount: 1,
                markersAlignment: Alignment.bottomCenter,
              ),
              
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
                leftChevronIcon: const Icon(
                  Icons.chevron_left,
                  color: Color(0xFF3470D9),
                ),
                rightChevronIcon: const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF3470D9),
                ),
              ),
              
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
                weekendStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade400,
                ),
              ),
            ),
            
            // Loading indicator
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: LinearProgressIndicator(),
              ),
            
            // Legend
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                  color: const Color(0xFFE57373),
                  label: 'Employee(s) on leave',
                ),
                const SizedBox(width: 24),
                _buildLegendItem(
                  color: const Color(0xFF4CBFDA).withOpacity(0.3),
                  label: 'Today',
                  borderColor: const Color(0xFF4CBFDA),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tap any date to see who\'s on leave',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    Color? borderColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: borderColor != null
                ? Border.all(color: borderColor, width: 2)
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
