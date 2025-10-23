// lib/menu_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class MenuPage extends StatelessWidget {
  final int initialTab;
  const MenuPage({super.key, this.initialTab = 0});

  int get _safeInitial => initialTab.clamp(0, 5);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      initialIndex: _safeInitial,
      child: Scaffold(
        // NAV BAR giống trang chủ + logo 3 SÀNH click về home
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          titleSpacing: 20,
          title: Row(
            children: [
              GestureDetector(
                onTap: () => context.go('/'), // back Home
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade600,
                    borderRadius: BorderRadius.circular(6),
                  ),
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
              _NavLink(text: 'Đặt món', onTap: () => context.go('/order')),
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
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Miền Bắc'),
              Tab(text: 'Miền Trung'),
              Tab(text: 'Miền Nam'),
              Tab(text: 'Đặc sản'),
              Tab(text: 'Món chính & Lẩu'),
              Tab(text: 'Thức uống'),
            ],
          ),
        ),

        // Nội dung trang thực đơn
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: false,
              pinned: false,
              backgroundColor: Colors.transparent,
              expandedHeight: 220,
              flexibleSpace: const FlexibleSpaceBar(
                background: _MenuHeroImage('assets/menu/cover.jpg'),
              ),
            ),
            SliverFillRemaining(
              child: const TabBarView(
                children: [
                  _MenuSection(images: ['assets/menu/mien_bac.jpg']),
                  _MenuSection(images: ['assets/menu/mien_trung.jpg']),
                  _MenuSection(images: ['assets/menu/mien_nam.jpg']),
                  _MenuSection(images: [
                    'assets/menu/dac_san_nha_ngheo.jpg',
                    'assets/menu/mon_an_dan_choi.jpg',
                    'assets/menu/kho_mo_mam_nuong.jpg',
                    'assets/menu/haisannuong.jpg',
                  ]),
                  _MenuSection(images: ['assets/menu/mon_chinh.jpg']),
                  _MenuSection(images: ['assets/menu/thuc_uong.jpg']),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Các widget phụ (riêng cho trang menu) ----
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
      onExit:  (_) => setState(() => hover = false),
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

class _MenuHeroImage extends StatelessWidget {
  final String path;
  const _MenuHeroImage(this.path);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(path, fit: BoxFit.cover),
        Container(color: Colors.black.withOpacity(0.15)),
        const Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Sổ Mua Lương Thực 3 Sành',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22,
                shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
              ),
            ),
          ),
        )
      ],
    );
  }
}

class _MenuSection extends StatelessWidget {
  final List<String> images;
  const _MenuSection({required this.images});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth;
        final cross = w >= 1100 ? 3 : (w >= 720 ? 2 : 1);
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.7,
          ),
          itemCount: images.length,
          itemBuilder: (_, i) => _MenuCard(imagePath: images[i]),
        );
      },
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String imagePath;
  const _MenuCard({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openZoom(context, imagePath),
      child: Card(
        elevation: 3,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Hero(
          tag: imagePath,
          child: Image.asset(imagePath, fit: BoxFit.cover),
        ),
      ),
    );
  }

  void _openZoom(BuildContext context, String path) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(8),
        backgroundColor: Colors.black,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Hero(tag: path, child: Image.asset(path, fit: BoxFit.contain)),
          ),
        ),
      ),
    );
  }
}
