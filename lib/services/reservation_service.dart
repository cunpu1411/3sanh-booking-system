import 'dart:async';

import 'package:client_web/core/exceptions/data_exception.dart';
import 'package:client_web/models/enum/reservation_source.dart';
import 'package:client_web/models/enum/reservation_status.dart';
import 'package:client_web/models/paginated_result.dart';
import 'package:client_web/models/reservation_model.dart';
import 'package:client_web/repositories/reservation_repository.dart';
import 'package:client_web/repositories/reservation_repository_impl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReservationService {
  final ReservationRepositoryImplement _repository;
  ReservationService(this._repository);

  /// Get reservation by id
  Future<ReservationModel?> getReservationById(String id) async {
    if (id.isEmpty) {
      throw DataException("Reservation ID can't be empty");
    }
    return await _repository.getById(id);
  }

  /// ======== Read ========
  // Get stream for new reservations in real-time
  Stream<List<ReservationModel>> getNewReservationsStream({
    required DateTimeRange range,
  }) {
    return _repository.listenForNewReservations().map(
      (snapshot) => _filterByDateRange(snapshot, range),
    );
  }

  // Filter by date range (helper method)
  List<ReservationModel> _filterByDateRange(
    QuerySnapshot snapshot,
    DateTimeRange range,
  ) {
    print('[Service] Processing ${snapshot.docs.length} docs...');
    print('[Service] Filtering by range: ${range.start} - ${range.end}');
    final models = <ReservationModel>[];

    for (var doc in snapshot.docs) {
      try {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null || data.isEmpty) continue;

        // Check date range
        final dateStr = data['date'] as String?;
        if (dateStr == null || dateStr.isEmpty) continue;

        final dateParts = dateStr.split('-');
        if (dateParts.length != 3) continue;

        // Parse date (format: DD-MM-YYYY)
        final day = int.tryParse(dateParts[0]);
        final month = int.tryParse(dateParts[1]);
        final year = int.tryParse(dateParts[2]);
        if (day == null || month == null || year == null) continue;

        final reservationDate = DateTime(year, month, day);

        // Check if in range (inclusive)
        final isInRange =
            reservationDate.isAfter(
              range.start.subtract(const Duration(days: 1)),
            ) &&
            reservationDate.isBefore(range.end.add(const Duration(days: 1)));

        if (!isInRange) continue;

        // Convert to model
        final model = ReservationModel.fromFirestore(
          doc as DocumentSnapshot<Map<String, dynamic>>,
        );
        models.add(model);
      } catch (e) {
        print('[Service] Error processing doc ${doc.id}: $e');
      }
    }

    print('[Service] ${models.length} reservations in range');
    return models;
  }

  // Get pagination
  Future<PaginatedResult<ReservationModel>> getPaginatedReservations({
    int limit = 20,
    DocumentSnapshot? startAfter,
    DateTime? startDate,
    DateTime? endDate,
    ReservationStatus? status,
    String orderBy = 'date',
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
    String orderBy = 'date',
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
      orderBy: 'date',
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
      return reservationDate.year == today.year &&
          reservationDate.month == today.month &&
          reservationDate.day == today.day;
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
      // Search by phone
      if (reservation.phone.toLowerCase().contains(lowerQuery)) {
        return true;
      }
      // Search by name
      if (reservation.name.toLowerCase().contains(lowerQuery)) {
        return true;
      }
      // Search by ID
      // if (reservation.id.toLowerCase().contains(lowerQuery)) {
      //   return true;
      // }
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
  Future<ReservationModel> createReservation({
    required String name,
    required String phone,
    required String date,
    required String time,
    required int partySize,
    required ReservationSource source,
    required ReservationStatus status,
    String? note,
  }) async {
    print('[Service] Creating reservation ...');
    try {
      // Validate inputs
      _validateReservationInput(
        name: name,
        phone: phone,
        date: date,
        time: time,
        partySize: partySize,
      );

      // Check duplicate reservation
      final isDuplicate = await _repository.checkDuplicateReservation(
        phone: phone,
        date: date,
        time: time,
        excludeId: null,
        checkActiveOnly: true,
      );

      if (isDuplicate) {
        throw DataException('DUPLICATE'); // Flag
      }

      // Create reservation model
      final newReservation = ReservationModel(
        id: '',
        name: name,
        phone: phone,
        date: date,
        time: time,
        partySize: partySize,
        source: source,
        status: status,
        note: note ?? '',
        createdAt: Timestamp.now(),
      );
      final createdReservation = await _repository.createReservation(
        newReservation,
      );
      return createdReservation;
    } catch (e) {
      throw DataException(e.toString(), originalError: e);
    }
  }

  /// Update
  Future<ReservationModel?> updateReservation({
    required String id,
    String? name,
    String? phone,
    String? date,
    String? time,
    int? partySize,
    ReservationStatus? status,
    String? tableId,
    String? note,
  }) async {
    if (id.isEmpty) {
      throw DataException("Reservation ID can't be empty");
    }
    try {
      final existing = await _repository.getById(id);
      if (existing == null) {
        throw DataException('Reservation not found: $id');
      }
      final nameToValidate = name ?? existing.name;
      final phoneToValidate = phone ?? existing.phone;
      final dateToValidate = date ?? existing.date;
      final timeToValidate = time ?? existing.time;
      final partySizeToValidate = partySize ?? existing.partySize;
      // Validate inputs
      if (name != null ||
          phone != null ||
          date != null ||
          time != null ||
          partySize != null) {
        _validateReservationInput(
          name: nameToValidate,
          phone: phoneToValidate,
          date: dateToValidate,
          time: timeToValidate,
          partySize: partySizeToValidate,
        );
      }

      final Map<String, dynamic> updateData = {};
      if (name != null && name != existing.name) {
        updateData['name'] = name.trim();
      }

      if (phone != null && phone != existing.phone) {
        updateData['phone'] = phone.trim();
      }

      if (date != null && date != existing.date) {
        updateData['date'] = date;
      }

      if (time != null && time != existing.time) {
        updateData['time'] = time;
      }

      if (partySize != null && partySize != existing.partySize) {
        updateData['partySize'] = partySize;
      }

      if (tableId != null) {
        updateData['tableId'] = tableId.isEmpty ? null : tableId;
      }

      if (status != null && status != existing.status) {
        updateData['status'] = status.value;
      }

      if (note != null && note != existing.note) {
        updateData['note'] = note.trim();
      }

      if (updateData.isEmpty) {
        return existing;
      }
      final hasPhoneChanged = updateData.containsKey('phone');
      final hasDateChanged = updateData.containsKey('date');
      final hasTimeChanged = updateData.containsKey('time');
      if (hasPhoneChanged || hasDateChanged || hasTimeChanged) {
        final isDuplicate = await _repository.checkDuplicateReservation(
          phone: phoneToValidate,
          date: dateToValidate,
          time: timeToValidate,
          excludeId: id,
          checkActiveOnly: true,
        );
        if (isDuplicate) {
          throw DataException('DUPLICATE');
        }
      }
      final updatedReservation = await _repository.updateReservation(
        id,
        updateData,
      );
      if (updatedReservation == null) {
        throw DataException('Failed to update reservation');
      }
      return updatedReservation;
    } catch (e) {
      if (e is DataException) rethrow;
      throw DataException('Failed to update reservation', originalError: e);
    }
  }

  // Quick update status
  Future<ReservationModel?> updateReservationStatus(
    String id,
    ReservationStatus status,
  ) async {
    print('[Service] Updating reservation status: $id -> ${status.value}');
    return await updateReservation(id: id, status: status);
  }

  // Quick assign table
  Future<ReservationModel?> assignTable(
    String reservationId,
    String tableId,
  ) async {
    print('[Service] Assigning table: $tableId to reservation: $reservationId');
    return await updateReservation(
      id: reservationId,
      tableId: tableId,
      status: ReservationStatus.confirmed,
    );
  }

  void _validateReservationInput({
    required String name,
    required String phone,
    required String date,
    required String time,
    required int partySize,
  }) {
    print('[Reservation service] Validate input ...');
    if (name.isEmpty) {
      throw DataException("Name can't be empty");
    }
    if (phone.isEmpty) {
      throw DataException("Phone can't be empty");
    }
    if (date.isEmpty) {
      throw DataException("Date can't be empty");
    }
    if (time.isEmpty) {
      throw DataException("Time can't be empty");
    }
    if (partySize <= 0) {
      throw DataException("Party size must be greater than 0");
    }
    // Validate date (format: DD-MM-YYYY, must be >= today)
    final dateParts = date.split('-');
    if (dateParts.length != 3) {
      throw DataException('Must be numeric (DD-MM-YYYY)');
    }
    final year = int.tryParse(dateParts[0]);
    final month = int.tryParse(dateParts[1]);
    final day = int.tryParse(dateParts[2]);

    if (day == null || month == null || year == null) {
      throw DataException('Must be numeric (DD-MM-YYYY)');
    }
    final reservationDate = DateTime(year, month, day);
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    if (reservationDate.isBefore(todayStart)) {
      throw DataException('Date must be today or later');
    }

    // Validate time (format: HH:mm, must be 08:00-22:00)
    final timeParts = time.split(':');
    if (timeParts.length != 2) {
      throw DataException('Must be numeric (HH:mm)');
    }

    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);

    if (hour == null || minute == null) {
      throw DataException('Must be numeric (HH:mm)');
    }

    if (hour < 8 || hour > 22 || minute < 0 || minute > 59) {
      throw DataException('Time must be between 08:00 and 22:00');
    }
  }

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

  DateTimeRange getDefaultDateRange() {
    final now = DateTime.now();
    return DateTimeRange(
      start: now.subtract(const Duration(days: 7)),
      end: now.add(const Duration(days: 30)),
    );
  }
}
