import 'package:cloud_firestore/cloud_firestore.dart';

class DailyMetrics {
  final String date; // Format: YYYY-MM-DD
  final int totalReservations;
  final int pending;
  final int confirmed;
  final int arrived;
  final int noShow;
  final int totalGuests;
  final int lunchCount; // 09:30 - 15:00
  final int dinnerCount; // 17:00 - 23:00
  final int sourcePhone;
  final int sourceWebsite;
  final int sourceWalkin;
  final Map<String, int> hourlyDistribution; // {"11": 5, "12": 8, ...}
  final Map<String, int> partySizeDistribution; // {"2": 10, "4": 15, ...}
  final Timestamp createdAt;
  final Timestamp updatedAt;

  DailyMetrics({
    required this.date,
    required this.totalReservations,
    required this.pending,
    required this.confirmed,
    required this.arrived,
    required this.noShow,
    required this.totalGuests,
    required this.lunchCount,
    required this.dinnerCount,
    required this.sourcePhone,
    required this.sourceWebsite,
    required this.sourceWalkin,
    required this.hourlyDistribution,
    required this.partySizeDistribution,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyMetrics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyMetrics(
      date: data['date'] ?? '',
      totalReservations: data['totalReservations'] ?? 0,
      pending: data['pending'] ?? 0,
      confirmed: data['confirmed'] ?? 0,
      arrived: data['arrived'] ?? 0,
      noShow: data['noShow'] ?? 0,
      totalGuests: data['totalGuests'] ?? 0,
      lunchCount: data['lunchCount'] ?? 0,
      dinnerCount: data['dinnerCount'] ?? 0,
      sourcePhone: data['sourcePhone'] ?? 0,
      sourceWebsite: data['sourceWebsite'] ?? 0,
      sourceWalkin: data['sourceWalkin'] ?? 0,
      hourlyDistribution: Map<String, int>.from(
        data['hourlyDistribution'] ?? {},
      ),
      partySizeDistribution: Map<String, int>.from(
        data['partySizeDistribution'] ?? {},
      ),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': date,
      'totalReservations': totalReservations,
      'pending': pending,
      'confirmed': confirmed,
      'arrived': arrived,
      'noShow': noShow,
      'totalGuests': totalGuests,
      'lunchCount': lunchCount,
      'dinnerCount': dinnerCount,
      'sourcePhone': sourcePhone,
      'sourceWebsite': sourceWebsite,
      'sourceWalkin': sourceWalkin,
      'hourlyDistribution': hourlyDistribution,
      'partySizeDistribution': partySizeDistribution,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
