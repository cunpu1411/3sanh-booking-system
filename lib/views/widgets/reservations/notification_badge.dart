import 'package:client_web/controllers/reservations/reservations_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Notification badge
class NotificationBadge extends StatelessWidget {
  const NotificationBadge({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReservationsController>();

    return Obx(() {
      final hasNew = controller.hasNewReservations.value;
      final count = controller.newReservationsCount.value;

      return Stack(
        clipBehavior: Clip.none,
        children: [
          // Icon button
          IconButton(
            onPressed: () {
              controller.toggleNotificationPanel();
            },
            icon: Icon(
              Icons.notifications_outlined,
              size: 24,
              color: hasNew ? const Color(0xFF5697C6) : const Color(0xFF64748B),
            ),
            tooltip: hasNew ? '$count đặt chỗ mới' : 'Không có đặt chỗ mới',
            style: IconButton.styleFrom(
              backgroundColor: hasNew
                  ? const Color(0xFF5697C6).withOpacity(0.1)
                  : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          // Badge counter
          if (hasNew && count > 0)
            Positioned(
              right: 0,
              top: 0,
              child: AnimatedScale(
                scale: 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: count > 9 ? 5 : 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}
