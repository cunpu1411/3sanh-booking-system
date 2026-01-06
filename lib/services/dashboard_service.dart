import 'package:client_web/models/enum/reservation_source.dart';
import 'package:client_web/models/enum/reservation_status.dart';
import 'package:client_web/models/metrics_model.dart';
import 'package:client_web/models/reservation_model.dart';
import 'package:client_web/services/reservation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' show DateFormat;

class DashboardService {
  final ReservationService _reservationService;
  DashboardService(this._reservationService);

  /// Get today's reservations
  Future<List<ReservationModel>> getTodayReservations() async {
    final today = DateTime.now();
    return await _reservationService.getReservationByDate(today);
  }

  /// Get reservations for date range
  Future<List<ReservationModel>> getReservationsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await _reservationService.getReservationByDateRange(
      startDate,
      endDate,
    );
  }

  /// Get last 7 days reservations
  Future<List<ReservationModel>> getLast7DaysReservations() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));
    return await getReservationsForDateRange(sevenDaysAgo, now);
  }

  /// Get last 30 days reservations
  Future<List<ReservationModel>> getLast30DaysReservations() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 29));
    return await getReservationsForDateRange(thirtyDaysAgo, now);
  }

  /// ============ CALCULATE METRICS FROM RESERVATIONS ============

  /// Calculate metrics for a specific date
  DailyMetrics calculateDailyMetrics(
    String date,
    List<ReservationModel> reservations,
  ) {
    int totalReservations = reservations.length;
    int pending = 0;
    int confirmed = 0;
    int arrived = 0;
    int noShow = 0;
    int totalGuests = 0;
    int lunchCount = 0;
    int dinnerCount = 0;
    int sourcePhone = 0;
    int sourceWebsite = 0;
    int sourceWalkin = 0;

    Map<String, int> hourlyDistribution = {};
    Map<String, int> partySizeDistribution = {};

    for (var reservation in reservations) {
      // Count by status
      switch (reservation.status) {
        case ReservationStatus.pending:
          pending++;
          break;
        case ReservationStatus.confirmed:
          confirmed++;
          break;
        case ReservationStatus.arrived:
          arrived++;
          break;
        case ReservationStatus.noShow:
          noShow++;
          break;
      }

      // Total guests
      totalGuests += reservation.partySize;

      // Count by time period (lunch/dinner)
      final timeParts = reservation.time.split(':');
      if (timeParts.length == 2) {
        final hour = int.tryParse(timeParts[0]) ?? 0;
        if (hour >= 9 && hour < 14) {
          lunchCount++;
        } else if (hour >= 17 && hour <= 23) {
          dinnerCount++;
        }

        // Hourly distribution
        final hourKey = hour.toString();
        hourlyDistribution[hourKey] = (hourlyDistribution[hourKey] ?? 0) + 1;
      }

      // Count by source
      switch (reservation.source) {
        case ReservationSource.phone:
          sourcePhone++;
          break;
        case ReservationSource.website:
          sourceWebsite++;
          break;
        case ReservationSource.walkin:
          sourceWalkin++;
          break;
        case ReservationSource.other:
          break;
      }

      // Party size distribution
      final sizeKey = reservation.partySize.toString();
      partySizeDistribution[sizeKey] =
          (partySizeDistribution[sizeKey] ?? 0) + 1;
    }

    return DailyMetrics(
      date: date,
      totalReservations: totalReservations,
      pending: pending,
      confirmed: confirmed,
      arrived: arrived,
      noShow: noShow,
      totalGuests: totalGuests,
      lunchCount: lunchCount,
      dinnerCount: dinnerCount,
      sourcePhone: sourcePhone,
      sourceWebsite: sourceWebsite,
      sourceWalkin: sourceWalkin,
      hourlyDistribution: hourlyDistribution,
      partySizeDistribution: partySizeDistribution,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    );
  }

  /// ============ AGGREGATE METRICS ============

  /// Aggregate metrics for multiple days
  Map<String, dynamic> aggregateMetrics(List<DailyMetrics> metricsList) {
    if (metricsList.isEmpty) {
      return {
        'totalReservations': 0,
        'totalGuests': 0,
        'avgReservationsPerDay': 0.0,
        'avgGuestsPerReservation': 0.0,
        'cancellationRate': 0.0,
        'lunchPercentage': 0.0,
        'dinnerPercentage': 0.0,
        'sourceDistribution': {'phone': 0, 'website': 0, 'walkin': 0},
        'statusDistribution': {
          'pending': 0,
          'confirmed': 0,
          'arrived': 0,
          'noShow': 0,
        },
      };
    }

    int totalReservations = 0;
    int totalGuests = 0;
    int totalPending = 0;
    int totalConfirmed = 0;
    int totalArrived = 0;
    int totalNoShow = 0;
    int totalLunch = 0;
    int totalDinner = 0;
    int totalPhone = 0;
    int totalWebsite = 0;
    int totalWalkin = 0;

    for (var metrics in metricsList) {
      totalReservations += metrics.totalReservations;
      totalGuests += metrics.totalGuests;
      totalPending += metrics.pending;
      totalConfirmed += metrics.confirmed;
      totalArrived += metrics.arrived;
      totalNoShow += metrics.noShow;
      totalLunch += metrics.lunchCount;
      totalDinner += metrics.dinnerCount;
      totalPhone += metrics.sourcePhone;
      totalWebsite += metrics.sourceWebsite;
      totalWalkin += metrics.sourceWalkin;
    }

    final avgReservationsPerDay = totalReservations / metricsList.length;
    final avgGuestsPerReservation = totalReservations > 0
        ? totalGuests / totalReservations
        : 0.0;
    final cancellationRate = totalReservations > 0
        ? (totalNoShow / totalReservations) * 100
        : 0.0;
    final totalMeals = totalLunch + totalDinner;
    final lunchPercentage = totalMeals > 0
        ? (totalLunch / totalMeals) * 100
        : 0.0;
    final dinnerPercentage = totalMeals > 0
        ? (totalDinner / totalMeals) * 100
        : 0.0;

    return {
      'totalReservations': totalReservations,
      'totalGuests': totalGuests,
      'avgReservationsPerDay': avgReservationsPerDay,
      'avgGuestsPerReservation': avgGuestsPerReservation,
      'cancellationRate': cancellationRate,
      'lunchPercentage': lunchPercentage,
      'dinnerPercentage': dinnerPercentage,
      'sourceDistribution': {
        'phone': totalPhone,
        'website': totalWebsite,
        'walkin': totalWalkin,
      },
      'statusDistribution': {
        'pending': totalPending,
        'confirmed': totalConfirmed,
        'arrived': totalArrived,
        'noShow': totalNoShow,
      },
    };
  }

  /// ============ HELPER METHODS ============

  /// Format date to YYYY-MM-DD
  String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Get date range (last N days)
  List<String> getDateRange(int days) {
    final now = DateTime.now();
    final dates = <String>[];
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      dates.add(formatDate(date));
    }
    return dates;
  }

  /// Calculate occupancy rate
  double calculateOccupancyRate({
    required int totalReservations,
    required int totalTables,
    required int timeSlots, // Number of time slots (e.g., 2 for lunch + dinner)
  }) {
    if (totalTables == 0 || timeSlots == 0) return 0.0;
    final maxCapacity = totalTables * timeSlots;
    return (totalReservations / maxCapacity) * 100;
  }
}
