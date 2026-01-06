import 'package:client_web/controllers/dashboard/dashboard_controller.dart';
import 'package:client_web/views/widgets/dashboard/chart_card.dart';
import 'package:client_web/views/widgets/dashboard/kpi_card.dart';
import 'package:client_web/views/widgets/dashboard/lunch_dinner_chart.dart';
import 'package:client_web/views/widgets/dashboard/need_action_card.dart';
import 'package:client_web/views/widgets/dashboard/occupancy_gauge.dart';
import 'package:client_web/views/widgets/dashboard/party_size_chart.dart';
import 'package:client_web/views/widgets/dashboard/peek_hours_chart.dart';
import 'package:client_web/views/widgets/dashboard/source_distribution_chart.dart';
import 'package:client_web/views/widgets/dashboard/stat_card.dart';
import 'package:client_web/views/widgets/dashboard/trend_chart.dart';
import 'package:client_web/views/widgets/dashboard/upcoming_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DashboardPage extends GetView<DashboardController> {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage.value,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: controller.refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 24),

                // KPI Cards Row
                _buildKpiCards(),
                const SizedBox(height: 24),

                // Main Content Grid
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column (70%)
                    Expanded(
                      flex: 7,
                      child: Column(
                        children: [
                          // Today's Stats
                          _buildTodayStats(),
                          const SizedBox(height: 24),

                          // Occupancy Rate
                          _buildOccupancySection(),
                          const SizedBox(height: 24),

                          // 30 Days Trend
                          _build30DaysTrend(),
                          const SizedBox(height: 24),

                          // Charts Row
                          Row(
                            children: [
                              Expanded(child: _buildPeakHoursChart()),
                              const SizedBox(width: 24),
                              Expanded(child: _buildLunchDinnerChart()),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Bottom Charts Row
                          Row(
                            children: [
                              Expanded(child: _buildPartySizeChart()),
                              const SizedBox(width: 24),
                              Expanded(child: _buildSourceDistributionChart()),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),

                    // Right Column (30%)
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          // Need Action
                          _buildNeedActionCard(),
                          const SizedBox(height: 24),

                          // Upcoming Reservations
                          _buildUpcomingCard(),
                          const SizedBox(height: 24),

                          // Quick Stats
                          _buildQuickStats(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ============ HEADER ============
  Widget _buildHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Obx(
              () => Text(
                'Tổng quan hôm nay - ${controller.todayTotal.value} đặt chỗ',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: controller.refresh,
          icon: const Icon(Icons.refresh),
          tooltip: 'Làm mới',
        ),
      ],
    );
  }

  // ============ KPI CARDS ============
  Widget _buildKpiCards() {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: KpiCard(
              title: 'Tổng đặt chỗ hôm nay',
              value: controller.todayTotal.value.toString(),
              subtitle: '7 ngày qua: ${controller.last7DaysTotal.value}',
              icon: Icons.event_note,
              color: const Color(0xFF5697C6),
              trend: '+12%',
              isPositiveTrend: true,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: KpiCard(
              title: 'Đã xác nhận',
              value: controller.todayConfirmed.value.toString(),
              subtitle:
                  '${(controller.todayConfirmed.value / (controller.todayTotal.value > 0 ? controller.todayTotal.value : 1) * 100).toStringAsFixed(0)}% tổng số',
              icon: Icons.check_circle,
              color: const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: KpiCard(
              title: 'Đã đến',
              value: controller.todayArrived.value.toString(),
              subtitle: 'Khách đã check-in',
              icon: Icons.how_to_reg,
              color: const Color(0xFF9C27B0),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: KpiCard(
              title: 'Tỷ lệ lấp đầy',
              value: '${controller.occupancyRate.value.toStringAsFixed(0)}%',
              subtitle: 'Trung bình hôm nay',
              icon: Icons.table_restaurant,
              color: const Color(0xFFFFA726),
            ),
          ),
        ],
      ),
    );
  }

  // ============ TODAY'S STATS ============
  Widget _buildTodayStats() {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: StatCard(
              label: 'Chờ xác nhận',
              value: controller.todayPending.value.toString(),
              icon: Icons.schedule,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: StatCard(
              label: 'Sắp đến (2h)',
              value: controller.upcomingCount.value.toString(),
              icon: Icons.access_time,
              color: const Color(0xFF5697C6),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: StatCard(
              label: 'Khách mới',
              value: controller.newCustomers.value.toString(),
              icon: Icons.person_add,
              color: const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: StatCard(
              label: 'Khách quen',
              value: controller.returningCustomers.value.toString(),
              icon: Icons.repeat,
              color: const Color(0xFF9C27B0),
            ),
          ),
        ],
      ),
    );
  }

  // ============ OCCUPANCY SECTION ============
  Widget _buildOccupancySection() {
    return Obx(() {
      final _ = controller.occupancyRate.value; // Trigger

      return ChartCard(
        title: 'Tỷ lệ lấp đầy',
        subtitle: 'Theo buổi trong ngày',
        height: 240,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: OccupancyGauge(
                percentage: controller.occupancyRate.value,
                label: 'Tổng',
                color: const Color(0xFF5697C6),
              ),
            ),
            Flexible(
              child: OccupancyGauge(
                percentage: controller.lunchOccupancy.value,
                label: 'Trưa',
                color: const Color(0xFFFFA726),
              ),
            ),
            Flexible(
              child: OccupancyGauge(
                percentage: controller.dinnerOccupancy.value,
                label: 'Tối',
                color: const Color(0xFF5C6BC0),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ============ 30 DAYS TREND ============
  Widget _build30DaysTrend() {
    return Obx(() {
      final _ = controller.last30DaysData.length;

      return ChartCard(
        title: 'Xu hướng 30 ngày',
        subtitle: 'Số lượng đặt chỗ theo ngày',
        height: 300,
        child: controller.last30DaysData.isEmpty
            ? Center(
                child: Text(
                  'Không có dữ liệu',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              )
            : TrendChart(data: controller.last30DaysData),
      );
    });
  }

  // ============ PEAK HOURS CHART ============
  Widget _buildPeakHoursChart() {
    return Obx(() {
      final _ = controller.peakHours.length;

      return ChartCard(
        title: 'Giờ cao điểm',
        subtitle: 'Top 3 khung giờ đông khách',
        height: 300,
        child: controller.peakHours.isEmpty
            ? Center(
                child: Text(
                  'Không có dữ liệu',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              )
            : PeakHoursChart(peakHours: controller.peakHours),
      );
    });
  }

  // ============ LUNCH VS DINNER CHART ============
  Widget _buildLunchDinnerChart() {
    return Obx(
      () => ChartCard(
        title: 'Trưa vs Tối',
        subtitle: '7 ngày qua',
        height: 300,
        child: LunchDinnerChart(
          lunchCount: controller.lunchCount.value,
          dinnerCount: controller.dinnerCount.value,
        ),
      ),
    );
  }

  // ============ PARTY SIZE CHART ============
  Widget _buildPartySizeChart() {
    return Obx(() {
      final _ = controller.partySizeDistribution.length;

      return ChartCard(
        title: 'Phân bố số người',
        subtitle: '7 ngày qua',
        height: 300,
        child: controller.partySizeDistribution.isEmpty
            ? Center(
                child: Text(
                  'Không có dữ liệu',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              )
            : PartySizeChart(distribution: controller.partySizeDistribution),
      );
    });
  }

  // ============ SOURCE DISTRIBUTION CHART ============
  Widget _buildSourceDistributionChart() {
    return Obx(
      () => ChartCard(
        title: 'Nguồn đặt chỗ',
        subtitle: '7 ngày qua',
        height: 300,
        child: SourceDistributionChart(
          phoneCount: controller.sourcePhone.value,
          websiteCount: controller.sourceWebsite.value,
          walkinCount: controller.sourceWalkin.value,
        ),
      ),
    );
  }

  // ============ NEED ACTION CARD ============
  Widget _buildNeedActionCard() {
    return Obx(
      () => NeedActionCard(
        pendingCount: controller.pendingCount.value,
        overdueCount: controller.overdueCount.value,
        onViewPending: () {
          // Navigate to reservations with pending filter
          Get.toNamed('/reservations', arguments: {'status': 'pending'});
        },
        onViewOverdue: () {
          // Navigate to reservations with overdue filter
          Get.toNamed('/reservations', arguments: {'status': 'overdue'});
        },
      ),
    );
  }

  // ============ UPCOMING CARD ============
  Widget _buildUpcomingCard() {
    return Obx(() {
      final _ = controller.upcomingReservations.length;

      return UpcomingCard(
        upcomingReservations: controller.upcomingReservations,
        onViewAll: () {
          Get.toNamed('/reservations', arguments: {'filter': 'upcoming'});
        },
      );
    });
  }

  // ============ QUICK STATS ============
  Widget _buildQuickStats() {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thống kê nhanh',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 20),
            _buildQuickStatItem(
              label: 'Trung bình/ngày (7 ngày)',
              value: controller.last7DaysAverage.value.toStringAsFixed(1),
              icon: Icons.trending_up,
              color: const Color(0xFF5697C6),
            ),
            const Divider(height: 24),
            _buildQuickStatItem(
              label: 'Tỷ lệ hủy',
              value: '${controller.cancellationRate.value.toStringAsFixed(1)}%',
              icon: Icons.cancel,
              color: Colors.red,
            ),
            const Divider(height: 24),
            _buildQuickStatItem(
              label: 'Tổng bàn',
              value: controller.totalTables.value.toString(),
              icon: Icons.table_restaurant,
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
