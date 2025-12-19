import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class MockDataGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  /// Danh sách tên giả (Tiếng Việt)
  final List<String> _firstNames = [
    'Nguyễn',
    'Trần',
    'Lê',
    'Phạm',
    'Hoàng',
    'Huỳnh',
    'Phan',
    'Vũ',
    'Võ',
    'Đặng',
    'Bùi',
    'Đỗ',
    'Hồ',
    'Ngô',
    'Dương',
    'Lý',
  ];

  final List<String> _lastNames = [
    'Văn An',
    'Thị Bình',
    'Minh Châu',
    'Hoàng Dũng',
    'Thu Hà',
    'Văn Hùng',
    'Thị Lan',
    'Quốc Khánh',
    'Thị Mai',
    'Văn Nam',
    'Thị Nga',
    'Minh Phương',
    'Văn Quân',
    'Thị Thảo',
    'Văn Tùng',
    'Thị Uyên',
    'Minh Vũ',
    'Thị Xuân',
    'Văn Yên',
    'Thị Hương',
  ];

  /// Danh sách ghi chú giả
  final List<String> _notes = [
    'Cần chỗ ngồi yên tĩnh',
    'Có trẻ em',
    'Sinh nhật',
    'Kỷ niệm',
    'Gần cửa sổ',
    'Không gần bếp',
    'Cần ghế cao cho bé',
    'Ăn chay',
    'Dị ứng hải sản',
    '',
    '',
    '', // Nhiều note rỗng để realistic hơn
  ];

  /// Generate một số điện thoại giả (format Việt Nam)
  String _generatePhone() {
    // Format: 09X hoặc 03X hoặc 07X + 8 số
    final prefixes = [
      '090',
      '091',
      '093',
      '094',
      '097',
      '098',
      '032',
      '033',
      '034',
      '035',
      '036',
      '037',
      '038',
      '039',
      '070',
      '076',
      '077',
      '078',
      '079',
    ];
    final prefix = prefixes[_random.nextInt(prefixes.length)];
    final suffix = List.generate(7, (_) => _random.nextInt(10)).join();
    return '$prefix$suffix';
  }

  /// Generate tên ngẫu nhiên
  String _generateName() {
    final firstName = _firstNames[_random.nextInt(_firstNames.length)];
    final lastName = _lastNames[_random.nextInt(_lastNames.length)];
    return '$firstName $lastName';
  }

  /// Generate ngày ngẫu nhiên (từ 30 ngày trước đến 60 ngày sau)
  String _generateDate() {
    final now = DateTime.now();
    // Random từ -30 đến +60 ngày
    final daysOffset = _random.nextInt(90) - 30;
    final date = now.add(Duration(days: daysOffset));
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Generate giờ ngẫu nhiên (11:00 - 21:00)
  String _generateTime() {
    final hour = 11 + _random.nextInt(11); // 11-21
    final minute = _random.nextBool() ? '00' : '30'; // Chỉ :00 hoặc :30
    return '${hour.toString().padLeft(2, '0')}:$minute';
  }

  /// Generate số người (1-12)
  int _generatePartySize() {
    // Phân bố: 70% là 2-4 người, 20% là 5-6 người, 10% là 7-12 người
    final rand = _random.nextInt(100);
    if (rand < 70) {
      return 2 + _random.nextInt(3); // 2-4
    } else if (rand < 90) {
      return 5 + _random.nextInt(2); // 5-6
    } else {
      return 7 + _random.nextInt(6); // 7-12
    }
  }

  /// Generate source
  String _generateSource() {
    final sources = ['phone', 'website', 'walkin', 'other'];
    final weights = [40, 35, 20, 5]; // % probability

    final rand = _random.nextInt(100);
    int cumulative = 0;
    for (int i = 0; i < sources.length; i++) {
      cumulative += weights[i];
      if (rand < cumulative) return sources[i];
    }
    return 'website';
  }

  /// Generate status
  String _generateStatus(String dateStr) {
    // Logic: Nếu ngày đã qua → arrived hoặc no_show
    //        Nếu ngày chưa đến → pending hoặc confirmed
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();

      if (date.isBefore(now)) {
        // Đã qua: 80% arrived, 15% no_show, 5% pending
        final rand = _random.nextInt(100);
        if (rand < 80) return 'arrived';
        if (rand < 95) return 'no_show';
        return 'pending';
      } else {
        // Chưa đến: 60% confirmed, 40% pending
        return _random.nextBool() && _random.nextBool()
            ? 'pending'
            : 'confirmed';
      }
    } catch (e) {
      return 'pending';
    }
  }

  /// Generate note (70% không có note)
  String _generateNote() {
    if (_random.nextInt(100) < 70) return '';
    return _notes[_random.nextInt(_notes.length)];
  }

  /// Generate một reservation
  Map<String, dynamic> _generateReservation() {
    final date = _generateDate();
    final status = _generateStatus(date);

    return {
      'name': _generateName(),
      'phone': _generatePhone(),
      'date': date,
      'time': _generateTime(),
      'partySize': _generatePartySize(),
      'source': _generateSource(),
      'status': status,
      'note': _generateNote(),
      'tableId': '', // Để trống
      'createdAt': Timestamp.now(),
    };
  }

  /// Generate và thêm vào Firestore
  Future<void> generateAndAddReservations({
    required int count,
    required Function(int current, int total) onProgress,
    required Function(String message) onComplete,
    required Function(String error) onError,
  }) async {
    try {
      final batch = _firestore.batch();
      int batchCount = 0;
      int totalAdded = 0;

      for (int i = 0; i < count; i++) {
        final reservation = _generateReservation();
        final docRef = _firestore.collection('reservations').doc();

        batch.set(docRef, reservation);
        batchCount++;

        // Firestore batch limit là 500, commit mỗi 400 để an toàn
        if (batchCount >= 400) {
          await batch.commit();
          totalAdded += batchCount;
          onProgress(totalAdded, count);

          // Reset batch
          batchCount = 0;

          // Delay nhỏ để tránh rate limit
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      // Commit batch cuối cùng
      if (batchCount > 0) {
        await batch.commit();
        totalAdded += batchCount;
      }

      onComplete('✅ Đã thêm thành công $totalAdded reservations!');
    } catch (e) {
      onError('❌ Lỗi: $e');
    }
  }
}
