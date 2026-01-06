import 'package:client_web/controllers/reservations/reservations_controller.dart';
import 'package:client_web/views/widgets/reservations/notification_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Notification panel (dropdown)
///
/// Features:
/// - Hiển thị list bookings mới
/// - Countdown timer
/// - Refresh button
/// - Empty state
/// - Scroll to load more
class NotificationPanel extends StatelessWidget {
  const NotificationPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReservationsController>();

    return Obx(() {
      if (!controller.isNotificationPanelOpen.value) {
        return const SizedBox.shrink();
      }

      return Stack(
        children: [
          // Backdrop (click to close)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                controller.closeNotificationPanel();
              },
              child: Container(color: Colors.black.withOpacity(0.1)),
            ),
          ),

          // Panel
          Positioned(
            top: 60, // Adjust based on your AppBar height
            right: 16,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              shadowColor: Colors.black.withOpacity(0.1),
              child: Container(
                width: 400,
                constraints: const BoxConstraints(maxHeight: 600),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    _buildHeader(controller),

                    const Divider(height: 1),

                    // Content
                    Flexible(child: _buildContent(controller)),

                    // Footer (if has notifications)
                    if (controller.hasNewReservations.value) ...[
                      const Divider(height: 1),
                      _buildFooter(controller),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildHeader(ReservationsController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF5697C6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF5697C6),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Title + Count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đặt chỗ mới',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Obx(() {
                  final count = controller.newReservationsCount.value;
                  if (count > 0) {
                    return Text(
                      '$count đặt chỗ',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
          ),

          // Close button
          IconButton(
            onPressed: () {
              controller.closeNotificationPanel();
            },
            icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ReservationsController controller) {
    return Obx(() {
      final bookings = controller.newReservationsList;

      if (bookings.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.separated(
        padding: const EdgeInsets.all(16),
        shrinkWrap: true,
        itemCount: bookings.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return NotificationItem(
            reservation: booking,
            onTap: () {
              // TODO: Navigate to booking detail or select booking
              controller.closeNotificationPanel();
              // controller.selectedReservation.value = booking;
            },
          );
        },
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none,
                size: 40,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Không có đặt chỗ mới',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bạn sẽ nhận thông báo khi có\nđặt chỗ mới',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(ReservationsController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Countdown timer
          Obx(() {
            final seconds = controller.remainingTimeForNextRefresh.value;
            if (seconds > 0) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tự động làm mới sau ${controller.formattedCountdown}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          const SizedBox(height: 12),

          // Refresh button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                controller.closeNotificationPanel();
                await controller.refreshReservations();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Làm mới ngay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5697C6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
