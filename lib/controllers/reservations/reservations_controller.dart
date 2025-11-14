import 'dart:async';

import 'package:client_web/helpers/snackbar_helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReservationsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Search & Filters
  final searchQuery = ''.obs;
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  final showOnlyNotArrived = false.obs;
  final showReservationsToday = false.obs;
  final showReservationsThisWeek = false.obs;
  final Rx<DateTimeRange?> dateRangeFilter = Rx<DateTimeRange?>(null);

  /// Data
  final reservations = <QueryDocumentSnapshot<Map<String, dynamic>>>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final Rx<QueryDocumentSnapshot<Map<String, dynamic>>?> selectedReservation =
      Rx<QueryDocumentSnapshot<Map<String, dynamic>>?>(null);
  final isUpdating = false.obs;

  /// Helpers
  final dateAscending = false.obs;
  bool _isManuallySettingDateRange = false;

  /// Debounce
  Timer? _debounceTimer;

  /// =============== Lifecycle Methods ===============
  @override
  void onInit() {
    super.onInit();
    _listenReservations();
    _setupSearchListener();
    _setUpQuickFilters();
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.onClose();
  }

  /// =============== Search & Filters ===============
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get filteredReservations {
    var reservations = this.reservations.toList();
    final query = searchQuery.value.toLowerCase();
    if (query.isNotEmpty) {
      reservations = reservations.where((doc) {
        final res = doc.data();
        final name = (res['name'] ?? '').toString().toLowerCase();
        final phone = (res['phone'] ?? '').toString().toLowerCase();
        final id = (res['id'] ?? '').toString().toLowerCase();
        return name.contains(query) ||
            phone.contains(query) ||
            id.contains(query);
      }).toList();
    }

    if (showOnlyNotArrived.value) {
      reservations = reservations.where((doc) {
        final data = doc.data();
        final arrived = data['arrived'] ?? false;
        return arrived == false;
      }).toList();
    }
    if (dateRangeFilter.value != null) {
      final start = dateRangeFilter.value!.start;
      final end = dateRangeFilter.value!.end;
      reservations = reservations.where((doc) {
        final data = doc.data();
        final dateValue = data['date'];
        if (dateValue == null) return false;
        DateTime? date;
        try {
          date = DateTime.parse(dateValue);
        } catch (e) {
          print('Error parsing date to string');
          return false;
        }
        final resDate = DateTime(date.year, date.month, date.day);
        final startDate = DateTime(start.year, start.month, start.day);
        final endDate = DateTime(end.year, end.month, end.day);
        return (resDate.isAtSameMomentAs(startDate) ||
                resDate.isAfter(startDate)) &&
            (resDate.isAtSameMomentAs(endDate) ||
                resDate.isBefore(endDate.add(Duration(days: 1))));
      }).toList();
    }
    sortByDate(reservations);
    return reservations;
  }

  void _setupSearchListener() {
    searchController.addListener(() {
      _onSearchChanged();
    });
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      searchQuery.value = searchController.text;
    });
  }

  void setSelectedReservation(
    QueryDocumentSnapshot<Map<String, dynamic>> reservation,
  ) {
    selectedReservation.value = reservation;
  }

  void _setUpQuickFilters() {
    everAll([showReservationsToday, showReservationsThisWeek], (_) {
      if (_isManuallySettingDateRange) return;

      final isToday = showReservationsToday.value;
      final isWeek = showReservationsThisWeek.value;

      if (isToday) {
        final today = DateTime.now();
        setDateRangeFilter(
          DateTimeRange(
            start: DateTime(today.year, today.month, today.day),
            end: DateTime(today.year, today.month, today.day, 23, 59, 59),
          ),
          fromQuickFilter: true,
        );
      } else if (isWeek) {
        final today = DateTime.now();
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final start = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        );
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        final end = DateTime(
          endOfWeek.year,
          endOfWeek.month,
          endOfWeek.day,
          23,
          59,
          59,
        );
        setDateRangeFilter(
          DateTimeRange(start: start, end: end),
          fromQuickFilter: true,
        );
      } else {
        dateRangeFilter.value = null;
      }
    });
  }

  void setDateRangeFilter(
    DateTimeRange? dateRange, {
    bool fromQuickFilter = true,
  }) {
    dateRangeFilter.value = dateRange;
    if (!fromQuickFilter) {
      _isManuallySettingDateRange = true;
      showReservationsToday.value = false;
      showReservationsThisWeek.value = false;
      _isManuallySettingDateRange = false;
    }
  }

  void dateRangePicker(BuildContext context) {
    _showDateRangePicker(context);
  }

  /// =============== Firestore steams ===============
  void _listenReservations() {
    isLoading.value = true;
    errorMessage.value = '';
    _firestore
        .collection('reservations')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            try {
              reservations.value = snapshot.docs.toList();
            } catch (e) {
              errorMessage.value = 'Failed to parse reservations: $e';
            } finally {
              isLoading.value = false;
            }
          },
          onError: (error) {
            errorMessage.value = 'Failed to load reservations: $error';
            isLoading.value = false;
          },
        );
  }

  Future<void> toggleArrived(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    if (isUpdating.value) return;
    try {
      isUpdating.value = true;
      final currentState = doc.data()['arrived'] as bool? ?? false;
      await doc.reference.update({'arrived': !currentState});
      if (context.mounted) {
        SnackbarHelper.showSuccess(
          context,
          currentState ? 'Chưa đến' : 'Đã đến',
        );
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showError(context, 'Lỗi: không thay đổi trang thái');
      }
    } finally {
      isUpdating.value = false;
    }
  }

  /// =============== Helpers ===============
  /// Sorting
  void sortByDate(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> reservations,
  ) {
    reservations.sort((a, b) {
      DateTime dateA = DateTime.parse(a.data()['date']);
      DateTime dateB = DateTime.parse(b.data()['date']);
      final timeA = a.data()['time'];
      final timeB = b.data()['time'];
      final dateTimeA = _combineDateAndTime(dateA, timeA);
      final dateTimeB = _combineDateAndTime(dateB, timeB);

      return dateAscending.value == true
          ? dateTimeA.compareTo(dateTimeB)
          : dateTimeB.compareTo(dateTimeA);
    });
  }

  DateTime _combineDateAndTime(DateTime date, String time) {
    final parts = time.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    return DateTime(date.year, date.month, date.day, hours, minutes);
  }

  void setQuickFilers({bool today = false, bool week = false}) {
    showReservationsToday.value = today;
    showReservationsThisWeek.value = week;
  }

  /// Show delete dialog
  void showDeleteDialog({
    required BuildContext context,
    required QueryDocumentSnapshot<Map<String, dynamic>> reservation,
  }) async {
    final data = reservation.data();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.red, size: 28),
              const SizedBox(width: 16),
              Text('Xác nhận xóa'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bạn có muốn xóa đặt chỗ không ?',
                style: TextStyle(fontSize: 20),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  color: Colors.grey.shade200.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildInfoRow(
                      'Ngày',
                      _formatDateTime(data['date'], data['time']),
                    ),
                    const SizedBox(height: 4),
                    _buildInfoRow('Tên', data['name'] ?? 'N/A'),
                    const SizedBox(height: 4),
                    _buildInfoRow('SDT', data['phone'] ?? 'N/A'),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text('Hủy', style: TextStyle(color: Colors.grey.shade700)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true); // Trả về true khi xác nhận
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Xóa'),
            ),
          ],
        );
      },
    );
    if (!context.mounted) return;
    if (result == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        await reservation.reference.delete();
        if (context.mounted) {
          Navigator.of(context).pop();
          SnackbarHelper.showSuccess(context, 'Đã được xóa');
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop();
          SnackbarHelper.showError(context, 'Không thể xóa: $e');
        }
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Show date range picker
  void _showDateRangePicker(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
      initialDateRange: dateRangeFilter.value,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5697C6),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
            datePickerTheme: DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              headerBackgroundColor: const Color(0xFF5697C6),
              headerForegroundColor: Colors.white,
              dayStyle: const TextStyle(fontSize: 14),
              yearStyle: const TextStyle(fontSize: 16),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setDateRangeFilter(picked);
    }
  }

  void cleanQuickFiltersDateRange() {
    showReservationsToday.value = false;
    showReservationsThisWeek.value = false;
  }

  String _formatDateTime(dynamic dateValue, dynamic timeValue) {
    if (dateValue == null) return 'N/A';
    try {
      final date = DateTime.parse(dateValue);
      final time = timeValue?.toString() ?? '';

      final dateStr =
          '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';

      if (time.isNotEmpty) {
        return '$time - $dateStr';
      }
      return dateStr;
    } catch (e) {
      return 'N/A';
    }
  }

  String get formattedDateRange {
    if (dateRangeFilter.value == null) return '';
    final start = dateRangeFilter.value!.start;
    final end = dateRangeFilter.value!.end;
    return '${start.day}/${start.month} - ${end.day}/${end.month}';
  }
}
