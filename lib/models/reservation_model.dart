import 'package:client_web/models/enum/reservation_source.dart';
import 'package:client_web/models/enum/reservation_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationModel {
  final String id;
  final Timestamp createdAt;
  final String date;
  final String time;
  final String name;
  final String phone;
  final int partySize;
  final String? tableId;
  final ReservationSource source;
  final ReservationStatus status;
  final String note;

  ReservationModel({
    required this.id,
    required this.createdAt,
    required this.date,
    required this.time,
    required this.name,
    required this.phone,
    required this.partySize,
    this.tableId,
    required this.source,
    required this.status,
    this.note = '',
  });

  /// Convert from Firestore
  factory ReservationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReservationModel(
      id: doc.id,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      date: data['date'] ?? '',
      time: data['time'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      partySize: data['partySize'] ?? 1,
      tableId: data['tableId'] ?? '',
      source: _parseSource(data['source']),
      status: _parseStatus(data['status']),
      note: data['note'] ?? '',
    );
  }

  /// Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'createdAt': createdAt,
      'date': date,
      'time': time,
      'name': name,
      'phone': phone,
      'partySize': partySize,
      'tableId': tableId,
      'source': source.value,
      'status': status.value,
      'note': note,
    };
  }

  /// Parse source from Firestore
  static ReservationSource _parseSource(dynamic value) {
    if (value == null) return ReservationSource.other;
    final str = value.toString().toLowerCase();
    return ReservationSource.values.firstWhere(
      (e) => e.value == str,
      orElse: () => ReservationSource.other,
    );
  }

  /// Parse status from Firestore
  static ReservationStatus _parseStatus(dynamic value) {
    if (value == null) return ReservationStatus.pending;
    final str = value.toString().toLowerCase();
    return ReservationStatus.values.firstWhere(
      (e) => e.value == str,
      orElse: () => ReservationStatus.pending,
    );
  }

  /// Copy with
  ReservationModel copyWith({
    String? id,
    Timestamp? createdAt,
    String? date,
    String? time,
    String? name,
    String? phone,
    int? partySize,
    String? tableId,
    ReservationSource? source,
    ReservationStatus? status,
    String? note,
  }) {
    return ReservationModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      date: date ?? this.date,
      time: time ?? this.time,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      partySize: partySize ?? this.partySize,
      tableId: tableId ?? this.tableId,
      source: source ?? this.source,
      status: status ?? this.status,
      note: note ?? this.note,
    );
  }
}
