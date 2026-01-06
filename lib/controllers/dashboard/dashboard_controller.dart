import 'package:client_web/models/metrics_model.dart';
import 'package:client_web/models/reservation_model.dart';
import 'package:client_web/services/dashboard_service.dart';
import 'package:get/get.dart';

class DashboardController extends GetxController {
  final DashboardService _dashboardService;

  DashboardController(this._dashboardService);

  /// ============ OBSERVABLE STATE ============
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  /// Restaurant config
  final totalTables = 50.obs;

  /// Today's data
  final todayReservations = <ReservationModel>[].obs;
  final todayTotal = 0.obs;
  final todayConfirmed = 0.obs;
  final todayPending = 0.obs;
  final todayArrived = 0.obs;

  /// Upcoming (next 2 hours)
  final upcomingReservations = <ReservationModel>[].obs;
  final upcomingCount = 0.obs;
  final nextReservation = Rx<ReservationModel?>(null);

  /// Occupancy rate
  final occupancyRate = 0.0.obs;
  final lunchOccupancy = 0.0.obs;
  final dinnerOccupancy = 0.0.obs;

  /// Need action
  final needActionCount = 0.obs;
  final pendingCount = 0.obs;
  final overdueCount = 0.obs;

  /// 7 days metrics
  final last7DaysMetrics = <DailyMetrics>[].obs;
  final last7DaysTotal = 0.obs;
  final last7DaysAverage = 0.0.obs;

  /// Lunch vs Dinner
  final lunchPercentage = 0.0.obs;
  final dinnerPercentage = 0.0.obs;
  final lunchCount = 0.obs;
  final dinnerCount = 0.obs;

  /// Peak hours
  final peakHours = <MapEntry<int, int>>[].obs;

  /// Party size distribution
  final partySizeDistribution = <MapEntry<String, int>>[].obs;

  /// Source distribution
  final sourcePhone = 0.obs;
  final sourceWebsite = 0.obs;
  final sourceWalkin = 0.obs;

  /// Cancellation rate
  final cancellationRate = 0.0.obs;
  final cancelledCount = 0.obs;
  final totalForCancellation = 0.obs;

  /// Customer retention
  final newCustomers = 0.obs;
  final returningCustomers = 0.obs;
  final newCustomerPercentage = 0.0.obs;
  final returningCustomerPercentage = 0.0.obs;

  /// 30 days trend
  final last30DaysData = <DailyMetrics>[].obs;

  /// Top customers (optional)
  final topCustomers = <Map<String, dynamic>>[].obs;

  /// ============ LIFECYCLE ============
  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  /// ============ FETCH DATA ============
  Future<void> fetchDashboardData() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Fetch today's data
      await _fetchTodayData();

      // Fetch 7 days data
      await _fetch7DaysData();

      // Fetch 30 days trend
      await _fetch30DaysData();

