import 'package:client_web/models/reservation_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// View Reservation Dialog (Read-only)
class ViewReservationDialog extends StatelessWidget {
  final ReservationModel reservation;

  const ViewReservationDialog({Key? key, required this.reservation})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoSection(),
                    const SizedBox(height: 24),
                    _buildDateTimeSection(),
                    const SizedBox(height: 24),
                    _buildDetailsSection(),
                    if (reservation.note != null &&
                        reservation.note!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildNoteSection(),
                    ],
                    const SizedBox(height: 24),
                    _buildMetadataSection(),
                  ],
                ),
              ),
            ),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  /// Header
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _getStatusColor(reservation.status),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getStatusIcon(reservation.status),
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chi tiết đặt chỗ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    reservation.status.displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Đóng',
          ),
        ],
      ),
    );
  }

  /// Info Section (Name + Phone)
  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.person,
            iconColor: const Color(0xFF5697C6),
            label: 'Tên khách hàng',
            value: reservation.name,
            canCopy: false,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            icon: Icons.phone,
            iconColor: const Color(0xFF10B981),
            label: 'Số điện thoại',
            value: reservation.phone,
            canCopy: true,
          ),
        ],
      ),
    );
  }

  /// Date Time Section
  Widget _buildDateTimeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF5697C6).withOpacity(0.1),
            const Color(0xFF5697C6).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF5697C6).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDateTimeCard(
              icon: Icons.calendar_today,
              label: 'Ngày đặt',
              value: _formatDate(reservation.date),
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: const Color(0xFF5697C6).withOpacity(0.3),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Expanded(
            child: _buildDateTimeCard(
              icon: Icons.access_time,
              label: 'Giờ đặt',
              value: reservation.time,
            ),
          ),
        ],
      ),
    );
  }

  /// Details Section
  Widget _buildDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.people,
            iconColor: const Color(0xFFD97706),
            label: 'Số người',
            value: '${reservation.partySize} người',
            canCopy: false,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            icon: _getSourceIcon(reservation.source),
            iconColor: const Color(0xFF8B5CF6),
            label: 'Nguồn đặt',
            value: reservation.source.displayName,
            canCopy: false,
          ),
        ],
      ),
    );
  }

  /// Note Section
  Widget _buildNoteSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note, color: Colors.amber.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Ghi chú',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            reservation.note!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.amber.shade900,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Metadata Section
  Widget _buildMetadataSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin hệ thống',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetadataItem(
                  label: 'ID',
                  value: reservation.id.substring(0, 8) + '...',
                ),
              ),
              Expanded(
                child: _buildMetadataItem(
                  label: 'Tạo lúc',
                  value: _formatTimestamp(reservation.createdAt),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Actions
  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Đóng'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5697C6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper: Build info row
  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool canCopy,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
        if (canCopy)
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            color: const Color(0xFF64748B),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
            },
            tooltip: 'Copy',
          ),
      ],
    );
  }

  /// Helper: Build date/time card
  Widget _buildDateTimeCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF5697C6), size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  /// Helper: Build metadata item
  Widget _buildMetadataItem({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  /// Helper: Format date
  String _formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  /// Helper: Format timestamp
  String _formatTimestamp(dynamic timestamp) {
    try {
      if (timestamp == null) return 'N/A';
      final date = timestamp.toDate();
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return 'N/A';
    }
  }

  /// Helper: Get status icon
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

  /// Helper: Get status color
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

  /// Helper: Get source icon
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
}
