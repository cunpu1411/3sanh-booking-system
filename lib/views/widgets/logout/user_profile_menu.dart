import 'package:client_web/controllers/authentication/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class UserProfileMenu extends StatelessWidget {
  const UserProfileMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    return Obx(() {
      final user = authController.user.value;

      if (user == null) {
        return const SizedBox.shrink();
      }

      final initial = user.name.isNotEmpty
          ? user.name[0].toUpperCase()
          : user.email[0].toUpperCase();

      return PopupMenuButton<String>(
        offset: const Offset(0, 50),
        tooltip: 'Tài khoản',
        child: _ProfileButton(
          initial: initial,
          name: user.name,
          email: user.email,
        ),
        itemBuilder: (context) => [
          // Header - Thông tin user
          PopupMenuItem<String>(
            enabled: false,
            child: _UserInfoHeader(
              name: user.name,
              email: user.email,
              role: user.role.displayName,
            ),
          ),
          const PopupMenuDivider(),

          // Đổi mật khẩu
          const PopupMenuItem<String>(
            value: 'change-password',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.lock_outline, size: 20),
              title: Text('Đổi mật khẩu'),
            ),
          ),

          // Đăng xuất
          const PopupMenuItem<String>(
            value: 'logout',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.logout, size: 20, color: Colors.red),
              title: Text('Đăng xuất', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
        onSelected: (value) {
          switch (value) {
            case 'change-password':
              context.push('/change-password');
              break;
            case 'logout':
              _showLogoutDialog(context, authController);
              break;
          }
        },
      );
    });
  }

  /// Show logout confirmation dialog
  void _showLogoutDialog(BuildContext context, AuthController authController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );

              // Logout
              await authController.logout();

              // Close loading
              if (context.mounted) {
                Navigator.pop(context);
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}

/// Profile Button - Avatar + Name
class _ProfileButton extends StatelessWidget {
  const _ProfileButton({
    required this.initial,
    required this.name,
    required this.email,
  });

  final String initial;
  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.amber,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Name
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              name.isNotEmpty ? name : email,
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),

          // Dropdown icon
          const Icon(Icons.arrow_drop_down, color: Colors.amber, size: 20),
        ],
      ),
    );
  }
}

/// User Info Header in Dropdown
class _UserInfoHeader extends StatelessWidget {
  const _UserInfoHeader({
    required this.name,
    required this.email,
    required this.role,
  });

  final String name;
  final String email;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),

          // Email
          Text(
            email,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),

          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              role,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.amber.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
