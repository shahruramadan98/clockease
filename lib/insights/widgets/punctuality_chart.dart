import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PunctualityChart extends StatelessWidget {
  final List<double> weeklyData;

  const PunctualityChart({super.key, required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.70,
      child: Padding(
        padding: const EdgeInsets.only(right: 18.0, left: 12.0, top: 24, bottom: 12),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 25,
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < weeklyData.length) {
                       return Padding(
                         padding: const EdgeInsets.only(top: 8.0),
                         child: Text("Week ${value.toInt() + 1}", style: const TextStyle(fontSize: 12)),
                       );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 25,
                  reservedSize: 42,
                  getTitlesWidget: (value, meta) {
                    return Text('${value.toInt()}%', style: const TextStyle(fontSize: 12));
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: (weeklyData.length - 1).toDouble(),
            minY: 0,
            maxY: 100,
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(weeklyData.length, (index) {
                  return FlSpot(index.toDouble(), weeklyData[index]);
                }),
                isCurved: true,
                color: const Color(0xFF3470D9),
                barWidth: 4,
                isStrokeCapRound: true,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFF3470D9).withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
