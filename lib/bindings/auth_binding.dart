import 'package:client_web/controllers/authentication/auth_controller.dart';
import 'package:client_web/controllers/authentication/login/login_controller.dart';
import 'package:client_web/repositories/auth_repository.dart';
import 'package:client_web/repositories/auth_repository_impl.dart';
import 'package:client_web/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FirebaseAuth>(() => FirebaseAuth.instance, fenix: true);
    Get.lazyPut<FirebaseFirestore>(
      () => FirebaseFirestore.instance,
      fenix: true,
    );

    Get.lazyPut<AuthRepository>(() => AuthRepositoryImplement(), fenix: true);

    Get.lazyPut<AuthService>(
      () => AuthService(Get.find<AuthRepository>()),
      fenix: true,
    );

    Get.put<AuthController>(
      AuthController(Get.find<AuthService>()),
      permanent: true,
    );
  }
}
