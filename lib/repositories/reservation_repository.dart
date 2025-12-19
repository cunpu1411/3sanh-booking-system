import 'package:client_web/models/enum/reservation_status.dart';
import 'package:client_web/models/paginated_result.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/reservation_model.dart';

abstract class ReservationRepository {
  /// Get reservations by id
  Future<ReservationModel?> getById(String id);

  /// Get paginated reservations
  Future<PaginatedResult<ReservationModel>> getReservations({
    int limit = 20,
    DocumentSnapshot? startAfter,
    DateTime? startDate,
    DateTime? endDate,
    ReservationStatus? status,
    String orderBy = 'createdAt',
    bool ascending = false,
  });

  /// Update reservations by id
  Future<ReservationModel?> updateReservations(
    String id,
    Map<String, dynamic> data,
  );

  /// Delete reservations
  Future<ReservationModel?> deleteReservations(String id);
}
