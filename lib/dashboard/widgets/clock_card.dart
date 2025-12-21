import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/dashboard_controller.dart';
import '../../models/dashboard_attendance_state.dart'; // Import for AttendanceStep
import '../../features/attendance/face_verification_page.dart';
import '../../widgets/location_confirmation_dialog.dart';
import '../../services/location_service.dart';

class ClockCard extends ConsumerWidget {
  const ClockCard({super.key});

  /// Show location confirmation dialog and return confirmed location
  Future<LocationData?> _showLocationConfirmation(BuildContext context) async {
    return await showModalBottomSheet<LocationData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LocationConfirmationDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(dashboardProvider);
    final controller = ref.read(dashboardControllerProvider);

    // Handle async state from stream provider
    return asyncState.when(
      loading: () => _buildLoadingCard(),
      error: (_, __) => _buildErrorCard(),
      data: (state) => _buildClockCard(context, ref, state, controller),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF3470D9), Color(0xFF4CBFDA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.red.shade100,
      ),
      child: const Center(
        child: Text(
          "Error loading attendance state",
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildClockCard(
    BuildContext context,
    WidgetRef ref,
    DashboardAttendanceState state,
    DashboardController controller,
  ) {
    // Derive UI properties from the step
    String title;
    String subtitle;
    IconData icon;
    List<Color> gradientColors;
    bool isActionable;

    switch (state.step) {
      case AttendanceStep.notStarted:
        title = "Clock In";
        subtitle = "Tap to verify face to clock in";
        icon = Icons.face_retouching_natural;
        gradientColors = [const Color(0xFF3470D9), const Color(0xFF4CBFDA)];
        isActionable = true;
        break;
      case AttendanceStep.clockedIn:
        title = "Clock Out";
        subtitle = "Tap to clock out";
        icon = Icons.logout_rounded;
        gradientColors = [const Color(0xFFE57373), const Color(0xFFD32F2F)];
        isActionable = true;
        break;
    }

    return GestureDetector(
      onTap: !isActionable
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("You have already completed attendance today.")),
              );
            }
          : () async {
        // STEP 1: Get and confirm location FIRST
        final confirmedLocation = await _showLocationConfirmation(context);
        
        // If user cancelled location confirmation, don't proceed
        if (confirmedLocation == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location confirmation cancelled'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        // STEP 2: Navigate to face verification screen (UNCHANGED)
        if (!context.mounted) return;
        
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FaceVerificationPage()),
        );

        // STEP 3: If face matches, result will be the file path (String)
        if (result != null && result is String) {
          final file = File(result);

          try {
            // Show loading
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Processing attendance...")),
              );
            }

            // 4. Confirm Attendance (API Call) with confirmed location
            await controller.confirmAttendance(file, confirmedLocation);

          // 5. Success Message
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.step == AttendanceStep.clockedIn 
                    ? "Successfully Clocked OUT" 
                    : "Successfully Clocked IN"
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
            
          } catch (e) {
            // 6. Error Message
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Attendance Failed: ${e.toString().replaceAll('Exception: ', '')}"),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } 
      },

      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),

            child: Row(
              children: [
                // LEFT SIDE
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // MAIN ACTION
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // ACTUAL STATUS
                      Text(
                        state.lastAction != null
                            ? "Last action: ${state.lastAction}"
                            : "No recent activity",
                        style: const TextStyle(fontSize: 15, color: Colors.white70),
                      ),

                      const SizedBox(height: 10),

                      // INSTRUCTIONS
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // RIGHT ICON
                Container(
                  height: 90,
                  width: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ],
            ),
          ),
          
          // --- DEV RESET BUTTON ---

        ],
      ),
    );
  }
}
