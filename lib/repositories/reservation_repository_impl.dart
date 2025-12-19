import 'package:client_web/core/exceptions/data_exception.dart';
import 'package:client_web/models/enum/reservation_status.dart';
import 'package:client_web/models/paginated_result.dart';
import 'package:client_web/models/reservation_model.dart';
import 'package:client_web/repositories/reservation_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationRepositoryImplement implements ReservationRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'reservations';
  ReservationRepositoryImplement(this._firestore);
  @override
  Future<ReservationModel?> deleteReservations(String id) async {
    // TODO: implement deleteReservations
    try {
      final reservation = await getById(id);
      if (reservation == null) return null;
      await _firestore.collection(_collection).doc(id).delete();
      return reservation;
    } catch (e) {
      throw DataException(
        'Failed to delete reservation: $id',
        originalError: e,
      );
    }
  }

  @override
  Future<ReservationModel?> getById(String id) async {
    // TODO: implement getById
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) return null;
      return ReservationModel.fromFirestore(doc);
    } catch (e) {
      throw DataException('Failed to get reservation: $id', originalError: e);
    }
  }

  @override
  Future<PaginatedResult<ReservationModel>> getReservations({
    int limit = 20,
    DocumentSnapshot? startAfter,
    DateTime? startDate,
    DateTime? endDate,
    ReservationStatus? status,
    String orderBy = 'date',
    bool ascending = false,
  }) async {
    // TODO: implement getReservations
    try {
      Query query = _firestore.collection(_collection);

      /// Apply date range filter
      if (startDate != null) {
        final startDateFormat = _formatDate(startDate);
        query = query.where('date', isGreaterThanOrEqualTo: startDateFormat);
      }
      if (endDate != null) {
        final endDateFormat = _formatDate(endDate);
        query = query.where('date', isLessThanOrEqualTo: endDateFormat);
      }

      /// Apply status filter
      if (status != null) {
        query = query.where('status', isEqualTo: status.value);
      }

      /// Apply ordering
      query = query.orderBy(orderBy, descending: !ascending);

      /// Apply pagination cursor
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      /// Apply limit
      query = query.limit(limit);

      /// Execute query
      final snapshot = await query.get();

      /// Convert to model
      final items = snapshot.docs
          .map((doc) => ReservationModel.fromFirestore(doc))
          .toList();
      final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      return PaginatedResult<ReservationModel>(
        items: items,
        hasMore: items.length == limit,
        lastDocument: lastDoc,
      );
    } catch (e) {
      throw DataException('Failed to get reservations', originalError: e);
    }
  }

  @override
  Future<ReservationModel?> updateReservations(
    String id,
    Map<String, dynamic> data,
  ) async {
    // TODO: implement updateReservations
    try {
      await _firestore.collection(_collection).doc(id).update(data);
      return getById(id);
    } catch (e) {
      throw DataException('Failed to update reservations', originalError: e);
    }
  }

  /// Helpers
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
