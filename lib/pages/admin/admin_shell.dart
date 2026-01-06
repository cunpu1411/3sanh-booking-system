import 'package:client_web/bindings/reservations_binding.dart';
import 'package:client_web/controllers/authentication/auth_controller.dart';
import 'package:client_web/models/enum/user_role.dart';
import 'package:client_web/views/widgets/logout/user_profile_menu.dart';
import 'package:client_web/views/widgets/reservations/notification_badge.dart';
import 'package:client_web/views/widgets/reservations/notification_panel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.child});
  final Widget child;
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  bool? _darkOverride;
  @override
  void initState() {
    super.initState();
    ReservationsBinding().dependencies();
  }

  void _openRouteInNewTab(String path) {
    String clean = path.trim();
    if (clean.isEmpty) clean = '/';
    if (!clean.startsWith('/')) clean = '/$clean';
    final b = Uri.base;
    final origin = '${b.scheme}://${b.host}${b.hasPort ? ':${b.port}' : ''}';
    final url = '$origin/#$clean';
    launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
  }

  @override
  Widget build(BuildContext context) {
    final sysDark =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final isDark = _darkOverride ?? sysDark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F7);

    final currentPath = GoRouterState.of(context).matchedLocation;
    final activeMenu = _getActiveMenu(currentPath);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: bgColor,
          body: Row(
            children: [
              _Sidebar(
                active: activeMenu,
                onTap: (menu) {
                  context.go('/admin/$menu');
                },
                isDark: isDark,
              ),
              Expanded(
                child: Column(
                  children: [
                    _Header(
                      isDark: isDark,
                      title: _getTitle(activeMenu),
                      onToggleTheme: () => setState(() {
                        if (_darkOverride == null) {
                          _darkOverride = !sysDark;
                        } else if (_darkOverride == true) {
                          _darkOverride = false;
                        } else {
                          _darkOverride = null;
                        }
                      }),
                      overrideState: _darkOverride,
                      onOpenRoute: _openRouteInNewTab,
                    ),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
            ],
          ),
        ),
        const NotificationPanel(),
      ],
    );
  }

  /// Get active menu from current path
  String _getActiveMenu(String path) {
    if (path.startsWith('/admin/dashboard')) return 'dashboard';
    if (path.startsWith('/admin/reservations')) return 'reservations';
    if (path.startsWith('/admin/analytics')) return 'analytics';
    if (path.startsWith('/admin/settings')) return 'settings';
    if (path.startsWith('/admin/users')) return 'users';
    return 'dashboard';
  }

  /// Get title from menu
  String _getTitle(String menu) {
    return switch (menu) {
      'dashboard' => 'Admin Dashboard',
      'reservations' => 'Reservations',
      'analytics' => 'Analytics',
      'settings' => 'Settings',
      'users' => 'User Management',
      _ => 'Admin',
    };
  }
}

