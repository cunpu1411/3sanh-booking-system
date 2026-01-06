import 'package:client_web/models/user_model.dart';
import 'package:client_web/repositories/auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthRepositoryImplement implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Chưa đăng nhập');

      // Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  @override
  Future<UserModel?> getUserInfo(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      print('[Auth repository] Sign in ...');
      if (kIsWeb) {
        print('[Auth repository] Web platform ...');
        // Web platform
        if (rememberMe) {
          print('[Auth repository] Web platform: LOCAL...');
          // LOCAL = localStorage
          await _auth.setPersistence(Persistence.LOCAL);
        } else {
          // SESSION = sessionStorage
          print('[Auth repository] Web platform: SESSION ...');
          await _auth.setPersistence(Persistence.SESSION);
        }
      } else {
        // Mobile/Desktop platform
        print('[Auth repository] Mobile platform ...');
        if (rememberMe) {
          print('[Auth repository] Mobile platform: LOCAL ...');
          await _auth.setPersistence(Persistence.LOCAL);
        } else {
          print('[Auth repository] Mobile platform: SESSION ...');
          await _auth.setPersistence(Persistence.SESSION);
        }
      }
      //  Firebase Auth login
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      // 2. Get user info from Firestore
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        throw Exception('Tài khoản không tồn tại trong hệ thống');
      }

      final user = UserModel.fromFirestore(userDoc);

      // 3. Check if account is active
      if (!user.isActive) {
        await _auth.signOut();
        throw Exception('Tài khoản đã bị vô hiệu hóa');
      }

      // 4. Update last login time
      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } on FirebaseException catch (e) {
      throw _handleFirestoreException(e);
    } catch (e) {
      throw _handleGeneralException(e);
    }
  }

  @override
  Future<void> signOut() async {
    // TODO: implement signOut
    await _auth.signOut();
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
        return 'Thông tin đăng nhập không chính xác hoặc đã hết hạn';
      case 'user-not-found':
        return 'Email không tồn tại';
      case 'wrong-password':
        return 'Mật khẩu không đúng';
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa';
      case 'too-many-requests':
        return 'Quá nhiều lần thử. Vui lòng thử lại sau';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng';
      case 'weak-password':
        return 'Mật khẩu quá yếu';
      case 'email-already-in-use':
        return 'Email đã được sử dụng';
      case 'requires-recent-login':
        return 'Vui lòng đăng nhập lại để thực hiện thao tác này';
      default:
        return e.message ?? 'Đã có lỗi xảy ra';
    }
  }

  String _handleFirestoreException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Bạn không có quyền truy cập. Vui lòng liên hệ quản trị viên';
      case 'unavailable':
        return 'Dịch vụ tạm thời không khả dụng. Vui lòng thử lại sau';
      case 'not-found':
        return 'Dữ liệu không tồn tại';
      case 'already-exists':
        return 'Dữ liệu đã tồn tại';
      case 'resource-exhausted':
        return 'Đã vượt quá giới hạn. Vui lòng thử lại sau';
      case 'failed-precondition':
        return 'Không đáp ứng điều kiện thực hiện';
      case 'aborted':
        return 'Thao tác bị hủy. Vui lòng thử lại';
      case 'out-of-range':
        return 'Giá trị nằm ngoài phạm vi cho phép';
      case 'unauthenticated':
        return 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại';
      case 'deadline-exceeded':
        return 'Hết thời gian xử lý. Vui lòng thử lại';
      default:
        return e.message ?? 'Lỗi hệ thống. Vui lòng thử lại sau';
    }
  }

  String _handleGeneralException(dynamic error) {
    String errorMessage = error.toString().replaceAll('Exception: ', '');

    if (errorMessage.contains('network') ||
        errorMessage.contains('connection') ||
        errorMessage.contains('SocketException')) {
      return 'Lỗi kết nối mạng. Vui lòng kiểm tra internet';
    } else if (errorMessage.contains('timeout') ||
        errorMessage.contains('TimeoutException')) {
      return 'Hết thời gian kết nối. Vui lòng thử lại';
    } else if (errorMessage.contains('format') ||
        errorMessage.contains('FormatException')) {
      return 'Dữ liệu không đúng định dạng';
    } else if (errorMessage.isEmpty ||
        errorMessage == 'null' ||
        errorMessage.length > 150) {
      return 'Lỗi hệ thống. Vui lòng thử lại sau';
    }

    return errorMessage;
  }
}
