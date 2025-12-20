import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/insights_controller.dart';
import 'widgets/summary_card.dart';
import 'widgets/punctuality_chart.dart';
import 'widgets/insight_text_card.dart';

class InsightsPage extends ConsumerWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(insightsProvider);

    return Scaffold(
      // backgroundColor: Use default theme
      body: insightsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Failed to load insights: $e")),
        data: (data) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TITLE
                Text(
                  "Your Insights",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Understanding your habits, improving your flow.",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),

                // 1. ATTENDANCE SUMMARY GRID
                Text(
                  "Attendance Summary (This Month)",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    SummaryCard(
                      title: "On Time",
                      value: "${data.onTimeCount} days",
                      color: const Color(0xFF4CBFDA), // Dashboard Cyan
                      icon: Icons.check_circle_outline,
                    ),
                    SummaryCard(
                      title: "Late",
                      value: "${data.lateCount} days",
                      color: Colors.orange.shade400,
                      icon: Icons.access_time,
                    ),
                    SummaryCard(
                      title: "Half Day",
                      value: "${data.halfDayCount} days",
                      color: Colors.purple.shade400,
                      icon: Icons.incomplete_circle,
                    ),
                    SummaryCard(
                      title: "Absent",
                      value: "${data.absentCount} days",
                      color: const Color(0xFFE57373), // Dashboard Red
                      icon: Icons.cancel_outlined,
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // 2. PUNCTUALITY TREND
                Text(
                  "Punctuality Trend",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "On Time Rate",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${data.onTimePercentage.toStringAsFixed(0)}%",
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3470D9),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (data.punctualityImprovement != 0)
                              Text(
                                "${data.punctualityImprovement > 0 ? '+' : ''}${data.punctualityImprovement.toStringAsFixed(1)}% from last month",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: data.punctualityImprovement >= 0 ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        PunctualityChart(weeklyData: data.weeklyPunctuality),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                 // 3. WORKING HOURS OVERVIEW
                Text(
                  "Working Hours Overview",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SummaryCard(
                        title: "Total Hours",
                        value: "${data.totalHoursWorked.toStringAsFixed(1)}h",
                        color: const Color(0xFF3470D9), // Dashboard Blue
                        icon: Icons.timer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SummaryCard(
                        title: "Avg Per Day",
                        value: "${data.avgHoursPerDay.toStringAsFixed(1)}h",
                        color: const Color(0xFF3BAECC), // Dashboard Teal
                        icon: Icons.av_timer,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // 4. STREAKS
                 Text(
                  "Streaks & Consistency",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                InsightTextCard(
                  title: "Current On-Time Streak",
                  content: "${data.currentStreak} days in a row! Keep it up!",
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                ),
                const SizedBox(height: 12),
                 InsightTextCard(
                  title: "Best This Month",
                  content: "Longest streak was ${data.maxStreak} days.",
                  icon: Icons.emoji_events_outlined,
                  color: Colors.amber,
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}
