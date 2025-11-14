import 'package:client_web/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;
  final reservationsRef = firestore.collection('reservations');

  // Sample data
  final testData = [
    {
      'name': 'Nguyễn Văn A',
      'phone': '0901234567',
      'date': '2025-11-15',
      'time': '19:00',
      'partySize': 4,
      'note': 'Muốn ngồi gần cửa sổ',
      'createdAt': FieldValue.serverTimestamp(),
      'source': 'web',
      'status': 'pending',
      'tableId': null,
    },
    {
      'name': 'Trần Thị B',
      'phone': '0912345678',
      'date': '2025-11-14',
      'time': '18:30',
      'partySize': 2,
      'note': 'Sinh nhật',
      'createdAt': FieldValue.serverTimestamp(),
      'source': 'web',
      'status': 'pending',
      'tableId': null,
    },
    {
      'name': 'Lê Văn C',
      'phone': '0923456789',
      'date': '2025-11-16',
      'time': '20:00',
      'partySize': 6,
      'note': '',
      'createdAt': FieldValue.serverTimestamp(),
      'source': 'web',
      'status': 'pending',
      'tableId': null,
    },
    {
      'name': 'Phạm Thị D',
      'phone': '0934567890',
      'date': '2025-11-15',
      'time': '19:30',
      'partySize': 3,
      'note': 'Dị ứng hải sản',
      'createdAt': FieldValue.serverTimestamp(),
      'source': 'web',
      'status': 'pending',
      'tableId': null,
    },
    {
      'name': 'Hoàng Văn E',
      'phone': '0945678901',
      'date': '2025-11-17',
      'time': '18:00',
      'partySize': 8,
      'note': 'Cần phòng riêng',
      'createdAt': FieldValue.serverTimestamp(),
      'source': 'web',
      'status': 'pending',
      'tableId': null,
    },
    {
      'name': 'Đỗ Thị F',
      'phone': '0956789012',
      'date': '2025-11-13',
      'time': '12:00',
      'partySize': 2,
      'note': 'Ăn trưa',
      'createdAt': FieldValue.serverTimestamp(),
      'source': 'web',
      'status': 'pending',
      'tableId': null,
    },
    {
      'name': 'Vũ Văn G',
      'phone': '0967890123',
      'date': '2025-11-18',
      'time': '19:00',
      'partySize': 5,
      'note': 'Có trẻ em',
      'createdAt': FieldValue.serverTimestamp(),
      'source': 'web',
      'status': 'pending',
      'tableId': null,
    },
    {
      'name': 'Bùi Thị H',
      'phone': '0978901234',
      'date': '2025-11-15',
      'time': '20:30',
      'partySize': 4,
      'note': '',
      'createdAt': FieldValue.serverTimestamp(),
      'source': 'web',
      'status': 'pending',
      'tableId': null,
    },
    {
      'name': 'Đinh Văn I',
      'phone': '0989012345',
      'date': '2025-11-20',
      'time': '18:30',
      'partySize': 10,
      'note': 'Tiệc tất niên',
      'createdAt': FieldValue.serverTimestamp(),
      'source': 'web',
      'status': 'pending',
      'tableId': null,
    },
    {
      'name': 'Mai Thị K',
      'phone': '0990123456',
      'date': '2025-11-14',
      'time': '19:00',
      'partySize': 2,
      'note': 'Hẹn hò',
      'createdAt': FieldValue.serverTimestamp(),
      'source': 'web',
      'status': 'pending',
      'tableId': null,
    },
  ];

  print('Đang thêm ${testData.length} reservations...');

  for (final data in testData) {
    await reservationsRef.add(data);
  }

  print('✅ Hoàn thành!');
}
