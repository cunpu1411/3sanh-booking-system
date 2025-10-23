// lib/dev_seed_menu.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DevSeedMenuPage extends StatelessWidget {
  const DevSeedMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = <Map<String, dynamic>>[
      {"category":"Miền Bắc","name":"Bò kéo pháo","price":169000.0,"imageUrl":"assets/dishes/bo_keo_phao_1.png","isAvailable":true},
      {"category":"Miền Bắc","name":"Đậu hũ trứng 3 Sành","price":99000.0,"imageUrl":"assets/dishes/dau_hu_trung_1.png","isAvailable":true},
      {"category":"Miền Bắc","name":"Cá thác lác rút xương","price":139000.0,"imageUrl":"assets/dishes/ca_thac_lat_rut_xuong_1.png","isAvailable":true},
      {"category":"Miền Bắc","name":"Nọng đặc vụ mắm tỏi","price":159000.0,"imageUrl":"assets/dishes/nong_dac_vu_mam_toi_1.png","isAvailable":true},

      {"category":"Miền Trung","name":"Cá dìa nướng muối","price":159000.0,"imageUrl":"assets/dishes/ca_dia_nuong_muoi_1.png","isAvailable":true},
      {"category":"Miền Trung","name":"Hột vịt lộn om bầu","price":129000.0,"imageUrl":"assets/dishes/hot_vit_lon_om_bau_1.png","isAvailable":true},
      {"category":"Miền Trung","name":"Lẩu gà ớt hiểm (nhỏ)","price":199000.0,"imageUrl":"assets/dishes/lau_ga_ot_hiem_1.png","isAvailable":true},

      {"category":"Miền Nam","name":"Tôm xông cay Tiền lửa","price":169000.0,"imageUrl":"assets/dishes/tom_xong_cay_tien_lua_mien_nam_1.png","isAvailable":true},
      {"category":"Miền Nam","name":"Chân gà sốt Thái","price":99000.0,"imageUrl":"assets/dishes/chan_ga_sot_thai_1.png","isAvailable":true},
      {"category":"Miền Nam","name":"Mực sốt Thái","price":169000.0,"imageUrl":"assets/dishes/muc_sot_thai_1.png","isAvailable":true},

      {"category":"Đặc sản","name":"Khoai mạt nướng sốt 3 Sành","price":79000.0,"imageUrl":"assets/dishes/khoai_mat_nuong_sot_3_sanh_1.png","isAvailable":true},
      {"category":"Đặc sản","name":"Sụn gà muối tuyết","price":119000.0,"imageUrl":"assets/dishes/sun_ga_muoi_tuyet_1.png","isAvailable":true},
      {"category":"Đặc sản","name":"Khoai môn du kích","price":119000.0,"imageUrl":"assets/dishes/khoai_mon_du_kich_1.png","isAvailable":true},
      {"category":"Đặc sản","name":"Tóp mỡ mắm tỏi","price":129000.0,"imageUrl":"assets/dishes/top_mo_mam_toi_1.png","isAvailable":true},

      {"category":"Món chính & Cơm/Mì","name":"Cơm ghẹ phủ trứng","price":149000.0,"imageUrl":"assets/dishes/com_ghe_phu_trung_1.png","isAvailable":true},
      {"category":"Món chính & Cơm/Mì","name":"Mì xào Hợp Tác Xã","price":119000.0,"imageUrl":"assets/dishes/mi_xao_hop_tac_xa_1.png","isAvailable":true},
      {"category":"Món chính & Cơm/Mì","name":"Bò măng tây","price":179000.0,"imageUrl":"assets/dishes/bo_mang_tay_1.png","isAvailable":true},

      {"category":"Canh - Lẩu","name":"Canh hến nấu thơm","price":99000.0,"imageUrl":"assets/dishes/lau_ga_ot_hiem_1.png","isAvailable":true},
      {"category":"Canh - Lẩu","name":"Lẩu gà ớt hiểm","price":249000.0,"imageUrl":"assets/dishes/lau_ga_ot_hiem_1.png","isAvailable":true},

      {"category":"Hải sản - Nướng","name":"Tôm nướng sốt 3 Sành","price":159000.0,"imageUrl":"assets/dishes/tom_nuong_1.png","isAvailable":true},
      {"category":"Hải sản - Nướng","name":"Cá dìa nướng muối","price":159000.0,"imageUrl":"assets/dishes/ca_dia_nuong_muoi_1.png","isAvailable":true},
      {"category":"Hải sản - Nướng","name":"Nạc nọng nướng","price":159000.0,"imageUrl":"assets/dishes/nat_nong_nuong_1.png","isAvailable":true},

      {"category":"Ốc - Hải sản nóng","name":"Ốc bươu hấp tiêu","price":99000.0,"imageUrl":"assets/dishes/oc_buou_hap_tieu_1.png","isAvailable":true},

      {"category":"Khô - Mắm - Nướng","name":"Khô cá dứa","price":79000.0,"imageUrl":"assets/dishes/kho_ca_dua_1.png","isAvailable":true},
    ];

    Future<void> _seed() async {
      final col = FirebaseFirestore.instance.collection('menuItems');
      for (final m in data) {
        await col.add({
          ...m,
          'createdAt': DateTime.now(),
        });
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('[DEV] Seed menuItems')),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: _seed,
          icon: const Icon(Icons.cloud_upload),
          label: const Text('Seed toàn bộ menuItems vào Firestore'),
        ),
      ),
    );
  }
}
