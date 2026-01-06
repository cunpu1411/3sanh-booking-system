import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PeakHoursChart extends StatelessWidget {
  final List<MapEntry<int, int>> peakHours;
  final Color barColor;

  const PeakHoursChart({
    super.key,
    required this.peakHours,
    this.barColor = const Color(0xFF5697C6),
  });

  @override
  Widget build(BuildContext context) {
    if (peakHours.isEmpty) {
      return Center(
        child: Text(
          'Không có dữ liệu',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxY(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.blueGrey.shade800,
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final hour = peakHours[groupIndex].key;
              final count = peakHours[groupIndex].value;
              return BarTooltipItem(
                '${hour}:00\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(
                    text: '$count đặt chỗ',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= peakHours.length) {
                  return const SizedBox.shrink();
                }
                final hour = peakHours[index].key;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${hour}h',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
          },
        ),
        barGroups: _generateBarGroups(),
      ),
    );
  }

  List<BarChartGroupData> _generateBarGroups() {
    return List.generate(peakHours.length, (index) {
      final count = peakHours[index].value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            color: barColor,
            width: 24,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _getMaxY(),
              color: Colors.grey.shade100,
            ),
          ),
        ],
      );
    });
  }

  double _getMaxY() {
    if (peakHours.isEmpty) return 10;
    final maxValue = peakHours
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);
    return (maxValue + 2).toDouble();
  }
}
