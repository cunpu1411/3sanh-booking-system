import 'package:client_web/controllers/authentication/auth_controller.dart';
import 'package:client_web/helpers/snackbar_helpers.dart';
import 'package:client_web/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class LoginController extends GetxController {
  final AuthService _authService;
  final AuthController _authController;
  LoginController(this._authService, this._authController);

  // Form fields
  final email = ''.obs;
  final password = ''.obs;
  final rememberMe = false.obs;
  final showPassword = false.obs;

  // Validation errors
  final emailError = Rxn<String>();
  final passwordError = Rxn<String>();

  // Loading state
  final isLoading = false.obs;

  // Methods
  void setEmail(String value) {
    email.value = value;
    emailError.value = null;
  }

  void setPassword(String value) {
    password.value = value;
    passwordError.value = null;
  }

  void setRememberMe(bool? value) {
    rememberMe.value = value ?? false;
  }

  void togglePasswordVisibility() {
    showPassword.value = !showPassword.value;
  }

  /// Login
  Future<void> login(BuildContext context) async {
    // Validate
    if (!_validate()) return;

    try {
      isLoading.value = true;

      // Call service
      final user = await _authService.login(
        email: email.value,
        password: password.value,
        rememberMe: rememberMe.value,
      );

      // Save to global controller
      _authController.setUser(user);

      // Navigate to dashboard
      if (context.mounted) {
        context.go('/admin');
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

  /// Validate form
  bool _validate() {
    bool isValid = true;

    // Email validation
    if (email.value.isEmpty) {
      emailError.value = 'Vui lòng nhập email';
      isValid = false;
    } else if (!GetUtils.isEmail(email.value)) {
      emailError.value = 'Email không hợp lệ';
      isValid = false;
    }

    // Password validation
    if (password.value.isEmpty) {
      passwordError.value = 'Vui lòng nhập mật khẩu';
      isValid = false;
    } else if (password.value.length < 6) {
      passwordError.value = 'Mật khẩu phải có ít nhất 6 ký tự';
      isValid = false;
    }

    return isValid;
  }
}
