import 'package:client_web/controllers/reservations/forms/add_reservation_form_controller.dart';
import 'package:client_web/controllers/reservations/reservations_controller.dart';
import 'package:client_web/models/enum/reservation_source.dart';
import 'package:client_web/models/enum/reservation_status.dart';
import 'package:client_web/models/reservation_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Add/Edit Reservation Dialog (GetView Version)
class AddReservationDialog extends GetView<ReservationsController> {
  final ReservationModel?
  existingReservation; // ← NEW: null = Add, not null = Edit

  const AddReservationDialog({
    Key? key,
    this.existingReservation, // ← NEW
  }) : super(key: key);

  /// Check if in Edit mode
  bool get isEditMode => existingReservation != null;

  @override
  Widget build(BuildContext context) {
    // Create form controller with existing data
    final formController = Get.put(
      AddReservationFormController(existingReservation: existingReservation),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 750),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, formController),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formController.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNameField(formController),
                      const SizedBox(height: 16),
                      _buildPhoneField(formController),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(context, formController),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTimeField(context, formController),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildPartySizeField(formController)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildSourceField(formController)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildStatusField(formController),
                      const SizedBox(height: 16),
                      _buildNoteField(formController),
                    ],
                  ),
                ),
              ),
            ),
            _buildActions(context, formController),
          ],
        ),
      ),
    );
  }

  /// Header
  Widget _buildHeader(
    BuildContext context,
    AddReservationFormController formController,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF5697C6),
        borderRadius: BorderRadius.only(
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
              isEditMode ? Icons.edit : Icons.add_circle_outline, // ← CHANGED
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditMode
                      ? 'Chỉnh sửa đặt chỗ'
                      : 'Thêm đặt chỗ mới', // ← CHANGED
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEditMode
                      ? 'Cập nhật thông tin đặt chỗ'
                      : 'Điền thông tin khách hàng và thời gian đặt chỗ', // ← CHANGED
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Get.delete<AddReservationFormController>();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Đóng',
          ),
        ],
      ),
    );
  }

  /// Name field
  Widget _buildNameField(AddReservationFormController formController) {
    return TextFormField(
      controller: formController.nameController,
      decoration: InputDecoration(
        labelText: 'Tên khách hàng *',
        hintText: 'Nhập tên khách hàng',
        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF5697C6)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5697C6), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Vui lòng nhập tên khách hàng';
        }
        if (value.trim().length < 2) {
          return 'Tên phải có ít nhất 2 ký tự';
        }
        return null;
      },
      textCapitalization: TextCapitalization.words,
    );
  }

  /// Phone field
  Widget _buildPhoneField(AddReservationFormController formController) {
    return TextFormField(
      controller: formController.phoneController,
      decoration: InputDecoration(
        labelText: 'Số điện thoại *',
        hintText: '0901234567',
        prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF5697C6)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5697C6), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
      ),
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(20),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Vui lòng nhập số điện thoại';
        }
        final len = value.length;
        if (len < 8) {
          return 'Số điện thoại phải lớn hơn 8 số';
        }
        if (len > 18) {
          return 'Số điện thoại không lớn hơn 18 số';
        }
        return null;
      },
    );
  }

  /// Date field
  Widget _buildDateField(
    BuildContext context,
    AddReservationFormController formController,
  ) {
    return Obx(
      () => InkWell(
        onTap: () => formController.selectDate(context),
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Ngày đặt *',
            prefixIcon: const Icon(
              Icons.calendar_today,
              color: Color(0xFF5697C6),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF5697C6), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            errorText: formController.selectedDate.value == null
                ? 'Vui lòng chọn ngày'
                : null,
          ),
          child: Text(
            formController.selectedDate.value == null
                ? 'Chọn ngày'
                : DateFormat(
                    'dd-MM-yyyy',
                  ).format(formController.selectedDate.value!),
            style: TextStyle(
              fontSize: 16,
              color: formController.selectedDate.value == null
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF1E293B),
            ),
          ),
        ),
      ),
    );
  }

  /// Time field
  Widget _buildTimeField(
    BuildContext context,
    AddReservationFormController formController,
  ) {
    return Obx(() {
      final hasError =
          formController.selectedTime.value != null &&
          !formController.isTimeWithinOpeningHours(
            formController.selectedTime.value!,
          );

      return InkWell(
        onTap: () => formController.selectTime(context),
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Giờ đặt *',
            helperText: 'Giờ mở cửa: ${formController.openingHoursRange}',
            helperStyle: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
            prefixIcon: const Icon(Icons.access_time, color: Color(0xFF5697C6)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.red.shade300 : const Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.red : const Color(0xFF5697C6),
                width: 2,
              ),
            ),
            filled: true,
            fillColor: hasError ? Colors.red.shade50 : const Color(0xFFF8F9FA),
            errorText: formController.selectedTime.value == null
                ? 'Vui lòng chọn giờ'
                : (hasError
                      ? 'Giờ đặt phải trong khoảng ${formController.openingHoursRange}'
                      : null),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  formController.selectedTime.value == null
                      ? 'Chọn giờ'
                      : '${formController.selectedTime.value!.hour.toString().padLeft(2, '0')}:${formController.selectedTime.value!.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 16,
                    color: formController.selectedTime.value == null
                        ? const Color(0xFF94A3B8)
                        : hasError
                        ? Colors.red.shade700
                        : const Color(0xFF1E293B),
                    fontWeight: hasError ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (hasError)
                Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
            ],
          ),
        ),
      );
    });
  }

  /// Party size field
  Widget _buildPartySizeField(AddReservationFormController formController) {
    return TextFormField(
      controller: formController.partySizeController,
      decoration: InputDecoration(
        labelText: 'Số người *',
        hintText: '1-20',
        prefixIcon: const Icon(Icons.people_outline, color: Color(0xFF5697C6)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5697C6), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Vui lòng nhập số người';
        }
        final size = int.tryParse(value);
        if (size == null || size < 1 || size > 20) {
          return 'Số người phải từ 1-20';
        }
        return null;
      },
    );
  }

  Widget _buildSourceField(AddReservationFormController formController) {
    // ← NEW: Read-only in Edit mode
    if (isEditMode) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: 'Nguồn',
          prefixIcon: const Icon(
            Icons.source_outlined,
            color: Color(0xFF64748B),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          filled: true,
          fillColor: Colors.grey.shade100, // Gray background for read-only
        ),
        child: Row(
          children: [
            _getSourceIcon(existingReservation!.source),
            const SizedBox(width: 8),
            Text(
              existingReservation!.source.displayName,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Không thể sửa',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Obx(
      () => DropdownButtonFormField<ReservationSource>(
        value: formController.selectedSource.value,
        decoration: InputDecoration(
          labelText: 'Nguồn',
          prefixIcon: const Icon(
            Icons.source_outlined,
            color: Color(0xFF5697C6),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF5697C6), width: 2),
          ),
          filled: true,
          fillColor: const Color(0xFFF8F9FA),
        ),
        items: ReservationSource.values.map((source) {
          return DropdownMenuItem(
            value: source,
            child: Row(
              children: [
                _getSourceIcon(source),
                const SizedBox(width: 8),
                Text(source.displayName),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            formController.selectedSource.value = value;
          }
        },
      ),
    );
  }

  /// Status field
  Widget _buildStatusField(AddReservationFormController formController) {
    return Obx(
      () => DropdownButtonFormField<ReservationStatus>(
        value: formController.selectedStatus.value,
        decoration: InputDecoration(
          labelText: 'Trạng thái *',
          prefixIcon: const Icon(Icons.info_outline, color: Color(0xFF5697C6)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF5697C6), width: 2),
          ),
          filled: true,
          fillColor: const Color(0xFFF8F9FA),
        ),
        items: ReservationStatus.values.map((status) {
          return DropdownMenuItem(
            value: status,
            child: Row(
              children: [
                _getStatusIcon(status),
                const SizedBox(width: 8),
                Text(
                  status.displayName,
                  style: TextStyle(
                    color: _hexToColor(status.colorHex),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            formController.selectedStatus.value = value;
          }
        },
      ),
    );
  }

  /// Note field
  Widget _buildNoteField(AddReservationFormController formController) {
    return TextFormField(
      controller: formController.noteController,
      decoration: InputDecoration(
        labelText: 'Ghi chú (tùy chọn)',
        hintText: 'Thêm ghi chú về đặt chỗ...',
        prefixIcon: const Icon(Icons.note_outlined, color: Color(0xFF5697C6)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5697C6), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
      ),
      maxLines: 3,
      maxLength: 200,
    );
  }

  Widget _buildActions(
    BuildContext context,
    AddReservationFormController formController,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () {
              Get.delete<AddReservationFormController>();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Hủy',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Obx(() {
            final isProcessing = isEditMode
                ? controller.isUpdating.value
                : controller.isCreating.value;

            return ElevatedButton.icon(
              onPressed: isProcessing
                  ? null
                  : () => formController.handleSubmit(context),
              icon: isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(isEditMode ? Icons.save : Icons.check, size: 20),
              label: Text(
                isProcessing
                    ? (isEditMode ? 'Đang cập nhật...' : 'Đang tạo...')
                    : (isEditMode ? 'Cập nhật' : 'Tạo đặt chỗ'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5697C6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Helper: Get source icon
  Widget _getSourceIcon(ReservationSource source) {
    IconData iconData;
    switch (source) {
      case ReservationSource.phone:
        iconData = Icons.phone;
        break;
      case ReservationSource.website:
        iconData = Icons.web;
        break;
      case ReservationSource.walkin:
        iconData = Icons.directions_walk;
        break;
      case ReservationSource.other:
        iconData = Icons.more_horiz;
        break;
    }
    return Icon(iconData, size: 18, color: const Color(0xFF5697C6));
  }

  /// Helper: Get status icon
  Widget _getStatusIcon(ReservationStatus status) {
    IconData iconData;
    switch (status) {
      case ReservationStatus.pending:
        iconData = Icons.schedule;
        break;
      case ReservationStatus.confirmed:
        iconData = Icons.check_circle_outline;
        break;
      case ReservationStatus.arrived:
        iconData = Icons.check_circle;
        break;
      case ReservationStatus.noShow:
        iconData = Icons.cancel;
        break;
    }
    return Icon(iconData, size: 18, color: _hexToColor(status.colorHex));
  }

  /// Helper: Convert hex to Color
  Color _hexToColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
}
