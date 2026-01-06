import 'package:client_web/helpers/snackbar_helpers.dart';
import 'package:client_web/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordController extends GetxController {
  final AuthService _authService;
  ForgotPasswordController(this._authService);
  // Form fields
  final email = ''.obs;
  final emailError = Rxn<String>();
  final isLoading = false.obs;
  final isSent = false.obs;

  // Methods
  void setEmail(String value) {
    email.value = value;
    emailError.value = null;
  }

  /// Send reset password email
  Future<void> sendResetEmail(BuildContext context) async {
    // Validate
    if (!_validate()) return;

    try {
      isLoading.value = true;

      await _authService.forgotPassword(email.value);

      isSent.value = true;

      SnackbarHelper.showSuccess(
        context,
        'Email đặt lại mật khẩu đã được gửi. Vui lòng kiểm tra hộp thư.',
      );

      await Future.delayed(Duration(seconds: 2));
      if (context.mounted) {
        context.go('/login');
      }
    } catch (e) {
      SnackbarHelper.showError(
        context,
        e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Validate email
  bool _validate() {
    if (email.value.isEmpty) {
      emailError.value = 'Vui lòng nhập email';
      return false;
    }
    if (!GetUtils.isEmail(email.value)) {
      emailError.value = 'Email không hợp lệ';
      return false;
    }
    return true;
  }

  /// Back to login
  void backToLogin(BuildContext context) {
    context.go('/login');
  }
}
