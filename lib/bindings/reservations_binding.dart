import 'package:client_web/controllers/reservations/reservations_controller.dart';
import 'package:client_web/repositories/reservation_repository.dart';
import 'package:client_web/repositories/reservation_repository_impl.dart';
import 'package:client_web/services/reservation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class ReservationsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<FirebaseFirestore>()) {
      Get.put<FirebaseFirestore>(FirebaseFirestore.instance, permanent: true);
    }
    Get.lazyPut<ReservationRepository>(
      () => ReservationRepositoryImplement(Get.find<FirebaseFirestore>()),
    );
    Get.lazyPut<ReservationService>(
      () => ReservationService(Get.find<ReservationRepository>()),
    );
    Get.lazyPut<ReservationsController>(
      () => ReservationsController(Get.find<ReservationService>()),
    );
  }
}
