import 'package:client_web/models/reservation_model.dart';
import 'package:flutter/material.dart';

class UpcomingCard extends StatelessWidget {
  final List<ReservationModel> upcomingReservations;
  final VoidCallback? onViewAll;

  const UpcomingCard({
    Key? key,
    required this.upcomingReservations,
    this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.access_time, color: Color(0xFF5697C6), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Sắp đến (2 giờ tới)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  child: const Text('Xem tất cả'),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // List
          if (upcomingReservations.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_available,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Không có đặt chỗ sắp đến',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: upcomingReservations.length > 5
                  ? 5
                  : upcomingReservations.length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final reservation = upcomingReservations[index];
                return _buildReservationItem(reservation);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildReservationItem(ReservationModel reservation) {
    return Row(
      children: [
        // Time
        Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF5697C6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            reservation.time,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5697C6),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 12),

        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reservation.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.people, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${reservation.partySize} người',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    reservation.phone,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            reservation.status.displayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
        ),
      ],
    );
  }
}
