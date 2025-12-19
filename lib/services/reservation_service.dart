import 'package:client_web/core/exceptions/data_exception.dart';
import 'package:client_web/models/enum/reservation_status.dart';
import 'package:client_web/models/paginated_result.dart';
import 'package:client_web/models/reservation_model.dart';
import 'package:client_web/repositories/reservation_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationService {
  final ReservationRepository _repository;
  ReservationService(this._repository);

  /// Get reservation by id
  Future<ReservationModel?> getReservationById(String id) async {
    if (id.isEmpty) {
      throw DataException("Reservation ID can't be empty");
    }
    return await _repository.getById(id);
  }

  /// ======== Read ========
  // Get pagination
  Future<PaginatedResult<ReservationModel>> getPaginatedReservations({
    int limit = 20,
    DocumentSnapshot? startAfter,
    DateTime? startDate,
    DateTime? endDate,
    ReservationStatus? status,
    String orderBy = 'createdAt',
    bool ascending = true,
  }) async {
    if (limit <= 0) throw DataException('Limit must be greater than 0');
    if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
      throw DataException("Start date can't after end date");
    }
    return await _repository.getReservations(
      limit: limit,
      startAfter: startAfter,
      startDate: startDate,
      endDate: endDate,
      status: status,
      orderBy: orderBy,
      ascending: ascending,
    );
  }

  // Get reservations by default range (from 7 days before to 30 days later)
  Future<PaginatedResult<ReservationModel>> getReservationsInDefaultRange({
    int limit = 500,
    DocumentSnapshot? startAfter,
    ReservationStatus? status,
    String orderBy = 'createdAt',
    bool ascending = false,
  }) async {
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 7));
    final endDate = now.add(const Duration(days: 30));
    return await _repository.getReservations(
      limit: limit,
      startAfter: startAfter,
      startDate: startDate,
      endDate: endDate,
      orderBy: orderBy,
      ascending: ascending,
    );
  }

  // Get reservations by datetime
  Future<List<ReservationModel>> getReservationByDate(DateTime date) async {
    final result = await _repository.getReservations(
      limit: 100,
      orderBy: 'time',
      startDate: _startOfDate(date),
      endDate: _endOfDate(date),
      ascending: false,
    );
    return result.items;
  }

  // Get reservations by datetime range
  Future<List<ReservationModel>> getReservationByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final result = await _repository.getReservations(
      limit: 100,
      orderBy: 'date',
      startDate: startDate,
      endDate: endDate,
      ascending: false,
    );
    return result.items;
  }

  // Get reservations by status
  Future<List<ReservationModel>> getReservationsByStatus(
    ReservationStatus status,
  ) async {
    final result = await _repository.getReservations(
      limit: 100,
      status: status,
      ascending: false,
    );
    return result.items;
  }

  /// ========= Filters ========
  // Quick filter reservations by today
  List<ReservationModel> filterReservationsByToday(
    List<ReservationModel> reservations,
  ) {
    final today = DateTime.now();
    return reservations.where((reservation) {
      final reservationDate = DateTime.parse(reservation.date);
      return reservationDate == today;
    }).toList();
  }

  // Quick filter reservations by this week
  List<ReservationModel> filterReservationsByThisWeek(
    List<ReservationModel> reservations,
  ) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return reservations.where((reservation) {
      final reservationDate = DateTime.parse(reservation.date);
      return reservationDate.isAfter(
            _startOfDate(startOfWeek).subtract(const Duration(seconds: 1)),
          ) &&
          reservationDate.isBefore(
            _endOfDate(endOfWeek).add(const Duration(seconds: 1)),
          );
    }).toList();
  }

  // Quick filter reservations not arrived
  List<ReservationModel> filterReservationsNotArrived(
    List<ReservationModel> reservations,
  ) {
    return reservations.where((reservation) {
      return reservation.status == ReservationStatus.pending;
    }).toList();
  }

  // Fetch data in a reasonable range and filter on client side
  Future<List<ReservationModel>> searchReservations({
    required String query,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    if (query.isEmpty) {
      throw DataException("Search query can't be empty");
    }
    // Define search range (before 7 days and after 30 days from now)
    final now = DateTime.now();
    final start = customStartDate ?? now.subtract(const Duration(days: 7));
    final end = customEndDate ?? now.add(const Duration(days: 30));

    // Fetch all reservations in the date range
    final result = await _repository.getReservations(
      limit: 500,
      startDate: start,
      endDate: end,
      ascending: false,
    );
    // Filter on client side
    return _filterReservationsByQuery(result.items, query);
  }

  // Filter reservations in default fetched data by search query
  List<ReservationModel> filterBySearchQuery(
    List<ReservationModel> reservations,
    String query,
  ) {
    if (query.isEmpty) {
      throw DataException("Search query can't be empty");
    }
    return _filterReservationsByQuery(reservations, query);
  }

  // Filter reservations by search query
  List<ReservationModel> _filterReservationsByQuery(
    List<ReservationModel> reservations,
    String query,
  ) {
    final lowerQuery = query.toLowerCase().trim();
    return reservations.where((reservation) {
      // Search by phone exact match
      if (reservation.phone.toLowerCase() == lowerQuery) {
        return true;
      }
      // Search by phone partial match
      if (reservation.phone.toLowerCase().contains(lowerQuery)) {
        return true;
      }
      // Search by name
      if (reservation.name.toLowerCase().contains(lowerQuery)) {
        return true;
      }
      // Search by ID
      if (reservation.id.toLowerCase().contains(lowerQuery)) {
        return true;
      }
      return false;
    }).toList();
  }

  /// ======== Helpers ========
  void sortByDate(List<ReservationModel> reservations, bool ascending) {
    reservations.sort((a, b) {
      final dateA = DateTime.parse(a.date);
      final dateB = DateTime.parse(b.date);
      return ascending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
    });
  }

  String _formatDate(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$day-$month-$year';
  }

  /// ======== CRUD ========
  /// Create
  /// Update
  /// Delete
  // Delete reservation by id
  Future<ReservationModel?> deleteReservationById(String id) async {
    if (id.isEmpty) {
      throw DataException("Reservation ID can't be empty");
    }
    try {
      final reservation = await _repository.deleteReservations(id);
      return reservation;
    } catch (e) {
      throw DataException(
        'Failed to delete reservation: $id',
        originalError: e,
      );
    }
  }

  /// Helpers
  DateTime _startOfDate(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day, 0, 0, 0);
  }

  DateTime _endOfDate(DateTime dataTime) {
    return DateTime(dataTime.year, dataTime.month, dataTime.day, 23, 59, 59);
  }
}
