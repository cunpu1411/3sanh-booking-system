/* ===================== RESERVATIONS SECTION ===================== */
import 'package:client_web/controllers/reservations/reservations_controller.dart';
import 'package:client_web/views/reservations_row.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ReservationsSection extends StatelessWidget {
  const ReservationsSection({
    super.key,
    required this.isDark,
    required this.timeFmt,
  });

  final bool isDark;
  final DateFormat timeFmt;
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReservationsController>();
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: TextField(
                controller: controller.searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, phone, ID,...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF64748B),
                    size: 15,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF5697C6),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
              ),
            ),
            const SizedBox(width: 10),
            _buildDateRange(context),
            const SizedBox(width: 12),
            Obx(() {
              return Row(
                children: [
                  FilterChip(
                    label: const Text('Chưa đến'),
                    selected: controller.showOnlyNotArrived.value,
                    selectedColor: Colors.amber.shade600,
                    checkmarkColor: Colors.white,
                    onSelected: (v) => controller.showOnlyNotArrived.value = v,
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Hôm nay'),
                    selected: controller.showReservationsToday.value,
                    selectedColor: Colors.amber.shade600,
                    checkmarkColor: Colors.white,
                    onSelected: (v) => controller.setQuickFilers(today: v),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Tuần này'),
                    selected: controller.showReservationsThisWeek.value,
                    selectedColor: Colors.amber.shade600,
                    checkmarkColor: Colors.white,
                    onSelected: (v) => controller.setQuickFilers(week: v),
                  ),
                ],
              );
            }),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Obx(() {
            return _ReservationsTable(
              timeFmt: timeFmt,
              isDark: isDark,
              reservations: controller.filteredReservations,
              isLoading: controller.isLoading.value,
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDateRange(BuildContext context) {
    return Obx(() {
      final controller = Get.find<ReservationsController>();
      final hasDateRange = controller.dateRangeFilter.value != null;
      final dateText = hasDateRange
          ? controller.formattedDateRange
          : 'Chọn khoảng thời gian';

      return Tooltip(
        message: dateText,
        child: InkWell(
          onTap: () => controller.dateRangePicker(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hasDateRange
                  ? const Color(0xFFB4D7EF)
                  : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasDateRange
                    ? const Color(0xFFB9DAE8)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 21,
                  color: hasDateRange
                      ? const Color(0xFF488FC3)
                      : const Color(0xFF64748B),
                ),
                if (hasDateRange)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF488FC3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/* ===================== TABLE ===================== */
class _ReservationsTable extends StatelessWidget {
  const _ReservationsTable({
    required this.timeFmt,
    required this.isDark,
    required this.reservations,
    required this.isLoading,
  });

  final DateFormat timeFmt;
  final bool isDark;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> reservations;
  final bool isLoading;
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReservationsController>();
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy đặt chỗ',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTableHeader(isDark),
          Expanded(
            child: ListView.builder(
              itemCount: reservations.length,
              itemBuilder: (context, index) {
                final reservation = reservations[index];
                return ReservationsRow(
                  reservation: reservation,
                  onTap: () => controller.setSelectedReservation(reservation),
                  isDark: isDark,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(bool isDark) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? Color(0x421265FF) : Color(0xFF5697C6),
        border: Border(bottom: BorderSide(color: Color(0xFF334155), width: 2)),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildHeaderCell('Customer')),
          Expanded(child: _buildHeaderCell('Contact')),
          Expanded(child: _buildSortHeaderCell('Date')),
          Expanded(child: _buildHeaderCell('Size')),
          Flexible(
            flex: 3,
            fit: FlexFit.tight,
            child: _buildHeaderCell('Note'),
          ),
          Expanded(child: _buildHeaderCell('Status')),
          Expanded(child: _buildHeaderCell('Actions')),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title, {bool center = true}) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xF0FFFFFF),
      ),
      textAlign: center ? TextAlign.center : TextAlign.start,
    );
  }

  Widget _buildSortHeaderCell(String title) {
    final controller = Get.find<ReservationsController>();
    return InkWell(
      onTap: () => controller.dateAscending.toggle(),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Obx(() {
          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xF0FFFFFF),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                controller.dateAscending.value
                    ? Icons.arrow_drop_up
                    : Icons.arrow_drop_down,
                size: 16,
                color: const Color(0xF0FFFFFF),
              ),
            ],
          );
        }),
      ),
    );
  }
}