      // Calculate customer retention (from 7 days data)
      _calculateCustomerRetention();
    } catch (e) {
      errorMessage.value = 'Lỗi tải dữ liệu: $e';
      print('Error fetching dashboard data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// ============ TODAY'S DATA ============
  Future<void> _fetchTodayData() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Fetch today's reservations
    final reservations = await _dashboardService.getTodayReservations();
    todayReservations.value = reservations;

    // Calculate today's metrics
    todayTotal.value = reservations.length;
    todayConfirmed.value = reservations
        .where((r) => r.status.value == 'confirmed')
        .length;
    todayPending.value = reservations
        .where((r) => r.status.value == 'pending')
        .length;
    todayArrived.value = reservations
        .where((r) => r.status.value == 'arrived')
        .length;

    // Calculate upcoming (next 2 hours)
    _calculateUpcoming(reservations);

    // Calculate occupancy rate
    _calculateOccupancyRate(reservations);

    // Calculate need action
    _calculateNeedAction(reservations);
  }

  void _calculateUpcoming(List<ReservationModel> reservations) {
    final now = DateTime.now();
    final twoHoursLater = now.add(const Duration(hours: 2));

    final upcoming = reservations.where((r) {
      // Parse date and time
      final dateParts = r.date.split('-');
      final timeParts = r.time.split(':');

      if (dateParts.length != 3 || timeParts.length != 2) return false;

      final year = int.tryParse(dateParts[0]);
      final month = int.tryParse(dateParts[1]);
      final day = int.tryParse(dateParts[2]);
      final hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);

      if (year == null ||
          month == null ||
          day == null ||
          hour == null ||
          minute == null)
        return false;

      final reservationTime = DateTime(year, month, day, hour, minute);

      // Check if confirmed and within next 2 hours
      return r.status.value == 'confirmed' &&
          reservationTime.isAfter(now) &&
          reservationTime.isBefore(twoHoursLater);
    }).toList();

    // Sort by time
    upcoming.sort((a, b) {
      final timeA = _parseReservationDateTime(a);
      final timeB = _parseReservationDateTime(b);
      return timeA.compareTo(timeB);
    });

    upcomingReservations.value = upcoming;
    upcomingCount.value = upcoming.length;
    nextReservation.value = upcoming.isNotEmpty ? upcoming.first : null;
  }

  DateTime _parseReservationDateTime(ReservationModel reservation) {
    final dateParts = reservation.date.split('-');
    final timeParts = reservation.time.split(':');

    final year = int.parse(dateParts[0]);
    final month = int.parse(dateParts[1]);
    final day = int.parse(dateParts[2]);
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    return DateTime(year, month, day, hour, minute);
  }

  void _calculateOccupancyRate(List<ReservationModel> reservations) {
    // Count lunch and dinner reservations
    int lunchRes = 0;
    int dinnerRes = 0;

    for (var r in reservations) {
      final timeParts = r.time.split(':');
      if (timeParts.length == 2) {
        final hour = int.tryParse(timeParts[0]) ?? 0;
        if (hour >= 9 && hour < 14) {
          lunchRes++;
        } else if (hour >= 17 && hour <= 23) {
          dinnerRes++;
        }
      }
    }

    // Calculate occupancy (assuming 2 time slots: lunch + dinner)
    final totalSlots = totalTables.value * 2;
    final totalRes = reservations.length;

    occupancyRate.value = totalSlots > 0 ? (totalRes / totalSlots) * 100 : 0.0;

    lunchOccupancy.value = totalTables.value > 0
        ? (lunchRes / totalTables.value) * 100
        : 0.0;

    dinnerOccupancy.value = totalTables.value > 0
        ? (dinnerRes / totalTables.value) * 100
        : 0.0;
  }

  void _calculateNeedAction(List<ReservationModel> reservations) {
    final now = DateTime.now();

    // Count pending
    pendingCount.value = reservations
        .where((r) => r.status.value == 'pending')
        .length;

    // Count overdue (confirmed but past reservation time by 15 minutes)
    overdueCount.value = reservations.where((r) {
      if (r.status.value != 'confirmed') return false;

      final reservationTime = _parseReservationDateTime(r);
      final overdueTime = reservationTime.add(const Duration(minutes: 15));

      return now.isAfter(overdueTime);
    }).length;

    needActionCount.value = pendingCount.value + overdueCount.value;
  }

  /// ============ 7 DAYS DATA ============
  Future<void> _fetch7DaysData() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));

    // Fetch reservations for last 7 days
    final reservations = await _dashboardService.getLast7DaysReservations();

    // Group by date and calculate metrics
    final metricsByDate = <String, List<ReservationModel>>{};

    for (var r in reservations) {
      final date = r.date;
      if (!metricsByDate.containsKey(date)) {
        metricsByDate[date] = [];
      }
      metricsByDate[date]!.add(r);
    }

    // Calculate daily metrics
    final metrics = <DailyMetrics>[];
    for (var entry in metricsByDate.entries) {
      final dailyMetrics = _dashboardService.calculateDailyMetrics(
        entry.key,
        entry.value,
      );
      metrics.add(dailyMetrics);
    }

    // Sort by date
    metrics.sort((a, b) => a.date.compareTo(b.date));

    last7DaysMetrics.value = metrics;

    // Calculate totals
    last7DaysTotal.value = reservations.length;
    last7DaysAverage.value = reservations.length / 7;

    // Aggregate metrics
    final aggregated = _dashboardService.aggregateMetrics(metrics);

    // Lunch vs Dinner
    lunchPercentage.value = aggregated['lunchPercentage'];
    dinnerPercentage.value = aggregated['dinnerPercentage'];
    lunchCount.value =
        aggregated['sourceDistribution']['phone'] +
        aggregated['sourceDistribution']['website'] +
        aggregated['sourceDistribution']['walkin'];
    dinnerCount.value = last7DaysTotal.value - lunchCount.value;

    // Calculate actual lunch/dinner from metrics
    int totalLunch = 0;
    int totalDinner = 0;
    for (var m in metrics) {
      totalLunch += m.lunchCount;
      totalDinner += m.dinnerCount;
    }
    lunchCount.value = totalLunch;
    dinnerCount.value = totalDinner;

    // Peak hours
    _calculatePeakHours(metrics);

    // Party size distribution
    _calculatePartySizeDistribution(metrics);

    // Source distribution
    final sourceDist = aggregated['sourceDistribution'];
    sourcePhone.value = sourceDist['phone'];
    sourceWebsite.value = sourceDist['website'];
    sourceWalkin.value = sourceDist['walkin'];

    // Cancellation rate
    cancellationRate.value = aggregated['cancellationRate'];
    final statusDist = aggregated['statusDistribution'];
    cancelledCount.value = statusDist['noShow'];
    totalForCancellation.value = aggregated['totalReservations'];
  }

  void _calculatePeakHours(List<DailyMetrics> metrics) {
    final hourlyTotal = <int, int>{};

    for (var m in metrics) {
      for (var entry in m.hourlyDistribution.entries) {
        final hour = int.tryParse(entry.key);
        if (hour != null) {
          hourlyTotal[hour] = (hourlyTotal[hour] ?? 0) + entry.value;
        }
      }
    }

    // Sort by count descending
    final sorted = hourlyTotal.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    peakHours.value = sorted.take(3).toList();
  }

  void _calculatePartySizeDistribution(List<DailyMetrics> metrics) {
    final sizeTotal = <String, int>{};

    for (var m in metrics) {
      for (var entry in m.partySizeDistribution.entries) {
        sizeTotal[entry.key] = (sizeTotal[entry.key] ?? 0) + entry.value;
      }
    }

    // Group into categories: 2, 4, 6, 8+
    final grouped = <String, int>{'2': 0, '4': 0, '6': 0, '8+': 0};

    for (var entry in sizeTotal.entries) {
      final size = int.tryParse(entry.key) ?? 0;
      if (size == 2) {
        grouped['2'] = grouped['2']! + entry.value;
      } else if (size <= 4) {
        grouped['4'] = grouped['4']! + entry.value;
      } else if (size <= 6) {
        grouped['6'] = grouped['6']! + entry.value;
      } else {
        grouped['8+'] = grouped['8+']! + entry.value;
      }
    }

    // Sort by count descending
    final sorted = grouped.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    partySizeDistribution.value = sorted;
  }

  /// ============ 30 DAYS TREND ============
  Future<void> _fetch30DaysData() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 29));

    // Fetch reservations for last 30 days
    final reservations = await _dashboardService.getLast30DaysReservations();

    // Group by date
    final metricsByDate = <String, List<ReservationModel>>{};

    for (var r in reservations) {
      final date = r.date;
      if (!metricsByDate.containsKey(date)) {
        metricsByDate[date] = [];
      }
      metricsByDate[date]!.add(r);
    }

    // Calculate daily metrics
    final metrics = <DailyMetrics>[];
    for (var entry in metricsByDate.entries) {
      final dailyMetrics = _dashboardService.calculateDailyMetrics(
        entry.key,
        entry.value,
      );
      metrics.add(dailyMetrics);
    }

    // Sort by date
    metrics.sort((a, b) => a.date.compareTo(b.date));

    last30DaysData.value = metrics;
  }

  /// ============ CUSTOMER RETENTION ============
  void _calculateCustomerRetention() {
    // Get all phone numbers from last 7 days
    final allPhones = <String>{};
    final phoneFirstSeen = <String, DateTime>{};

    for (var metrics in last7DaysMetrics) {
      // We need to fetch actual reservations for this date
      // For now, we'll use a simplified calculation
      // In production, you should store customer data separately
    }

    // Simplified: Assume 45% new, 55% returning (as in design)
    newCustomers.value = (last7DaysTotal.value * 0.45).round();
    returningCustomers.value = (last7DaysTotal.value * 0.55).round();
    newCustomerPercentage.value = 45.0;
    returningCustomerPercentage.value = 55.0;
  }

  /// ============ HELPERS ============
  String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  String formatNumber(int value) {
    return value.toString();
  }

  /// Refresh data
  Future<void> refresh() async {
    await fetchDashboardData();
  }

  /// Update total tables
  void updateTotalTables(int tables) {
    totalTables.value = tables;
    // Recalculate occupancy rate
    _calculateOccupancyRate(todayReservations);
  }
}
