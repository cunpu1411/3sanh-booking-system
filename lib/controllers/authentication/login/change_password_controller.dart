import 'package:client_web/helpers/snackbar_helpers.dart';
import 'package:client_web/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class ChangePasswordController extends GetxController {
  final AuthService _authService;
  ChangePasswordController(this._authService);

  // Form fields
  final currentPassword = ''.obs;
  final newPassword = ''.obs;
  final confirmPassword = ''.obs;

  // Show password states
  final showCurrentPassword = false.obs;
  final showNewPassword = false.obs;
  final showConfirmPassword = false.obs;
  // Validation errors
  final currentPasswordError = Rxn<String>();
  final newPasswordError = Rxn<String>();
  final confirmPasswordError = Rxn<String>();

  // Loading state
  final isLoading = false.obs;

  // Methods
  void setCurrentPassword(String value) {
    currentPassword.value = value;
    currentPasswordError.value = null;
  }

  void setNewPassword(String value) {
    newPassword.value = value;
    newPasswordError.value = null;
  }

  void setConfirmPassword(String value) {
    confirmPassword.value = value;
    confirmPasswordError.value = null;
  }

  void toggleCurrentPasswordVisibility() {
    showCurrentPassword.value = !showCurrentPassword.value;
  }

  void toggleNewPasswordVisibility() {
    showNewPassword.value = !showNewPassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    showConfirmPassword.value = !showConfirmPassword.value;
  }

  /// Change password
  Future<void> changePassword(BuildContext context) async {
    // Validate
    if (!_validate()) return;

    try {
      isLoading.value = true;

      await _authService.changePassword(
        currentPassword: currentPassword.value,
        newPassword: newPassword.value,
        confirmPassword: confirmPassword.value,
      );

      SnackbarHelper.showSuccess(context, 'Đổi mật khẩu thành công');

      // Quay về trang trước
      if (context.mounted) {
        context.pop();
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

    // Current password
    if (currentPassword.value.isEmpty) {
      currentPasswordError.value = 'Vui lòng nhập mật khẩu hiện tại';
      isValid = false;
    }

    // New password
    if (newPassword.value.isEmpty) {
      newPasswordError.value = 'Vui lòng nhập mật khẩu mới';
      isValid = false;
    } else if (newPassword.value.length < 8) {
      newPasswordError.value = 'Mật khẩu phải có ít nhất 8 ký tự';
      isValid = false;
    } else if (newPassword.value == currentPassword.value) {
      newPasswordError.value = 'Mật khẩu mới phải khác mật khẩu cũ';
      isValid = false;
    }

    // Confirm password
    if (confirmPassword.value.isEmpty) {
      confirmPasswordError.value = 'Vui lòng xác nhận mật khẩu';
      isValid = false;
    } else if (confirmPassword.value != newPassword.value) {
      confirmPasswordError.value = 'Mật khẩu xác nhận không khớp';
      isValid = false;
    }

    return isValid;
  }
}
