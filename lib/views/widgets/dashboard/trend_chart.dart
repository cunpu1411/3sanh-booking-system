import 'package:client_web/models/metrics_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TrendChart extends StatelessWidget {
  final List<DailyMetrics> data;
  final Color lineColor;
  final Color gradientStartColor;
  final Color gradientEndColor;

  const TrendChart({
    Key? key,
    required this.data,
    this.lineColor = const Color(0xFF5697C6),
    this.gradientStartColor = const Color(0xFF5697C6),
    this.gradientEndColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'Không có dữ liệu',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
          },
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
              reservedSize: 30,
              interval: data.length > 15 ? 7 : 3,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) {
                  return const SizedBox.shrink();
                }

                final date = DateTime.parse(data[index].date);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('dd/MM').format(date),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 5,
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
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: _getMaxY(),
        lineBarsData: [
          LineChartBarData(
            spots: _generateSpots(),
            isCurved: true,
            color: lineColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: lineColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  gradientStartColor.withOpacity(0.3),
                  gradientEndColor.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.blueGrey.shade800,
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index < 0 || index >= data.length) return null;

                final metrics = data[index];
                final date = DateTime.parse(metrics.date);

                return LineTooltipItem(
                  '${DateFormat('dd/MM/yyyy').format(date)}\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: '${metrics.totalReservations} đặt chỗ',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  List<FlSpot> _generateSpots() {
    return List.generate(
      data.length,
      (index) =>
          FlSpot(index.toDouble(), data[index].totalReservations.toDouble()),
    );
  }

  double _getMaxY() {
    if (data.isEmpty) return 10;
    final maxValue = data
        .map((e) => e.totalReservations)
        .reduce((a, b) => a > b ? a : b);
    return (maxValue + 5).toDouble();
  }
}
