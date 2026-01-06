import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PartySizeChart extends StatelessWidget {
  final List<MapEntry<String, int>> distribution;

  const PartySizeChart({Key? key, required this.distribution})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (distribution.isEmpty) {
      return Center(
        child: Text(
          'Không có dữ liệu',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    return Row(
      children: [
        // Pie Chart
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: _generateSections(),
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {},
              ),
            ),
          ),
        ),

        // Legend
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildLegend(),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _generateSections() {
    final total = distribution.fold<int>(0, (sum, item) => sum + item.value);
    final colors = [
      const Color(0xFF5697C6),
      const Color(0xFF4CAF50),
      const Color(0xFFFFA726),
      const Color(0xFFEF5350),
    ];

    return List.generate(distribution.length, (index) {
      final entry = distribution[index];
      final percentage = (entry.value / total * 100);
      final color = colors[index % colors.length];

      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  List<Widget> _buildLegend() {
    final colors = [
      const Color(0xFF5697C6),
      const Color(0xFF4CAF50),
      const Color(0xFFFFA726),
      const Color(0xFFEF5350),
    ];

    return List.generate(distribution.length, (index) {
      final entry = distribution[index];
      final color = colors[index % colors.length];

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
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
                '${entry.key} người',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ),
            Text(
              entry.value.toString(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      );
    });
  }
}
