import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart' as pdf;


class OrderPage extends StatefulWidget {
  const OrderPage({super.key});
  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final Map<String, _CartItem> _cart = {};
  int get _cartCount => _cart.values.fold(0, (s, e) => s + e.qty);
  final _currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  // ===== Cart =====
  void _addToCart(_OrderItem item) {
    setState(() {
      if (_cart.containsKey(item.id)) {
        _cart[item.id] = _cart[item.id]!.copyWith(qty: _cart[item.id]!.qty + 1);
      } else {
        _cart[item.id] = _CartItem(itemId: item.id, name: item.name, price: item.price, qty: 1);
      }
    });
  }
  void _inc(String id) { if (_cart.containsKey(id)) setState(() => _cart[id] = _cart[id]!.copyWith(qty: _cart[id]!.qty + 1)); }
  void _dec(String id) {
    if (!_cart.containsKey(id)) return;
    final it = _cart[id]!;
    final next = max(0, it.qty - 1);
    setState(() => next == 0 ? _cart.remove(id) : _cart[id] = it.copyWith(qty: next));
  }

  double get _subtotal => _cart.values.fold(0.0, (s, e) => s + e.price * e.qty);
  double get _tax => 0.0;       // cập nhật nếu có VAT
  double get _discount => 0.0;  // nếu có mã giảm
  double get _total => _subtotal + _tax - _discount;

