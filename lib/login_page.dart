import 'package:client_web/controllers/authentication/login/login_controller.dart';
import 'package:client_web/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';

import 'controllers/authentication/auth_controller.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      LoginController(Get.find<AuthService>(), Get.find<AuthController>()),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Icon(Icons.restaurant_menu, size: 64, color: Colors.blue),
                  SizedBox(height: 16),
                  Text(
                    '3 Sành Booking',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Đăng nhập hệ thống quản lý',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
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
                  SizedBox(height: 16),

                  // Password field
                  Obx(
                    () => TextField(
                      onChanged: controller.setPassword,
                      obscureText: !controller.showPassword.value,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: Icon(Icons.lock_outlined),
                        errorText: controller.passwordError.value,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.showPassword.value
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: controller.togglePasswordVisibility,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),

                  // Remember me
                  Obx(
                    () => CheckboxListTile(
                      value: controller.rememberMe.value,
                      onChanged: controller.setRememberMe,
                      title: Text('Ghi nhớ đăng nhập'),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  SizedBox(height: 24),

                  // Login button
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : () => controller.login(context),
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
                            : Text('Đăng nhập', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Forgot password
                  TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: Text('Quên mật khẩu?'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
