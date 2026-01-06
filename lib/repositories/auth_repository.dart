import 'package:client_web/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  /// Sign in with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
    bool rememberMe = false,
  });

  /// Sign out
  Future<void> signOut();

  /// Get current user
  User? getCurrentUser();

  /// Get user info in firestore
  Future<UserModel?> getUserInfo(String uid);

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email);

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
