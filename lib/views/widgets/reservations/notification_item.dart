import 'package:flutter/material.dart';
import 'package:client_web/models/reservation_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Single notification item (simplified)
///
/// Format: "Tên - SDT - Giờ đến - Số người"
/// Example: "Nguyễn Văn A - 0123456789 - 19:00 28/12 - 4 người"
class NotificationItem extends StatelessWidget {
  final ReservationModel reservation;
  final VoidCallback? onTap;

  const NotificationItem({Key? key, required this.reservation, this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF5697C6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.person_outline,
                color: Color(0xFF5697C6),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),

            // Content: "Tên - SDT - Giờ đến - Số người"
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main info string
                  Text(
                    _buildInfoString(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Time ago (small text)
                  const SizedBox(height: 4),
                  Text(
                    _formatTimeAgo(reservation.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),

            // "NEW" badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF5697C6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'MỚI',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5697C6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build info string: "Tên - SDT - Giờ đến - Số người"
  /// Example: "Nguyễn Văn A - 0123456789 - 19:00 28/12 - 4 người"
  String _buildInfoString() {
    final name = reservation.name;
    final phone = reservation.phone;
    final time = reservation.time;
    final date = _formatShortDate(reservation.date);
    final partySize = reservation.partySize;

    return '$name - $phone - $time $date - $partySize người';
  }

  /// Format date from "DD-MM-YYYY" to "DD/MM"
  /// Example: "28-12-2024" → "28/12"
  String _formatShortDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length >= 2) {
        return '${parts[0]}/${parts[1]}';
      }
      return dateStr;
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTimeAgo(dynamic timestamp) {
    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        return 'Vừa xong';
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return 'Vừa xong';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} phút trước';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} giờ trước';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} ngày trước';
      } else {
        final day = dateTime.day.toString().padLeft(2, '0');
        final month = dateTime.month.toString().padLeft(2, '0');
        final year = dateTime.year;
        final hour = dateTime.hour.toString().padLeft(2, '0');
        final minute = dateTime.minute.toString().padLeft(2, '0');
        return '$day/$month/$year $hour:$minute';
      }
    } catch (e) {
      return 'Vừa xong';
    }
  }
}
