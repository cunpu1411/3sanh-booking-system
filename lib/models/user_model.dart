import 'package:client_web/models/enum/user_role.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? phone;
  final UserRole role;
  final bool isActive;
  final Timestamp createdAt;
  final Timestamp? lastLoginAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.lastLoginAt,
  });

  /// From Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'],
      role: UserRole.fromString(data['role'] ?? 'staff'),
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      lastLoginAt: data['lastLoginAt'],
    );
  }

  /// To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role.value,
      'isActive': isActive,
      'createdAt': createdAt,
      'lastLoginAt': lastLoginAt,
    };
  }

  /// Copy with
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? phone,
    UserRole? role,
    bool? isActive,
    Timestamp? createdAt,
    Timestamp? lastLoginAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