  // ===== Create order + PDF =====
  Future<void> _placeOrderAndInvoice() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Giỏ hàng đang trống!')));
      return;
    }
    try {
      final now = DateTime.now();
      final items = _cart.values.map((e) => {
        'itemId': e.itemId, 'name': e.name, 'price': e.price, 'qty': e.qty, 'lineTotal': e.price * e.qty,
      }).toList();

      final ref = await FirebaseFirestore.instance.collection('orders').add({
        'createdAt': FieldValue.serverTimestamp(),
        'createdAtLocal': now.toIso8601String(),
        'status': 'NEW',
        'items': items,
        'subtotal': _subtotal, 'tax': _tax, 'discount': _discount, 'total': _total,
        'customer': {'channel': 'WEB'},
      });

      final invoiceNo = ref.id.substring(0, 8).toUpperCase();
      final pdf = await _buildInvoicePdf(
        invoiceNo: invoiceNo, createdAt: now, items: _cart.values.toList(),
        subtotal: _subtotal, tax: _tax, discount: _discount, total: _total,
      );

      await Printing.layoutPdf(onLayout: (_) async => pdf.save());
      setState(_cart.clear);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã tạo đơn #$invoiceNo & mở hoá đơn PDF')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<pw.Document> _buildInvoicePdf({
    required String invoiceNo, required DateTime createdAt, required List<_CartItem> items,
    required double subtotal, required double tax, required double discount, required double total,
  }) async {
    final doc = pw.Document();
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(createdAt);

    doc.addPage(pw.Page(
      pageFormat: pdf.PdfPageFormat.a4,
      build: (_) => pw.Padding(
        padding: const pw.EdgeInsets.all(24),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('3 SÀNH — HÓA ĐƠN BÁN HÀNG', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Mã hóa đơn: #$invoiceNo'), pw.Text('Thời gian: $dateStr'),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headers: const ['Món','SL','Đơn giá','Thành tiền'],
            data: items.map((e) => [e.name, e.qty.toString(), fmt.format(e.price), fmt.format(e.price*e.qty)]).toList(),
            cellAlignment: pw.Alignment.centerLeft,
          ),
          pw.SizedBox(height: 12),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
            pw.Container(width: 260, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
              _line('Tạm tính', fmt.format(subtotal)),
              _line('Thuế', fmt.format(tax)),
              _line('Giảm giá', fmt.format(discount)),
              pw.Divider(),
              _lineBold('TỔNG CỘNG', fmt.format(total)),
            ])),
          ]),
          pw.SizedBox(height: 16),
          pw.Text('Cảm ơn quý khách đã ủng hộ 3 Sành!', style: const pw.TextStyle(fontSize: 12)),
        ]),
      ),
    ));
    return doc;
  }

  static pw.Widget _line(String l, String r) => pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(l), pw.Text(r)],
  );
  static pw.Widget _lineBold(String l, String r) => pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [pw.Text(l, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
               pw.Text(r, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))],
  );

  void _openCartSheet() {
    showModalBottomSheet(
      context: context, backgroundColor: const Color(0xFF121212), isScrollControlled: true,
      builder: (_) {
        final items = _cart.values.toList();
        final money = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
        return Padding(
          padding: const EdgeInsets.fromLTRB(16,16,16,24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Giỏ hàng', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Padding(padding: EdgeInsets.all(24), child: Text('Chưa có món', style: TextStyle(color: Colors.white70)))
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true, itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (_, i) {
                    final e = items[i];
                    return ListTile(
                      title: Text(e.name, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(money.format(e.price), style: const TextStyle(color: Colors.white70)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(onPressed: () { _dec(e.itemId); setState((){}); },
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.white70)),
                        Text('${e.qty}', style: const TextStyle(color: Colors.white)),
                        IconButton(onPressed: () { _inc(e.itemId); setState((){}); },
                          icon: const Icon(Icons.add_circle_outline, color: Colors.white70)),
                      ]),
                    );
                  },
                ),
              ),
            const Divider(color: Colors.white10),
            _kv('Tạm tính', money.format(_subtotal)),
            _kv('Thuế', money.format(_tax)),
            _kv('Giảm giá', money.format(_discount)),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('TỔNG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(money.format(_total), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity, height: 46,
              child: ElevatedButton.icon(
                onPressed: _cart.isEmpty ? null : () { Navigator.of(context).pop(); _placeOrderAndInvoice(); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade600, foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.receipt_long),
                label: const Text('ĐẶT & XUẤT HOÁ ĐƠN', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(k, style: const TextStyle(color: Colors.white70)),
      Text(v, style: const TextStyle(color: Colors.white)),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('menuItems')
          .where('isAvailable', isEqualTo: true)
          .orderBy('category').orderBy('name')
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Scaffold(
            backgroundColor: Color(0xFF0E0E0E),
            body: Center(child: Text('Lỗi tải menu', style: TextStyle(color: Colors.white))),
          );
        }
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF0E0E0E),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final byCat = <String, List<_OrderItem>>{};
        for (final d in snap.data!.docs) {
          final data = d.data() as Map<String, dynamic>? ?? {};
          final id = d.id;
          final cat = (data['category'] ?? 'Khác') as String;
          final name = (data['name'] ?? '') as String;
          final price = (data['price'] ?? 0).toDouble();
          final imageUrl = (data['imageUrl'] ?? '') as String;
          byCat.putIfAbsent(cat, () => []).add(_OrderItem(id: id, name: name, price: price, image: imageUrl));
        }
        final tabs = byCat.keys.toList();
        if (tabs.isEmpty) {
          return const Scaffold(
            backgroundColor: Color(0xFF0E0E0E),
            body: Center(child: Text('Chưa có món trong menuItems.', style: TextStyle(color: Colors.white70))),
          );
        }

        return DefaultTabController(
          length: tabs.length,
          child: Scaffold(
            backgroundColor: const Color(0xFF0E0E0E),
            appBar: AppBar(
              backgroundColor: Colors.black, elevation: 0, titleSpacing: 20,
              title: Row(children: [
                GestureDetector(
                  onTap: () => context.go('/'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.amber.shade600, borderRadius: BorderRadius.circular(6)),
                    child: const Text('3 SÀNH', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 24),
                _NavLink(text: 'Thực đơn', onTap: () => context.go('/menu')),
                const SizedBox(width: 16),
                _NavLink(text: 'Địa điểm', onTap: () => context.go('/')),
                const SizedBox(width: 16),
                _NavLink(text: 'Tuyển dụng', onTap: () => context.go('/')),
                const SizedBox(width: 16),
                _NavLink(text: 'Đặt món', onTap: () {}),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go('/book'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black, backgroundColor: Colors.amber.shade600,
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
              ]),
              bottom: TabBar(
                isScrollable: true, indicatorColor: Colors.amber.shade600,
                labelColor: Colors.amber.shade500, unselectedLabelColor: Colors.white70,
                tabs: [for (final t in tabs) Tab(text: t.toUpperCase())],
              ),
            ),
            body: TabBarView(
              children: [for (final t in tabs) _OrderGrid(items: byCat[t]!, onAdd: _addToCart)],
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            floatingActionButton: Stack(clipBehavior: Clip.none, children: [
              FloatingActionButton(
                backgroundColor: Colors.amber.shade600, onPressed: _openCartSheet,
                child: const Icon(Icons.shopping_cart),
              ),
              if (_cartCount > 0)
                Positioned(
                  right: -2, top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: const BoxDecoration(color: Colors.red, borderRadius: BorderRadius.all(Radius.circular(12))),
                    child: Text('$_cartCount', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
            ]),
          ),
        );
      },
    );
  }
}

// ====== Models & UI ======
class _OrderItem { final String id, name, image; final double price;
  const _OrderItem({required this.id, required this.name, required this.price, required this.image}); }
class _CartItem { final String itemId, name; final double price; final int qty;
  const _CartItem({required this.itemId, required this.name, required this.price, required this.qty});
  _CartItem copyWith({int? qty}) => _CartItem(itemId: itemId, name: name, price: price, qty: qty ?? this.qty); }

class _OrderGrid extends StatelessWidget {
  final List<_OrderItem> items; final void Function(_OrderItem item) onAdd;
  const _OrderGrid({required this.items, required this.onAdd, super.key});

  @override Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final cross = w >= 1400 ? 4 : (w >= 1050 ? 3 : (w >= 720 ? 2 : 1));
    final money = NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0);

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cross, crossAxisSpacing: 20, mainAxisSpacing: 20, childAspectRatio: 0.8),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final it = items[i]; final isAsset = it.image.startsWith('assets/');
        return Card(
          color: const Color(0xFF151515), elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), clipBehavior: Clip.antiAlias,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: Stack(fit: StackFit.expand, children: [
              isAsset ? Image.asset(it.image, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade900,
                          child: const Icon(Icons.image_not_supported, color: Colors.white30, size: 48),))
                      : Image.network(it.image, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade900,
                          child: const Icon(Icons.image_not_supported, color: Colors.white30, size: 48),)),
              Align(alignment: Alignment.centerLeft, child: Container(
                width: 140, height: double.infinity,
                decoration: BoxDecoration(gradient: LinearGradient(
                  colors: [Colors.amber.shade600.withOpacity(.9), Colors.amber.shade600.withOpacity(.0)],
                  begin: Alignment.centerLeft, end: Alignment.centerRight,
                )),
              )),
            ])),
            Padding(padding: const EdgeInsets.fromLTRB(14,12,14,0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(it.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('${money.format(it.price)}đ', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
              ]),
            ),
            Padding(padding: const EdgeInsets.fromLTRB(14,0,14,14),
              child: SizedBox(height: 40, child: ElevatedButton(
                onPressed: () => onAdd(it),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade600, foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('ĐẶT MÓN', style: TextStyle(fontWeight: FontWeight.w800)),
              )),
            ),
          ]),
        );
      },
    );
  }
}

class _NavLink extends StatefulWidget { final String text; final VoidCallback onTap;
  const _NavLink({required this.text, required this.onTap}); @override State<_NavLink> createState() => _NavLinkState(); }
class _NavLinkState extends State<_NavLink> {
  bool hover = false; @override Widget build(BuildContext context) {
    return MouseRegion(onEnter: (_) => setState(() => hover = true), onExit: (_) => setState(() => hover = false),
      child: GestureDetector(onTap: widget.onTap, child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 150),
        style: TextStyle(color: hover ? Colors.amber.shade400 : Colors.white70,
                         fontWeight: hover ? FontWeight.w700 : FontWeight.w500),
        child: Text(widget.text),
      )),
    );
  }
}
