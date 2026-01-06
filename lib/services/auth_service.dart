import 'package:client_web/models/user_model.dart';
import 'package:client_web/repositories/auth_repository.dart';
import 'package:client_web/repositories/auth_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final AuthRepository _repository;
  AuthService(this._repository);

  /// Login
  Future<UserModel> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    // Validate
    if (email.isEmpty) throw Exception('Vui lòng nhập email');
    if (password.isEmpty) throw Exception('Vui lòng nhập mật khẩu');

    // Login
    final user = await _repository.signIn(
      email: email.trim(),
      password: password,
      rememberMe: rememberMe,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', rememberMe);
    // Save email if remember me
    if (rememberMe) {
      await prefs.setString('savedEmail', email.trim());
    } else {
      await prefs.remove('savedEmail');
    }
    return user;
  }

  /// Get user info
  Future<UserModel?> getUserInfo(String uid) async {
    return await _repository.getUserInfo(uid);
  }

  /// Logout
  Future<void> logout() async {
    await _repository.signOut();

    // Clear remember me
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('rememberMe');
  }

  /// Check if user is logged in
  Future<UserModel?> checkLoginStatus() async {
    final currentUser = _repository.getCurrentUser();
    if (currentUser == null) return null;

    return await _repository.getUserInfo(currentUser.uid);
  }

  /// Forgot password
  Future<void> forgotPassword(String email) async {
    if (email.isEmpty) throw Exception('Vui lòng nhập email');
    await _repository.sendPasswordResetEmail(email.trim());
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    // Validate
    if (currentPassword.isEmpty) {
      throw Exception('Vui lòng nhập mật khẩu hiện tại');
    }
    if (newPassword.isEmpty) {
      throw Exception('Vui lòng nhập mật khẩu mới');
    }
    if (newPassword.length < 8) {
      throw Exception('Mật khẩu mới phải có ít nhất 8 ký tự');
    }
    if (newPassword != confirmPassword) {
      throw Exception('Mật khẩu xác nhận không khớp');
    }
    if (currentPassword == newPassword) {
      throw Exception('Mật khẩu mới phải khác mật khẩu cũ');
    }

    await _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
