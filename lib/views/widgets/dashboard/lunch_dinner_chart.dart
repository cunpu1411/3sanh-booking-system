import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class LunchDinnerChart extends StatelessWidget {
  final int lunchCount;
  final int dinnerCount;

  const LunchDinnerChart({
    Key? key,
    required this.lunchCount,
    required this.dinnerCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = lunchCount + dinnerCount;

    if (total == 0) {
      return Center(
        child: Text(
          'Không có dữ liệu',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    final lunchPercentage = (lunchCount / total * 100);
    final dinnerPercentage = (dinnerCount / total * 100);

    return Row(
      children: [
        // Donut Chart
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: [
                PieChartSectionData(
                  color: const Color(0xFFFFA726),
                  value: lunchCount.toDouble(),
                  title: '${lunchPercentage.toStringAsFixed(0)}%',
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: const Color(0xFF5C6BC0),
                  value: dinnerCount.toDouble(),
                  title: '${dinnerPercentage.toStringAsFixed(0)}%',
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Legend
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendItem(
                color: const Color(0xFFFFA726),
                label: 'Trưa',
                count: lunchCount,
              ),
              const SizedBox(height: 16),
              _buildLegendItem(
                color: const Color(0xFF5C6BC0),
                label: 'Tối',
                count: dinnerCount,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required int count,
  }) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ),
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
