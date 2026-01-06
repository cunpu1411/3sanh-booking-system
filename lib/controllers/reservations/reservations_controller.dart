import 'dart:async';

import 'package:client_web/core/exceptions/data_exception.dart';
import 'package:client_web/helpers/snackbar_helpers.dart';
import 'package:client_web/models/enum/reservation_source.dart';
import 'package:client_web/models/enum/reservation_status.dart';
import 'package:client_web/models/reservation_model.dart';
import 'package:client_web/services/reservation_service.dart';
import 'package:client_web/views/widgets/reservations/add_reservation_dialog.dart';
import 'package:client_web/views/widgets/reservations/view_reservation_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReservationsController extends GetxController {
  final ReservationService _service;

  /// Data cached
  final _cachedReservations = <ReservationModel>[];
  DocumentSnapshot? _lastFetchDocument;
  Timestamp? _lastLoadTime;

  /// Notifications
  final hasNewReservations = false.obs;
  final newReservationsCount = 0.obs;
  StreamSubscription? _newReservationsSubscription;
  DateTime? _lastNotificationCheck;
  final newReservationsList = <ReservationModel>[].obs;
  Timer? _autoRefreshTimer;
  final Duration _autoRefreshInterval = const Duration(minutes: 60);
  Timer? _countdownTimer;
  final remainingTimeForNextRefresh = 0.obs;
  bool _isTimerActive = false;
  final isNotificationPanelOpen = false.obs;
  bool _isFirstEmission = true;

  /// Loading states
  final isLoadingMore = false.obs;
  final isLoading = false.obs;
  final isCreating = false.obs;

  /// Filters -SERVER SIDE
  final Rx<ReservationStatus?> statusFilter = Rx<ReservationStatus?>(null);

  /// Search state
  final searchQuery = ''.obs;
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  final isSearching = false.obs;
  final searchResults = <ReservationModel>[].obs;
  final searchSource =
      ''.obs; // from where the search is initiated: cache or server

  /// Filters state
  final showOnlyNotArrived = false.obs;
  final showReservationsToday = false.obs;
  final showReservationsThisWeek = false.obs;
  final Rx<DateTimeRange?> serverDateRangeFilter = Rx<DateTimeRange?>(null);

  /// Data
  final errorMessage = ''.obs;
  final totalItemsFiltered = 0.obs;
  final hasMoreData = false.obs;

  /// Selected reservations
  final Rx<ReservationModel?> selectedReservation = Rx<ReservationModel?>(null);

  /// Helpers
  final dateAscending = false.obs;
  bool _isManuallySettingDateRange = false;
  final isUpdating = true.obs;

  /// Debounce
  Timer? _debounceTimer;

  /// Pagination
  final currentPage = 1.obs;
  final pageSize = 10.obs;
  final paginatedReservations = <ReservationModel>[].obs;

  /// Constructor
  ReservationsController(this._service);

  /// ===============  Computed ===============
  int get totalPages {
    if (_cachedReservations.isEmpty) return 1;
    final cachedPages = (_cachedReservations.length / pageSize.value).ceil();
    return cachedPages;
  }

  bool get canGoToNextPage {
    final cachedPages = (_cachedReservations.length / pageSize.value).ceil();
    // If not on last cached page, can go next
    if (currentPage.value < cachedPages) {
      return true;
    }
    // If on last cached page, check if more data available
    if (currentPage.value == cachedPages && hasMoreData.value) {
      return true;
    }
    return false;
  }

  bool get canGoToPreviousPage {
    return currentPage.value > 1;
  }

  //! 0 - 10 of 200+
  String get displayedRange {
    if (totalItemsFiltered.value == 0) return '0 - 0 of 0';
    final start = ((currentPage.value - 1) * pageSize.value) + 1;
    var end = (currentPage.value * pageSize.value).clamp(
      0,
      totalItemsFiltered.value,
    );
    final total = totalItemsFiltered.value;
    final moreIndicator = hasMoreData.value ? '+' : '';
    return '$start - $end of $total $moreIndicator';
  }

  /// =============== Lifecycle Methods ===============
  @override
  void onInit() {
    super.onInit();
    _setupSearchListener();
    _setUpQuickFilters();
    onServerFilterChanged();
    _listenForNewReservations();
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    _newReservationsSubscription?.cancel();
    _autoRefreshTimer?.cancel();
    _countdownTimer?.cancel();
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    searchFocusNode.dispose();
    super.onClose();
  }

  /// =============== Fetch data ===============
  Future<void> fetchInitReservations() async {
    print('>> fetchInitReservations called ...');
    currentPage.value = 1;
    _cachedReservations.clear();
    _lastFetchDocument = null;

    // Set date range filter for server side (bf 7days - af 30 days)
    final now = DateTime.now();
    _lastNotificationCheck = now;
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final thirtyDaysLater = now.add(const Duration(days: 30));
    // Fetch default range from server
    await _fetchDefaultRange();
  }

  Future<void> _fetchDefaultRange() async {
    isLoading.value = true;
    try {
      print('>> _fetchDefaultRange called ...');
      final result = await _service.getReservationsInDefaultRange(
        limit: 500,
        status: statusFilter.value,
        orderBy: 'date',
        ascending: dateAscending.value,
      );
      _cachedReservations.clear();
      _cachedReservations.addAll(result.items);
      _lastFetchDocument = result.lastDocument;
      _lastLoadTime = Timestamp.now();
      hasMoreData.value = result.hasMore;
      print('Fetched ${result.items.length} reservations in default range.');
      // Apply client filters
      _applyClientFilters();
    } catch (e) {
      print('Error fetching default range: $e');
      errorMessage.value = 'Error fetching reservations: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch batch with pagination for custom date range
  Future<void> _fetchBatch({bool loadMore = false, int? limit}) async {
    print('>> _fetchBatch called (loadMore: $loadMore, limit: $limit)');
    if (loadMore) {
      isLoadingMore.value = true;
    } else {
      isLoading.value = true;
    }
    // Implementation of data fetching with pagination
    try {
      print('Fetching reservations from server...');
      final batchSize = limit ?? 100;
      final result = await _service.getPaginatedReservations(
        limit: batchSize,
        startAfter: loadMore ? _lastFetchDocument : null,
        startDate: serverDateRangeFilter.value?.start,
        endDate: serverDateRangeFilter.value?.end,
        status: statusFilter.value,
        orderBy: 'date',
        ascending: dateAscending.value,
      );
      print('Fetched ${result.items.length} reservations from server.');
      if (loadMore) {
        _cachedReservations.addAll(result.items);
        print('Loaded more, total cached: ${_cachedReservations.length}');
      } else {
        _cachedReservations.clear();
        _cachedReservations.addAll(result.items);
        print('Initial load, total cached: ${_cachedReservations.length}');
      }
      _lastFetchDocument = result.lastDocument;
      _lastLoadTime = Timestamp.now();
      hasMoreData.value = result.hasMore;
      // Apply client filters
      _applyClientFilters();
    } catch (e) {
      errorMessage.value = 'Error fetching reservations: $e';
    } finally {
      isLoadingMore.value = false;
      isLoading.value = false;
    }
  }

  /// =============== Client Filters ===============
  void _applyClientFilters() {
    print('>> Applying client-side filters...');
    List<ReservationModel> filtered = _cachedReservations.toList();
    // if searching, use search results
    if (searchQuery.value.isNotEmpty && searchResults.isNotEmpty) {
      filtered = _service.filterBySearchQuery(filtered, searchQuery.value);
    } else if (searchQuery.value.isNotEmpty && searchResults.isEmpty) {
      filtered = [];
    } else {
      filtered = _cachedReservations.toList();
    }
    print('Initial filtered count: ${filtered.length}');
    // --- Apply quick filters ---
    // Filter Today
    if (showReservationsToday.value) {
      filtered = _service.filterReservationsByToday(filtered);
      print('After Today filter count: ${filtered.length}');
    }
    // Filter This Week
    if (showReservationsThisWeek.value) {
      filtered = _service.filterReservationsByThisWeek(filtered);
      print('After This Week filter count: ${filtered.length}');
    }
    // Filter Not Arrived
    if (showOnlyNotArrived.value) {
      filtered = _service.filterReservationsNotArrived(filtered);
      print('After Not Arrived filter count: ${filtered.length}');
    }
    // Sort by date
    _service.sortByDate(filtered, dateAscending.value);
    // Update total count
    totalItemsFiltered.value = filtered.length;
    // Paginate
    _paginateReservations(filtered);
  }

  void _paginateReservations(List<ReservationModel> filteredReservations) {
    print('>> Paginating reservations...');
    final startIndex = (currentPage.value - 1) * pageSize.value;
    final endIndex = (startIndex + pageSize.value).clamp(
      0,
      filteredReservations.length,
    );
    // If startIndex exceeds length, return empty
    if (startIndex >= filteredReservations.length) {
      if (hasMoreData.value && !isLoadingMore.value) {
        _fetchBatch(loadMore: true);
      }
      paginatedReservations.value = [];
      return;
    }
    final pageItems = filteredReservations.sublist(startIndex, endIndex);
    paginatedReservations.value = pageItems;
    print(
      'Paginating: page ${currentPage.value}, '
      'startIndex: $startIndex, endIndex: $endIndex, '
      'first: ${paginatedReservations[0].name}, '
      'totalFiltered: ${filteredReservations.length}',
    );
    // Check if need to load more data
    _checkAndLoadMore();
  }

  void onServerFilterChanged() {
    print('>> onServerFilterChanged called ...');
    // Server changed, refetch data
    if (_isDefaultDateRange()) {
      fetchInitReservations();
    } else {
      currentPage.value = 1;
      _fetchBatch(loadMore: false);
    }
  }

  bool _isDefaultDateRange() {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final thirtyDaysLater = now.add(const Duration(days: 30));
    final currentRange = serverDateRangeFilter.value;
    if (currentRange == null) return true;
    final isDefault =
        currentRange.start.year == sevenDaysAgo.year &&
        currentRange.start.month == sevenDaysAgo.month &&
        currentRange.start.day == sevenDaysAgo.day &&
        currentRange.end.year == thirtyDaysLater.year &&
        currentRange.end.month == thirtyDaysLater.month &&
        currentRange.end.day == thirtyDaysLater.day;
    return isDefault;
  }

  void onClientFilterChanged() {
    currentPage.value = 1;
    _applyClientFilters();
  }

  /// =============== Search ===============
  void _setupSearchListener() {
    searchController.addListener(() {
      _onSearchChanged();
    });
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final query = searchController.text.trim();
      if (query.isEmpty) {
        // Clear search
        _clearSearch();
      } else {
        // Perform search
        performSearch(query);
      }
    });
  }

  Future<void> performSearch(String query) async {
    if (query.isEmpty) return;
    searchQuery.value = query;
    // For simplicity, we filter on client side
    if (_canSearchInCached()) {
      _searchInCache(query);
    } else {
      await _searchOnServer(query);
    }
  }

  bool _canSearchInCached() {
    // If filtering by "Today" or "This Week", search in cache
    if (showReservationsToday.value || showReservationsThisWeek.value) {
      return true;
    }
    // If having date range filter, search in cache
    if (serverDateRangeFilter.value != null) return true;
    return false;
  }

  // Search in cached data
  void _searchInCache(String query) {
    try {
      isSearching.value = true;
      searchSource.value = 'cache';
      final lowerQuery = query.toLowerCase();
      final results = _cachedReservations.where((reservation) {
        if (reservation.phone.toLowerCase() == lowerQuery) {
          return true;
        }
        if (reservation.name.toLowerCase().contains(lowerQuery)) {
          return true;
        }
        if (reservation.id.toLowerCase().contains(lowerQuery)) {
          return true;
        }
        return false;
      }).toList();
      searchResults.value = results;

      // Apply client filters to search results
      currentPage.value = 1;
      _applyClientFilters();
    } finally {
      isSearching.value = false;
    }
  }

  // Search on server
  Future<void> _searchOnServer(String query) async {
    try {
      isSearching.value = true;
      searchSource.value = 'server';
      final results = await _service.searchReservations(
        query: query,
        customStartDate: serverDateRangeFilter.value?.start,
        customEndDate: serverDateRangeFilter.value?.end,
      );
      searchResults.value = results;

      // Update cache with search results
      _cachedReservations.clear();
      _cachedReservations.addAll(results);

      // Reset pagination
      currentPage.value = 1;
      _lastFetchDocument = null;
      hasMoreData.value = false; // No more data in search

      // Apply client filters to search results
      _applyClientFilters();
    } catch (e) {
      errorMessage.value = 'Error searching reservations: $e';
    } finally {
      isSearching.value = false;
    }
  }

  // Clear search and return normal view
  void _clearSearch() {
    searchQuery.value = '';
    searchResults.clear();
    searchSource.value = '';
    // Reload original data
    fetchInitReservations();
  }

  // Clear search input field
  void clearSearchInput() {
    searchController.clear();
    _clearSearch();
  }

  /// =============== Quick Filters ===============
  void _setUpQuickFilters() {
    ever(serverDateRangeFilter, (DateTimeRange? range) {
      // Listen server-side filters
      if (!_isManuallySettingDateRange) {
        onServerFilterChanged();
      }
    });
    ever(statusFilter, (_) {
      // Listen server-side filters
      onServerFilterChanged();
    });

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
        serverDateRangeFilter.value = null;
      }
    });
  }

  void setDateRangeFilter(
    DateTimeRange? dateRange, {
    bool fromQuickFilter = true,
  }) {
    serverDateRangeFilter.value = dateRange;
    _clearNotifications();
    _listenForNewReservations();
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

  /// =============== Pagination Controls ===============
  void goToPage(int page) {
    print('>> Going to page $page');
    if (page < 1 || page > totalPages) return;
    final maxPaged = (_cachedReservations.length / pageSize.value).ceil();
    // If trying to go beyond cached pages and no more data, return
    if (page > maxPaged && !hasMoreData.value) return;
    currentPage.value = page;
    _applyClientFilters(); // This will call _loadMore if needed
  }

  void nextPage() {
    if (!canGoToNextPage) return;
    goToPage(currentPage.value + 1);
  }

  void previousPage() {
    if (!canGoToPreviousPage) return;
    goToPage(currentPage.value - 1);
  }

  void _checkAndLoadMore() {
    // Don't load more if searching
    if (searchQuery.value.isNotEmpty) return;
    // Don't load more if already loading
    if (isLoadingMore.value || isLoading.value) return;
    // Don't load more if no more data
    if (!hasMoreData.value) return;

    final totalCached = _cachedReservations.length;
    if (totalCached == 0) return;
    // Check if we need to load more data from server
    final threshHold = (_cachedReservations.length * 0.8).toInt();
    final currentIndex = currentPage.value * pageSize.value;
    if (currentIndex >= threshHold) {
      _fetchBatch(loadMore: true);
    }
  }

  /// =============== Notification ===============
  void _listenForNewReservations() {
    _newReservationsSubscription?.cancel();
    _isFirstEmission = true;
    final dateRange = _getDateRange();
    // Listen for new reservations
    _newReservationsSubscription = _service
        .getNewReservationsStream(range: dateRange)
        .listen(
          (newReservation) {
            if (_isFirstEmission) {
              // Skip first emission to avoid counting existing reservations
              _isFirstEmission = false;
              return;
            }
            if (newReservation.isNotEmpty) {
              _handleNewReservations(newReservation);
            }
          },
          onError: (error) {
            print('Error listening for new reservations: $error');
          },
        );
  }

  DateTimeRange _getDateRange() {
    if (serverDateRangeFilter.value != null) {
      return serverDateRangeFilter.value!;
    }
    return _service.getDefaultDateRange();
  }

  void _handleNewReservations(List<ReservationModel> newReservations) {
    print('>> New reservations received: ${newReservations.length}');
    for (var reservation in newReservations) {
      final exists = newReservationsList.any((r) => r.id == reservation.id);
      if (!exists) {
        newReservationsList.insert(0, reservation);
        newReservationsCount.value++;
      }
    }
    if (newReservationsCount.value > 0) {
      hasNewReservations.value = true;
      // Start timer for auto refresh
      if (!_isTimerActive) {
        _startAutoRefresh();
      }
      if (newReservationsCount.value > 15) {
        _autoRefresh();
      }
    }
  }

  void _startAutoRefresh() {
    if (_isTimerActive) {
      return;
    }
    _isTimerActive = true;
    remainingTimeForNextRefresh.value = _autoRefreshInterval.inSeconds;
    // Start countdown timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTimeForNextRefresh.value > 0) {
        remainingTimeForNextRefresh.value--;
      } else {
        timer.cancel();
      }
    });
    // Start auto refresh timer
    _autoRefreshTimer = Timer(_autoRefreshInterval, () {
      _autoRefresh();
    });
  }

  Future<void> refreshReservations() async {
    await _fullReset();
  }

  Future<void> _fullReset() async {
    newReservationsList.clear();
    newReservationsCount.value = 0;
    hasNewReservations.value = false;
    isNotificationPanelOpen.value = false;

    // Clear search
    clearSearchInput();

    // Clear filters
    showOnlyNotArrived.value = false;
    showReservationsToday.value = false;
    showReservationsThisWeek.value = false;
    statusFilter.value = null;

    // Reset pagination
    currentPage.value = 1;

    // Fetch data
    await fetchInitReservations();

    // Restart auto refresh timer
    _isTimerActive = false;

    // Restart listener
    _listenForNewReservations();
  }

  Future<void> _autoRefresh() async {
    print('>> Auto refreshing reservations ...');
    // Reset timer
    _autoRefreshTimer?.cancel();
    _countdownTimer?.cancel();
    _isTimerActive = false;
    await _fullReset();
  }

  // Clear notifications
  void _clearNotifications() {
    newReservationsList.clear();
    newReservationsCount.value = 0;
    hasNewReservations.value = false;
    isNotificationPanelOpen.value = false;

    _autoRefreshTimer?.cancel();
    _countdownTimer?.cancel();
    _isTimerActive = false;
    remainingTimeForNextRefresh.value = 0;
  }

  // Toggle notification panel
  void toggleNotificationPanel() {
    isNotificationPanelOpen.value = !isNotificationPanelOpen.value;
  }

  void closeNotificationPanel() {
    isNotificationPanelOpen.value = false;
  }

  String get formattedCountdown {
    final minutes = (remainingTimeForNextRefresh.value ~/ 60)
        .toString()
        .padLeft(2, '0');
    final seconds = (remainingTimeForNextRefresh.value % 60).toString().padLeft(
      2,
      '0',
    );
    return '$minutes:$seconds';
  }

  /// =============== CRUD ===============
  void showReservationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddReservationDialog(),
      barrierDismissible: false,
    );
  }

  /// Show Edit Dialog
  void showEditDialog({
    required BuildContext context,
    required ReservationModel reservation,
  }) {
    showDialog(
      context: context,
      builder: (context) => AddReservationDialog(
        existingReservation: reservation, // ← Pass existing reservation
      ),
      barrierDismissible: false,
    );
  }

  /// Show View Dialog (Read-only)
  void showViewDialog({
    required BuildContext context,
    required ReservationModel reservation,
  }) {
    showDialog(
      context: context,
      builder: (context) => ViewReservationDialog(reservation: reservation),
      barrierDismissible: true,
    );
  }

  /// Create reservation
  Future<void> createReservation({
    required BuildContext context,
    required String name,
    required String phone,
    required String date,
    required String time,
    required int partySize,
    required ReservationSource source,
    required ReservationStatus status,
    String? note,
  }) async {
    print('[Reservation controller] Create new reservation ...');
    try {
      isCreating.value = true;
      final createdReservation = await _service.createReservation(
        name: name,
        phone: phone,
        date: date,
        time: time,
        partySize: partySize,
        source: source,
        status: status,
        note: note,
      );
      // Close dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      if (context.mounted) {
        SnackbarHelper.showSuccess(context, 'Reservation successful!');
      }
      // Refresh list
      await fetchInitReservations();
    } on DataException catch (e) {
      if (e.message == 'DUPLICATE') {
        if (context.mounted) {
          _showDuplicateWarning(context, phone, date, time);
        }
      } else {
        if (context.mounted) {
          SnackbarHelper.showError(context, e.message);
        }
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showError(context, 'Creating reservation failed');
      }
    } finally {
      isCreating.value = false;
    }
  }

  /// Show duplicate warning dialog
  void _showDuplicateWarning(
    BuildContext context,
    String phone,
    String date,
    String time,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warning_rounded,
                color: Colors.orange,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Reservation duplicate',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A Reservation already exists: ',
              style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phone: $phone',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Month: $date', style: const TextStyle(fontSize: 13)),
                  Text('Time: $time', style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please double-check the information before creating',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Close',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Update reservation
  Future<void> updateReservation({
    required BuildContext context,
    required String id,
    String? name,
    String? phone,
    String? date,
    String? time,
    int? partySize,
    ReservationStatus? status,
    String? note,
  }) async {
    print('[Reservation controller] Update reservation: $id');
    try {
      isUpdating.value = true;

      final updatedReservation = await _service.updateReservation(
        id: id,
        name: name,
        phone: phone,
        date: date,
        time: time,
        partySize: partySize,
        status: status,
        note: note,
      );

      // Close dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (updatedReservation != null) {
        if (context.mounted) {
          SnackbarHelper.showSuccess(context, 'Cập nhật thành công!');
        }
        // Refresh list
        await fetchInitReservations();
      } else {
        if (context.mounted) {
          SnackbarHelper.showError(context, 'Cập nhật thất bại');
        }
      }
    } on DataException catch (e) {
      if (e.message == 'DUPLICATE') {
        if (context.mounted) {
          _showDuplicateWarning(context, phone ?? '', date ?? '', time ?? '');
        }
      } else {
        if (context.mounted) {
          SnackbarHelper.showError(context, e.message);
        }
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showError(context, 'Cập nhật thất bại: $e');
      }
    } finally {
      isUpdating.value = false;
    }
  }

  /// Update reservation status (Quick change from dropdown)
  Future<void> updateReservationStatus({
    required BuildContext context,
    required String reservationId,
    required ReservationStatus newStatus,
  }) async {
    print(
      '[Reservation controller] Quick update status: $reservationId -> ${newStatus.value}',
    );

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text('Đang cập nhật trạng thái...'),
          ],
        ),
        duration: const Duration(seconds: 30),
        backgroundColor: const Color(0xFF5697C6),
      ),
    );

    try {
      final updatedReservation = await _service.updateReservation(
        id: reservationId,
        status: newStatus,
      );

      // Hide loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      if (updatedReservation != null) {
        if (context.mounted) {
          SnackbarHelper.showSuccess(
            context,
            'Đã cập nhật trạng thái: ${newStatus.displayName}',
          );
        }
        // Refresh list
        await fetchInitReservations();
      } else {
        if (context.mounted) {
          SnackbarHelper.showError(context, 'Cập nhật thất bại');
        }
      }
    } catch (e) {
      // Hide loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      if (context.mounted) {
        SnackbarHelper.showError(context, 'Cập nhật thất bại: $e');
      }
    }
  }

  /// =============== Helpers ===============
  // Sorting
  void sortByDate(List<ReservationModel> reservations) {
    reservations.sort((a, b) {
      DateTime dateA = DateTime.parse(a.date);
      DateTime dateB = DateTime.parse(b.date);
      final timeA = a.time;
      final timeB = b.time;
      final dateTimeA = _combineDateAndTime(dateA, timeA);
      final dateTimeB = _combineDateAndTime(dateB, timeB);

      return dateAscending.value
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
    required ReservationModel reservation,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.warning_rounded, color: Colors.red, size: 28),
              ),
              const SizedBox(width: 16),
              Text(
                'Xác nhận xóa',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn có chắc chắn muốn xóa đặt chỗ này?',
                style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      label: 'Ngày giờ',
                      value: '${reservation.time} - ${reservation.date}',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.person,
                      label: 'Tên khách',
                      value: reservation.name,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.phone,
                      label: 'Số điện thoại',
                      value: reservation.phone,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.people,
                      label: 'Số người',
                      value: '${reservation.partySize} người',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hành động này không thể hoàn tác',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Hủy',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Xóa',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
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
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Đang xóa...',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),
      );

      try {
        await _service.deleteReservationById(reservation.id);

        if (context.mounted) {
          Navigator.of(context).pop();
          SnackbarHelper.showSuccess(context, 'Đã xóa thành công');
          await fetchInitReservations();
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop();
          SnackbarHelper.showError(context, 'Không thể xóa: $e');
        }
      }
    }
  }

  /// Helper method with icon
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w500,
            ),
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
      initialDateRange: serverDateRangeFilter.value,
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
    if (serverDateRangeFilter.value == null) return '';
    final start = serverDateRangeFilter.value!.start;
    final end = serverDateRangeFilter.value!.end;
    return '${start.day}/${start.month} - ${end.day}/${end.month}';
  }
}
