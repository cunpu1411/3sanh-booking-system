import 'package:client_web/controllers/reservations/reservations_controller.dart';
import 'package:client_web/models/enum/reservation_status.dart';
import 'package:client_web/models/reservation_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ReservationsRow extends StatefulWidget {
  const ReservationsRow({
    super.key,
    required this.reservation,
    required this.onTap,
    required this.isDark,
  });
  final ReservationModel reservation;
  final VoidCallback onTap;
  final bool isDark;
  @override
  State<ReservationsRow> createState() => _ReservationsRowState();
}

class _ReservationsRowState extends State<ReservationsRow> {
  final controller = Get.find<ReservationsController>();
  bool isHovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: () => widget.onTap(),
        onDoubleTap: () => controller.showViewDialog(
          context: context,
          reservation: widget.reservation,
        ),
        child: Obx(() => _buildRow()),
      ),
    );
  }

  Widget _buildRow() {
    final isSelected =
        controller.selectedReservation.value == widget.reservation;
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: isSelected
            ? widget.isDark
                  ? Colors.blue.shade300
                  : Colors.blue.shade100
            : isHovered
            ? widget.isDark
                  ? Colors.grey.shade400
                  : Colors.grey.shade200
            : widget.isDark
            ? Colors.grey.shade300
            : Colors.white70,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ), // Lighter border
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          /// Name Cell
          Expanded(child: _buildCell(widget.reservation.name)),

          /// Contact Cell
          Expanded(child: _buildContactCell()),

          /// Date time cell
          Expanded(child: _buildDateTimeCell()),

          /// Guests Cell
          Expanded(child: _buildGuestsCell()),

          /// Note
          Flexible(flex: 3, fit: FlexFit.tight, child: _buildNoteCell()),

          /// Status
          Expanded(child: _buildStatusDropdown()),

          /// Actions
          Expanded(child: _buildActions()),
        ],
      ),
    );
  }

  /// Build a standard cell with text
  Widget _buildCell(String text, {bool centered = true}) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1E293B), // Dark slate for better contrast
        height: 1.4,
      ),
      textAlign: centered ? TextAlign.center : TextAlign.start,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Build contact cell with phone number and copy button
  Widget _buildContactCell() {
    final contact = widget.reservation.phone;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          contact ?? 'N/A',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF334155), // Medium dark for readability
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(width: 8),
        contact != null
            ? Tooltip(
                message: 'Copy phone number',
                child: InkWell(
                  onTap: () => _copyPhoneNumber(),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(6), // Compact padding
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF), // Light blue background
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFBFDBFE), // Blue border
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.phone,
                      size: 12, // Slightly smaller icon
                      color: Colors.blue, // Vibrant blue
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }

  /// Copy phone number to clipboard
  void _copyPhoneNumber() {
    Clipboard.setData(ClipboardData(text: widget.reservation.phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              'Phone number copied: ${widget.reservation.phone}',
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF10B981), // Green for success
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Build date and time cell with icons
  Widget _buildDateTimeCell() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Date row
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              Icons.calendar_today,
              size: 14,
              color: widget.isDark
                  ? Colors.black
                  : Color(0xFF64748B), // Medium gray
            ),
            const SizedBox(width: 6),
            Text(
              widget.reservation.date,
              style: TextStyle(
                fontSize: 13,
                color: widget.isDark
                    ? Colors.black
                    : Color(0xFF475569), // Dark gray
                fontWeight: FontWeight.w500,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Time row
        Padding(
          padding: EdgeInsets.only(right: 35),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: widget.isDark ? Colors.black : Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                widget.reservation.time,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  overflow: TextOverflow.ellipsis,
                  color: Color(0xFF1E293B), // Darker for emphasis
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build guests cell with icon and highlight for large groups
  Widget _buildGuestsCell() {
    final partySize = widget.reservation.partySize as int? ?? 0;
    final isLargeGroup = partySize >= 6;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people,
            size: 16,
            color: isLargeGroup
                ? const Color(0xFFD97706) // Orange for large groups
                : const Color(0xFF181C20), // Gray for normal
          ),
          const SizedBox(width: 4),
          Text(
            partySize.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isLargeGroup
                  ? const Color(0xFFD97706)
                  : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  /// Build note cell with tooltip for full text
  Widget _buildNoteCell() {
    return widget.reservation.note != null && widget.reservation.note.isNotEmpty
        ? Tooltip(
            message: widget.reservation.note,
            preferBelow: false,
            waitDuration: const Duration(milliseconds: 300),
            showDuration: const Duration(seconds: 5),
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B), // Dark slate
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            textStyle: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              height: 1.5,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.orange.withValues(alpha: 0.3)
                    : Color(0xFFFEF3C7), // Light yellow background
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFBBF24), // Yellow border
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.note,
                    size: 14,
                    color: Color(0xFFD97706), // Orange
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      truncatedNote(widget.reservation.note),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF92400E), // Dark orange
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          )
        : const Text(
            'N/A',
            style: TextStyle(fontSize: 14, color: Colors.black), // Light gray
          );
  }

  /// Build status cell with colored badge
  Widget _buildStatusCell() {
    final status = widget.reservation.status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: widget.reservation.status.value == 'arrived'
            ? Colors.green.shade100
            : Colors.orange.shade100,
        border: Border.all(
          color: widget.reservation.status.value == 'arrived'
              ? Colors.green.shade100.withValues(alpha: 0.3)
              : Colors.orange.shade100.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16), // More rounded
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.reservation.status.value == 'arrived'
                ? Icons.check_circle
                : Icons.schedule,
            size: 14,
            color: widget.reservation.status.value == 'arrived'
                ? Colors.green.shade800
                : Colors.orange.shade800,
          ),
          const SizedBox(width: 6), // Slightly more space
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600, // Bolder text
              color: widget.reservation.status.value == 'arrived'
                  ? Colors.green.shade800
                  : Colors.orange.shade800,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150), // ← Giới hạn width
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ReservationStatus>(
          value: widget.reservation.status,
          isDense: true,
          isExpanded: true, // ← Quan trọng: Cho phép expand trong container
          icon: const Icon(Icons.arrow_drop_down, size: 18),
          borderRadius: BorderRadius.circular(12),
          onChanged: (ReservationStatus? newStatus) {
            if (newStatus != null && newStatus != widget.reservation.status) {
              controller.updateReservationStatus(
                context: context,
                reservationId: widget.reservation.id,
                newStatus: newStatus,
              );
            }
          },
          items: ReservationStatus.values.map((status) {
            return DropdownMenuItem<ReservationStatus>(
              value: status,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getStatusIcon(status),
                    size: 12,
                    color: _getStatusColor(status),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    // ← Thay Text bằng Flexible
                    child: Text(
                      status.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(status),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          selectedItemBuilder: (BuildContext context) {
            return ReservationStatus.values.map((status) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withValues(alpha: 0.15),
                  border: Border.all(
                    color: _getStatusColor(status).withValues(alpha: 0.3),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(status),
                      size: 12,
                      color: _hexToColor(status.colorHex),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      // ← Thay Text bằng Flexible
                      child: Text(
                        status.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(status),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Tooltip(
          message: 'Chỉnh sửa',
          preferBelow: false,
          waitDuration: const Duration(milliseconds: 500),
          child: IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: const Color(0xFF5697C6),
            onPressed: () {
              controller.showEditDialog(
                context: context,
                reservation: widget.reservation,
              );
            },
            splashRadius: 20,
            padding: const EdgeInsets.all(8),
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: 'Xóa',
          preferBelow: false,
          child: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              controller.showDeleteDialog(
                context: context,
                reservation: widget.reservation,
              );
            },
          ),
        ),
      ],
    );
  }

  ///=== Helpers ====
  /// Get status icon
  IconData _getStatusIcon(dynamic status) {
    final statusValue = status.value ?? status.toString();
    switch (statusValue) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'arrived':
        return Icons.check_circle;
      case 'noShow':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  /// Get status color
  Color _getStatusColor(dynamic status) {
    final statusValue = status.value ?? status.toString();
    switch (statusValue) {
      case 'pending':
        return Colors.orange.shade600;
      case 'confirmed':
        return Colors.blue.shade600;
      case 'arrived':
        return Colors.green.shade600;
      case 'noShow':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Color _hexToColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  /// Get source icon
  IconData _getSourceIcon(dynamic source) {
    final sourceValue = source.value ?? source.toString();
    switch (sourceValue) {
      case 'phone':
        return Icons.phone;
      case 'website':
        return Icons.web;
      case 'walkin':
        return Icons.directions_walk;
      case 'other':
        return Icons.more_horiz;
      default:
        return Icons.source;
    }
  }

  String truncatedNote(String? note) {
    if (note == null || note.isEmpty) return '—';
    if (note.length <= 40) return note;
    return '${note.substring(0, 37)}...';
  }
}
