import 'package:client_web/controllers/authentication/login/forgot_password_controller.dart';
import 'package:client_web/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      ForgotPasswordController(Get.find<AuthService>()),
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade400, Colors.purple.shade400],
          ),
        ),
        child: Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              constraints: BoxConstraints(maxWidth: 400),
              padding: EdgeInsets.all(32),
              child: Obx(
                () => controller.isSent.value
                    ? _buildSuccessView(controller, context)
                    : _buildFormView(controller, context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Form view
  Widget _buildFormView(
    ForgotPasswordController controller,
    BuildContext context,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon
        Icon(Icons.lock_reset, size: 64, color: Colors.blue),
        SizedBox(height: 16),
        Text(
          'Quên mật khẩu?',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Nhập email để nhận link đặt lại mật khẩu',
          style: TextStyle(fontSize: 14, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 32),

        // Email field
        Obx(
          () => TextField(
            onChanged: controller.setEmail,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
              errorText: controller.emailError.value,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
        ),
        SizedBox(height: 24),

        // Send button
        Obx(
          () => SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () => controller.sendResetEmail(context),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: controller.isLoading.value
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('Gửi email', style: TextStyle(fontSize: 16)),
            ),
          ),
        ),
        SizedBox(height: 16),

        // Back to login
        TextButton(
          onPressed: () => controller.backToLogin(context),
          child: Text('Quay lại đăng nhập'),
        ),
      ],
    );
  }

  /// Success view
  Widget _buildSuccessView(
    ForgotPasswordController controller,
    BuildContext context,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle, size: 64, color: Colors.green),
        SizedBox(height: 16),
        Text(
          'Email đã được gửi!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Vui lòng kiểm tra hộp thư và làm theo hướng dẫn để đặt lại mật khẩu.',
          style: TextStyle(fontSize: 14, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => controller.backToLogin(context),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Quay lại đăng nhập', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }
}
