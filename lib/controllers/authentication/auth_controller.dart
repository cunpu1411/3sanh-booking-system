import 'package:client_web/models/enum/user_role.dart';
import 'package:client_web/models/user_model.dart';
import 'package:client_web/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final AuthService _authService;
  AuthController(this._authService);

  // Current user (null = none login)
  final Rxn<UserModel> user = Rxn<UserModel>();
  final isCheckingAuth = true.obs;
  // Getters
  bool get isLoggedIn => user.value != null;
  bool get isAdmin => user.value?.role == UserRole.admin;
  bool get isStaff => user.value?.role == UserRole.staff;

  @override
  void onInit() {
    super.onInit();
    _initAuthListener();
  }

  void _initAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((firebaseUser) async {
      try {
        isCheckingAuth.value = true;

        if (firebaseUser != null) {
          final userInfo = await _authService.getUserInfo(firebaseUser.uid);

          if (userInfo != null) {
            user.value = userInfo;
          } else {
            user.value = null;
          }
        } else {
          user.value = null;
        }
      } catch (e) {
        user.value = null;
      } finally {
        isCheckingAuth.value = false;
      }
    });
  }

  /// Check login status when app starts
  Future<void> _checkLoginStatus() async {
    try {
      isCheckingAuth.value = true;
      final currentUser = await _authService.checkLoginStatus();
      user.value = currentUser;
    } catch (e) {
      user.value = null;
    } finally {
      isCheckingAuth.value = false;
    }
  }

  /// Set user after login
  void setUser(UserModel newUser) {
    user.value = newUser;
  }

  /// Logout
  Future<void> logout() async {
    await _authService.logout();
    user.value = null;
  }
}
