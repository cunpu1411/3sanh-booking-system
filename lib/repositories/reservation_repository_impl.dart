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
        query = query.where(orderBy, isGreaterThanOrEqualTo: startDateFormat);
      }
      if (endDate != null) {
        final endDateFormat = _formatDate(endDate);
        query = query.where(orderBy, isLessThanOrEqualTo: endDateFormat);
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
  Future<ReservationModel?> updateReservation(
    String id,
    Map<String, dynamic> data,
  ) async {
    // TODO: implement updateReservation
    try {
      final docRef = await _firestore.collection(_collection).doc(id);
      // Check if document exists
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        print('[Repository] Reservation not found: $id');
        return null;
      }
      final updateData = {...data, 'updateAt': FieldValue.serverTimestamp()};
      await docRef.update(updateData);
      // Fetch and return updated document
      final updatedDoc = await docRef.get();
      if (!updatedDoc.exists) {
        throw DataException('Failed to fetch updated reservation');
      }
      return ReservationModel.fromFirestore(updatedDoc);
    } on FirebaseException catch (e) {
      throw DataException(
        'Failed to update reservation: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      throw DataException('Failed to update reservations', originalError: e);
    }
  }

  /// Helpers
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> listenForNewReservations() {
    final now = Timestamp.now();
    return _firestore
        .collection(_collection)
        .where('createdAt', isGreaterThan: now)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots();
  }

  @override
  Future<List<ReservationModel>> getReservationsByIdList(
    List<String> idList,
  ) async {
    try {
      if (idList.isEmpty) return [];
      final List<ReservationModel> result = [];
      // Firestore limits 'whereIn' queries to 10 items per query
      for (int i = 0; i < idList.length; i += 10) {
        final chunk = idList.sublist(
          i,
          i + 10 > idList.length ? idList.length : i + 10,
        );
        final querySnapshot = await _firestore
            .collection(_collection)
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        result.addAll(
          querySnapshot.docs
              .map((doc) => ReservationModel.fromFirestore(doc))
              .toList(),
        );
      }
      return result;
    } catch (e) {
      throw DataException(
        'Failed to get reservations by id list',
        originalError: e,
      );
    }
  }

  @override
  Future<ReservationModel> createReservation(
    ReservationModel reservation,
  ) async {
    print('[Reservation repository] Create new reservation ...');
    try {
      final docRef = _firestore.collection(_collection).doc();
      final newReservation = reservation.copyWith(
        id: docRef.id,
        createdAt: Timestamp.now(),
      );
      await docRef.set(newReservation.toFirestore());
      return newReservation;
    } catch (e) {
      throw DataException('Failed to create reservation', originalError: e);
    }
  }

  @override
  Future<bool> checkDuplicateReservation({
    required String phone,
    required String date,
    required String time,
    String? excludeId,
    bool checkActiveOnly = true,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('phone', isEqualTo: phone)
          .where('date', isEqualTo: date)
          .where('time', isEqualTo: time);
      if (checkActiveOnly) {
        query = query.where(
          'status',
          whereIn: [
            ReservationStatus.pending.value,
            ReservationStatus.confirmed.value,
          ],
        );
      }
      final querySnapshot = await query.get();
      if (excludeId != null) {
        return querySnapshot.docs.any((doc) => doc.id != excludeId);
      }
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw DataException(
        'Failed to check duplicate reservation',
        originalError: e,
      );
    }
  }
}
