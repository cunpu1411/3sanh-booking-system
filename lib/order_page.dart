import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

// ====== PDF / Printing ======
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});
  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final money = NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0);

  int _cartCount = 0;

  // ==== cache font cho PDF ====
  pw.Font? _fontRegular;
  pw.Font? _fontBold;
  bool _fontsReady = false;

  // ====== Dữ liệu món theo nhóm ======
  final Map<String, List<_OrderItem>> catalog = {
    'Miền Bắc': [
      _OrderItem('Bò kéo pháo', 169000, 'assets/dishes/bo_keo_phao_1.png'),
      _OrderItem('Đậu hũ trứng 3 Sành', 99000, 'assets/dishes/dau_hu_trung_1.png'),
      _OrderItem('Cá thác lác rút xương', 139000, 'assets/dishes/ca_thac_lat_rut_xuong_1.png'),
      _OrderItem('Nọng đặc vụ mắm tỏi', 159000, 'assets/dishes/nong_dac_vu_mam_toi_1.png'),
    ],
    'Miền Trung': [
      _OrderItem('Cá dìa nướng muối', 159000, 'assets/dishes/ca_dia_nuong_muoi_1.png'),
      _OrderItem('Hột vịt lộn om bầu', 129000, 'assets/dishes/hot_vit_lon_om_bau_1.png'),
      _OrderItem('Lẩu gà ớt hiểm (nhỏ)', 199000, 'assets/dishes/lau_ga_ot_hiem_1.png'),
    ],
    'Miền Nam': [
      _OrderItem('Tôm xông cay Tiền lửa', 169000, 'assets/dishes/tom_xong_cay_tien_lua_mien_nam_1.png'),
      _OrderItem('Chân gà sốt Thái', 99000, 'assets/dishes/chan_ga_sot_thai_1.png'),
      _OrderItem('Mực sốt Thái', 169000, 'assets/dishes/muc_sot_thai_1.png'),
    ],
    'Đặc sản': [
      _OrderItem('Khoai mạt nướng sốt 3 Sành', 79000, 'assets/dishes/khoai_mat_nuong_sot_3_sanh_1.png'),
      _OrderItem('Sụn gà muối tuyết', 119000, 'assets/dishes/sun_ga_muoi_tuyet_1.png'),
      _OrderItem('Khoai môn du kích', 119000, 'assets/dishes/khoai_mon_du_kich_1.png'),
      _OrderItem('Tóp mỡ mắm tỏi', 129000, 'assets/dishes/top_mo_mam_toi_1.png'),
    ],
    'Món chính & Cơm/Mì': [
      _OrderItem('Cơm ghẹ phủ trứng', 149000, 'assets/dishes/com_ghe_phu_trung_1.png'),
      _OrderItem('Mì xào Hợp Tác Xã', 119000, 'assets/dishes/mi_xao_hop_tac_xa_1.png'),
      _OrderItem('Bò măng tây', 179000, 'assets/dishes/bo_mang_tay_1.png'),
    ],
    'Canh - Lẩu': [
      // ĐÃ ĐỔI THEO YÊU CẦU
      _OrderItem('Nghêu nấu khế', 99000, 'assets/dishes/ngheu_nau_khe_1.png'),
      _OrderItem('Lẩu gà ớt hiểm', 249000, 'assets/dishes/lau_ga_ot_hiem_1.png'),
    ],
    'Hải sản - Nướng': [
      _OrderItem('Tôm nướng sốt 3 Sành', 159000, 'assets/dishes/tom_nuong_1.png'),
      _OrderItem('Cá dìa nướng muối', 159000, 'assets/dishes/ca_dia_nuong_muoi_1.png'),
      _OrderItem('Nạc nọng nướng', 159000, 'assets/dishes/nat_nong_nuong_1.png'),
    ],
    'Ốc - Hải sản nóng': [
      _OrderItem('Ốc bươu hấp tiêu', 99000, 'assets/dishes/oc_buou_hap_tieu_1.png'),
    ],
    'Khô - Mắm - Nướng': [
      _OrderItem('Khô cá dứa', 79000, 'assets/dishes/kho_ca_dua_1.png'),
    ],
  };

  // ====== Giỏ hàng ======
  final List<_CartLine> _cart = [];

  void _addToCart(_OrderItem it) {
    final idx = _cart.indexWhere((e) => e.item.name == it.name);
    if (idx >= 0) {
      _cart[idx] = _cart[idx].copyWith(qty: _cart[idx].qty + 1);
    } else {
      _cart.add(_CartLine(item: it, qty: 1));
    }
    setState(() => _cartCount = _cart.fold<int>(0, (s, e) => s + e.qty));
  }

  int get _total => _cart.fold<int>(0, (s, e) => s + e.qty * e.item.price);

  // ===== lifecycle: load fonts once =====
  @override
  void initState() {
    super.initState();
    _loadInvoiceFonts();
  }

  Future<void> _loadInvoiceFonts() async {
    try {
      _fontRegular = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
      _fontBold = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
      setState(() => _fontsReady = true);
    } catch (_) {
      // nếu thiếu font vẫn cho in với font mặc định (có thể lỗi dấu)
      _fontsReady = false;
    }
  }

  // ====== PDF HOÁ ĐƠN ======
  Future<void> _exportInvoicePdf(BuildContext context) async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giỏ hàng trống – hãy thêm món trước khi xuất hóa đơn.')),
      );
      return;
    }

    try {
      final theme = (_fontRegular != null && _fontBold != null)
          ? pw.ThemeData.withFont(base: _fontRegular!, bold: _fontBold!)
          : pw.ThemeData.base();

      final doc = pw.Document(theme: theme);

      // 2) Data header
      final now = DateTime.now();
      final dateStr = DateFormat('dd/MM/yyyy – HH:mm').format(now);
      final invoiceNo = DateFormat('yyyyMMddHHmmss').format(now);

      // 3) Page format: 80mm (thermal). MultiPage để cao bao nhiêu cũng vừa.
      final pageFormat = const PdfPageFormat(
        80 * PdfPageFormat.mm, // width
        297 * PdfPageFormat.mm, // height flexible
        marginAll: 6,
      );

      doc.addPage(
        pw.MultiPage(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          build: (ctx) => [
            // ===== Header =====
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('IN LẠI - HÓA ĐƠN THANH TOÁN',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.Text('Số HĐ: $invoiceNo', style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Bàn: Bàn 13 - NGOÀI', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('Thu ngân: NV01', style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Giờ vào: $dateStr', style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Divider(thickness: 0.7),

            // ===== Bảng món =====
            pw.TableHelper.fromTextArray(
              headers: const ['STT', 'Tên món', 'SL', 'Đơn giá', 'Thành tiền'],
              data: _cart.asMap().entries.map((e) {
                final i = e.key + 1;
                final line = e.value;
                return [
                  '$i',
                  line.item.name,
                  '${line.qty}',
                  money.format(line.item.price),
                  money.format(line.qty * line.item.price),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellStyle: const pw.TextStyle(fontSize: 9),
              columnWidths: {
                0: const pw.FixedColumnWidth(20), // STT
                1: const pw.FlexColumnWidth(4), // Tên món
                2: const pw.FixedColumnWidth(24), // SL
                3: const pw.FlexColumnWidth(3), // Đơn giá
                4: const pw.FlexColumnWidth(3), // Thành tiền
              },
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
              },
              border: pw.TableBorder.all(width: 0.5),
              headerPadding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              cellPadding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
            ),

            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('Tổng cộng: ',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.Text('${money.format(_total)} đ',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Text('Ghi chú: Booking qua app', style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 16),
            pw.Align(
              alignment: pw.Alignment.center,
              child: pw.Text('Cảm ơn Quý Khách!',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ),
          ],
        ),
      );

      final bytes = await doc.save();

      try {
        await Printing.layoutPdf(onLayout: (_) async => bytes);
      } catch (e) {
        // Trình duyệt không hỗ trợ in trực tiếp → tải file
        await Printing.sharePdf(bytes: bytes, filename: 'hoa_don_$invoiceNo.pdf');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã tải PDF do trình duyệt không cho in trực tiếp.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể xuất hóa đơn: $e')),
        );
      }
    }
  }

  // ====== UI ======
  @override
  Widget build(BuildContext context) {
    final tabs = catalog.keys.toList();

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: const Color(0xFF0E0E0E),
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          titleSpacing: 20,
          title: Row(
            children: [
              GestureDetector(
                onTap: () => context.go('/'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('3 SÀNH', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 24),
              _NavLink(text: 'Trang chủ', onTap: () => context.go('/')),
              const SizedBox(width: 16),
              _NavLink(text: 'Menu', onTap: () => context.go('/menu')),
              const SizedBox(width: 16),
              _NavLink(text: 'Địa điểm', onTap: () => context.go('/')),
              const SizedBox(width: 16),
              _NavLink(text: 'Tuyển dụng', onTap: () => context.go('/')),
              const SizedBox(width: 16),
              _NavLink(text: 'Đặt món', onTap: () {}), // hiện tại
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/book'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.amber.shade600,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('ĐẶT BÀN', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: () => launchUrl(Uri.parse('tel:0765064777')),
                icon: const Icon(Icons.call, size: 18, color: Colors.white70),
                label: const Text('0765 064 777', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.amber.shade600,
            labelColor: Colors.amber.shade500,
            unselectedLabelColor: Colors.white70,
            tabs: [for (final t in tabs) Tab(text: t.toUpperCase())],
          ),
        ),
        body: TabBarView(
          children: [
            for (final t in tabs)
              _OrderGrid(
                money: money,
                items: catalog[t]!,
                onAdd: (it) => _addToCart(it),
              ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: Stack(
          clipBehavior: Clip.none,
          children: [
            FloatingActionButton(
              backgroundColor: Colors.amber.shade600,
              onPressed: () => _openCheckoutSheet(context),
              child: const Icon(Icons.shopping_cart),
            ),
            if (_cartCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Text(
                    '$_cartCount',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCheckoutSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(height: 4, width: 48, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(999))),
                  const SizedBox(height: 12),
                  const Text('Thanh toán', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _cart.isEmpty
                        ? const Center(child: Text('Giỏ hàng trống', style: TextStyle(color: Colors.white54)))
                        : ListView.builder(
                            controller: controller,
                            itemCount: _cart.length,
                            itemBuilder: (_, i) {
                              final line = _cart[i];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1C1C1C),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(line.item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                          const SizedBox(height: 4),
                                          Text('${money.format(line.item.price)}đ', style: const TextStyle(color: Colors.white70)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        if (line.qty > 1) {
                                          setState(() => _cart[i] = line.copyWith(qty: line.qty - 1));
                                        } else {
                                          setState(() => _cart.removeAt(i));
                                        }
                                        setState(() => _cartCount = _cart.fold(0, (s, e) => s + e.qty));
                                      },
                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.white70),
                                    ),
                                    Text('${line.qty}', style: const TextStyle(color: Colors.white)),
                                    IconButton(
                                      onPressed: () => setState(() => _cart[i] = line.copyWith(qty: line.qty + 1)),
                                      icon: const Icon(Icons.add_circle_outline, color: Colors.white70),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('${money.format(line.qty * line.item.price)}đ',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng cộng', style: TextStyle(color: Colors.white70)),
                      Text('${money.format(_total)} đ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (_cart.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Giỏ hàng trống – hãy thêm món trước khi xuất hóa đơn.')),
                          );
                          return;
                        }
                        await _exportInvoicePdf(context);
                      },
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('Thanh toán & Xuất hóa đơn (PDF)', style: TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade600,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    setState(() {}); // refresh badge
  }
}

// ====== Models / Widgets ======
class _OrderItem {
  final String name;
  final int price;
  final String image;
  const _OrderItem(this.name, this.price, this.image);
}

class _CartLine {
  final _OrderItem item;
  final int qty;
  const _CartLine({required this.item, required this.qty});
  _CartLine copyWith({int? qty}) => _CartLine(item: item, qty: qty ?? this.qty);
}

class _OrderGrid extends StatelessWidget {
  final List<_OrderItem> items;
  final void Function(_OrderItem) onAdd;
  final NumberFormat money;
  const _OrderGrid({required this.items, required this.onAdd, required this.money, super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final cross = w >= 1400 ? 4 : (w >= 1050 ? 3 : (w >= 720 ? 2 : 1));

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cross,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 0.8,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final it = items[i];
        return Card(
          color: const Color(0xFF151515),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.asset(
                        it.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF202020),
                          child: const Center(
                            child: Icon(Icons.image_not_supported, color: Colors.white24, size: 36),
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
              // Tên + giá
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      it.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${money.format(it.price)}đ',
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              // Nút đặt
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () => onAdd(it),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade600,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_shopping_cart, size: 18),
                        SizedBox(width: 8),
                        Text('THÊM VÀO GIỎ', style: TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavLink extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  const _NavLink({required this.text, required this.onTap});

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style: TextStyle(
            color: hover ? Colors.amber.shade400 : Colors.white70,
            fontWeight: hover ? FontWeight.w700 : FontWeight.w500,
          ),
          child: Text(widget.text),
        ),
      ),
    );
  }
}
