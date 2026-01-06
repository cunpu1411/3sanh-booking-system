import 'package:client_web/controllers/reservations/reservations_controller.dart';
import 'package:client_web/models/enum/reservation_source.dart';
import 'package:client_web/models/enum/reservation_status.dart';
import 'package:client_web/models/reservation_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Form Controller for Add/Edit Reservation Dialog
class AddReservationFormController extends GetxController {
  // ============ NEW: Existing reservation (for Edit mode) ============
  final ReservationModel? existingReservation;

  AddReservationFormController({this.existingReservation});

  /// Check if in Edit mode
  bool get isEditMode => existingReservation != null;

  // ============ FORM KEY ============
  final formKey = GlobalKey<FormState>();

  // ============ TEXT CONTROLLERS ============
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final partySizeController = TextEditingController(text: '2');
  final noteController = TextEditingController();

  // ============ OBSERVABLE VALUES ============
  final Rx<DateTime?> selectedDate = Rx<DateTime?>(null);
  final Rx<TimeOfDay?> selectedTime = Rx<TimeOfDay?>(null);
  final selectedSource = ReservationSource.walkin.obs;
  final selectedStatus = ReservationStatus.arrived.obs;

  final openingTime = const TimeOfDay(hour: 8, minute: 30).obs;
  final closingTime = const TimeOfDay(hour: 22, minute: 0).obs;

  /// Set custom opening hours
  void setOpeningHours({TimeOfDay? opening, TimeOfDay? closing}) {
    if (opening != null) {
      openingTime.value = opening;
    }
    if (closing != null) {
      closingTime.value = closing;
    }
  }

  /// Get opening time as string (HH:mm)
  String get openingTimeString =>
      '${openingTime.value.hour.toString().padLeft(2, '0')}:${openingTime.value.minute.toString().padLeft(2, '0')}';

  /// Get closing time as string (HH:mm)
  String get closingTimeString =>
      '${closingTime.value.hour.toString().padLeft(2, '0')}:${closingTime.value.minute.toString().padLeft(2, '0')}';

  /// Get opening hours range as string
  String get openingHoursRange => '$openingTimeString - $closingTimeString';

  // ============ LIFECYCLE ============
  @override
  void onInit() {
    super.onInit();
    setOpeningHours(
      opening: const TimeOfDay(hour: 9, minute: 30),
      closing: const TimeOfDay(hour: 23, minute: 0),
    );

    if (isEditMode) {
      _prefillData();
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    partySizeController.dispose();
    noteController.dispose();
    super.onClose();
  }

  // ============ NEW: Pre-fill data for Edit mode ============
  void _prefillData() {
    if (existingReservation == null) return;

    final reservation = existingReservation!;

    // Fill text fields
    nameController.text = reservation.name;
    phoneController.text = reservation.phone;
    partySizeController.text = reservation.partySize.toString();
    noteController.text = reservation.note ?? '';

    // Parse and set date (format: YYYY-MM-DD)
    try {
      final dateParts = reservation.date.split('-');
      if (dateParts.length == 3) {
        final year = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final day = int.parse(dateParts[2]);
        selectedDate.value = DateTime(year, month, day);
      }
    } catch (e) {
      print('Error parsing date: $e');
    }

    // Parse and set time (format: HH:mm)
    try {
      final timeParts = reservation.time.split(':');
      if (timeParts.length == 2) {
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        selectedTime.value = TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      print('Error parsing time: $e');
    }

    // Set source and status
    selectedSource.value = reservation.source;
    selectedStatus.value = reservation.status;
  }

  // ============ DATE & TIME SELECTION ============

  /// Select date
  Future<void> selectDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5697C6),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      selectedDate.value = picked;
    }
  }

  /// Select time with validation
  Future<void> selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          selectedTime.value ??
          TimeOfDay(hour: openingTime.value.hour, minute: 0),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5697C6),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      selectedTime.value = picked;
      // Validate time is within opening hours
      if (!isTimeWithinOpeningHours(picked)) {
        Get.snackbar(
          'Lỗi',
          'Giờ đặt phải trong khoảng $openingHoursRange',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.access_time, color: Colors.white),
        );
        return;
      }
    }
  }

  /// Check if time is within opening hours
  bool isTimeWithinOpeningHours(TimeOfDay time) {
    final timeInMinutes = time.hour * 60 + time.minute;
    final openingInMinutes =
        openingTime.value.hour * 60 + openingTime.value.minute;
    final closingInMinutes =
        closingTime.value.hour * 60 + closingTime.value.minute;

    return timeInMinutes >= openingInMinutes &&
        timeInMinutes <= closingInMinutes;
  }

  /// Validate selected time (for form submission)
  String? validateTime() {
    if (selectedTime.value == null) {
      return 'Vui lòng chọn giờ';
    }

    if (!isTimeWithinOpeningHours(selectedTime.value!)) {
      return 'Giờ đặt phải trong khoảng $openingHoursRange';
    }

    return null;
  }

  // ============ FORM SUBMISSION ============

  /// Handle submit - ← MODIFIED: Handle both Add and Edit
  Future<void> handleSubmit(BuildContext context) async {
    // Validate form
    if (!formKey.currentState!.validate()) {
      return;
    }

    // Validate date
    if (selectedDate.value == null) {
      Get.snackbar(
        'Lỗi',
        'Vui lòng chọn ngày đặt',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // Validate time
    if (selectedTime.value == null) {
      Get.snackbar(
        'Lỗi',
        'Vui lòng chọn giờ đặt',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // Format date (YYYY-MM-DD)
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value!);

    // Format time (HH:mm)
    final timeStr =
        '${selectedTime.value!.hour.toString().padLeft(2, '0')}:${selectedTime.value!.minute.toString().padLeft(2, '0')}';

    // Get main controller
    final reservationsController = Get.find<ReservationsController>();

    // ← NEW: Call different methods based on mode
    if (isEditMode) {
      // Edit mode
      await reservationsController.updateReservation(
        context: context,
        id: existingReservation!.id,
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        date: dateStr,
        time: timeStr,
        partySize: int.parse(partySizeController.text),
        status: selectedStatus.value,
        note: noteController.text.trim().isEmpty
            ? null
            : noteController.text.trim(),
      );
    } else {
      // Add mode
      await reservationsController.createReservation(
        context: context,
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        date: dateStr,
        time: timeStr,
        partySize: int.parse(partySizeController.text),
        source: selectedSource.value,
        status: selectedStatus.value,
        note: noteController.text.trim(),
      );
    }
  }

  // ============ HELPERS ============

  /// Reset form
  void resetForm() {
    nameController.clear();
    phoneController.clear();
    partySizeController.text = '2';
    noteController.clear();
    selectedDate.value = null;
    selectedTime.value = null;
    selectedSource.value = ReservationSource.walkin;
    selectedStatus.value = ReservationStatus.arrived;
  }
}
