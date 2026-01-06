import 'package:flutter/material.dart';

class SourceDistributionChart extends StatelessWidget {
  final int phoneCount;
  final int websiteCount;
  final int walkinCount;

  const SourceDistributionChart({
    Key? key,
    required this.phoneCount,
    required this.websiteCount,
    required this.walkinCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = phoneCount + websiteCount + walkinCount;

    if (total == 0) {
      return Center(
        child: Text(
          'Không có dữ liệu',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    return Column(
      children: [
        _buildSourceItem(
          icon: Icons.phone,
          label: 'Điện thoại',
          count: phoneCount,
          total: total,
          color: const Color(0xFF5697C6),
        ),
        const SizedBox(height: 16),
        _buildSourceItem(
          icon: Icons.language,
          label: 'Website',
          count: websiteCount,
          total: total,
          color: const Color(0xFF4CAF50),
        ),
        const SizedBox(height: 16),
        _buildSourceItem(
          icon: Icons.directions_walk,
          label: 'Walk-in',
          count: walkinCount,
          total: total,
          color: const Color(0xFFFFA726),
        ),
      ],
    );
  }

  Widget _buildSourceItem({
    required IconData icon,
    required String label,
    required int count,
    required int total,
    required Color color,
  }) {
    final percentage = (count / total * 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${percentage.toStringAsFixed(0)}%)',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