/* ===================== SIDEBAR ===================== */
class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.active,
    required this.onTap,
    required this.isDark,
  });

  final String active;
  final Function(String) onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final user = authController.user.value;
    final isAdmin = user?.role == UserRole.admin;

    // 🔥 Define menu items với visibility rules
    // Format: (id, icon, label, visibleForStaff, visibleForAdmin)
    final items = [
      ('dashboard', Icons.dashboard, 'Dashboard', false, true), // Chỉ Admin
      (
        'reservations',
        Icons.event_note,
        'Reservations',
        true,
        true,
      ), // Admin + Staff
      (
        'analytics',
        Icons.analytics_outlined,
        'Analytics',
        false,
        true,
      ), // Chỉ Admin
      (
        'settings',
        Icons.settings_outlined,
        'Settings',
        false,
        true,
      ), // Chỉ Admin
      ('users', Icons.people_outline, 'Users', false, true), // Chỉ Admin
    ];

    return Container(
      width: 220,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.black,
      child: Column(
        children: [
          const SizedBox(height: 30),
          const Text(
            '3 SÀNH',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 40),

          // 🔥 Hiển thị menu theo role
          for (final item in items)
            if (_canViewMenuItem(item, isAdmin))
              _SidebarItem(
                icon: item.$2,
                label: item.$3,
                selected: active == item.$1,
                onTap: () => onTap(item.$1),
                isDark: isDark,
              ),

          const Spacer(),

          // 🔥 Hiển thị role badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isAdmin
                    ? Colors.amber.withValues(alpha: 0.2)
                    : Colors.blue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isAdmin
                      ? Colors.amber.withValues(alpha: 0.5)
                      : Colors.blue.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isAdmin ? Icons.admin_panel_settings : Icons.person,
                    size: 16,
                    color: isAdmin ? Colors.amber : Colors.blue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isAdmin ? 'Admin' : 'Staff',
                    style: TextStyle(
                      color: isAdmin ? Colors.amber : Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              '© 2025 3 Sành',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Check if user can view menu item
  /// item format: (id, icon, label, visibleForStaff, visibleForAdmin)
  bool _canViewMenuItem(
    (String, IconData, String, bool, bool) item,
    bool isAdmin,
  ) {
    final visibleForStaff = item.$4;
    final visibleForAdmin = item.$5;

    if (isAdmin) {
      return visibleForAdmin;
    } else {
      return visibleForStaff;
    }
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Colors.amber.shade400
        : (isDark ? Colors.white70 : Colors.white);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        color: selected
            ? Colors.amber.shade700.withValues(alpha: 0.25)
            : Colors.transparent,
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/* ===================== HEADER ===================== */
class _Header extends StatelessWidget {
  const _Header({
    required this.isDark,
    required this.title,
    required this.onToggleTheme,
    required this.overrideState,
    required this.onOpenRoute,
  });

  final bool isDark;
  final String title;
  final VoidCallback onToggleTheme;
  final bool? overrideState;
  final void Function(String route) onOpenRoute;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String tooltip;
    if (overrideState == null) {
      icon = isDark ? Icons.nightlight_round : Icons.wb_sunny_outlined;
      tooltip = 'Theo hệ thống • Bấm để chuyển';
    } else if (overrideState == true) {
      icon = Icons.nightlight_round;
      tooltip = 'Đang Dark • Bấm để Light';
    } else {
      icon = Icons.wb_sunny_outlined;
      tooltip = 'Đang Light • Bấm để theo hệ thống';
    }

    return Container(
      height: 60,
      color: isDark ? const Color(0xFF202020) : Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const SizedBox(width: 8),
          const Text(
            '3 SÀNH',
            style: TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          NotificationBadge(),
          const SizedBox(width: 8),
          _OpenPageButton(onOpen: onOpenRoute),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onToggleTheme,
            tooltip: tooltip,
            icon: Icon(icon, color: Colors.amber),
          ),
          const SizedBox(width: 8),
          const UserProfileMenu(),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

/* ===================== OPEN PAGE BUTTON ===================== */
class _OpenPageButton extends StatelessWidget {
  const _OpenPageButton({required this.onOpen});
  final void Function(String route) onOpen;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Open Page (new tab)',
      icon: const Icon(Icons.open_in_new, color: Colors.amber),
      onSelected: (value) async {
        if (value == '__custom__') {
          final controller = TextEditingController(text: '/');
          final route = await showDialog<String>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Open custom route'),
              content: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: '/, /order, /menu?tab=1, ...',
                ),
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, controller.text.trim()),
                  child: const Text('Mở'),
                ),
              ],
            ),
          );
          if (route != null && route.isNotEmpty) onOpen(route);
        } else {
          onOpen(value);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: '/',
          child: ListTile(
            leading: Icon(Icons.home_outlined),
            title: Text('Homepage (/)'),
          ),
        ),
        const PopupMenuItem(
          value: '/menu',
          child: ListTile(
            leading: Icon(Icons.restaurant_menu),
            title: Text('Menu (/menu)'),
          ),
        ),
        const PopupMenuItem(
          value: '/order',
          child: ListTile(
            leading: Icon(Icons.shopping_bag_outlined),
            title: Text('Order (/order)'),
          ),
        ),
        const PopupMenuItem(
          value: '/book',
          child: ListTile(
            leading: Icon(Icons.event_available),
            title: Text('Booking (/book)'),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: '__custom__',
          child: ListTile(
            leading: Icon(Icons.edit_note),
            title: Text('Custom route…'),
          ),
        ),
      ],
    );
  }
}
