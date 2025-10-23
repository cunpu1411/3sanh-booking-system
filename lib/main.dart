import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'firebase_options.dart';
import 'menu_page.dart';
import 'order_page.dart';
import 'booking_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }
  runApp(const ThreeSanhApp());
}

class ThreeSanhApp extends StatelessWidget {
  const ThreeSanhApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomePage()),
        GoRoute(path: '/book', builder: (_, __) => const BookingPage()),
        GoRoute(
          path: '/menu',
          builder: (context, state) {
            final initial =
                int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
            return MenuPage(initialTab: initial);
          },
        ),
        GoRoute(path: '/order', builder: (_, __) => const OrderPage()),
      ],
    );

    return MaterialApp.router(
      title: '3 Sành',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFC107)),
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.transparent,
      ),
      routerConfig: router,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned.fill(
              child:
                  Image.asset('assets/images/bg_3sanh.jpg', fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: ColoredBox(color: Colors.black.withOpacity(0.04)),
            ),
            if (child != null) child,
          ],
        );
      },
    );
  }
}

// =========================== HOMEPAGE ===========================
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final scrollCtrl = ScrollController();
  final menuKey = GlobalKey();
  final locationsKey = GlobalKey();
  final careersKey = GlobalKey();

  Future<void> _scrollTo(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      alignment: 0.1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _callHotline() async =>
      launchUrl(Uri.parse('tel:0765064777'));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _callHotline,
        icon: const Icon(Icons.call),
        label: const Text('Hotline'),
      ),
      body: CustomScrollView(
        controller: scrollCtrl,
        slivers: [
          // NAV
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.black,
            centerTitle: false,
            titleSpacing: 20,
            title: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade600,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('3 SÀNH',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 24),
                _NavLink(text: 'Thực đơn', onTap: () => context.go('/menu')),
                const SizedBox(width: 16),
                _NavLink(
                    text: 'Địa điểm',
                    onTap: () => _scrollTo(locationsKey)),
                const SizedBox(width: 16),
                _NavLink(
                    text: 'Tuyển dụng',
                    onTap: () => _scrollTo(careersKey)),
                const SizedBox(width: 16),
                _NavLink(text: 'Đặt món', onTap: () => context.go('/order')),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go('/book'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.amber.shade600,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('ĐẶT BÀN',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: _callHotline,
                  icon:
                      const Icon(Icons.call, size: 18, color: Colors.white70),
                  label: const Text('0765 064 777',
                      style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),

          // HERO
          const SliverToBoxAdapter(child: _HeroBanner()),

          // MENU teaser
          _Section(
            key: menuKey,
            title: 'Thực đơn',
            subtitle:
                'Món signature, combo nhóm, đồ nhắm – cập nhật theo mùa.',
            child: const _MenuTeaser(),
          ),

          // ======= GỢI Ý MÓN CAROUSEL =======
          _Section(
            title: 'Món "ẨN" chỉ dân chơi biết',
            subtitle: 'Lướt thử vài món bán chạy – bấm để đặt ngay.',
            child: const _DishCarousel(),
          ),

          // ĐỊA ĐIỂM
          _Section(
            key: locationsKey,
            title: 'Địa điểm',
            subtitle: 'Chọn chi nhánh gần bạn nhất.',
            child: _ListLinks(
              items: const [
                _LinkItem(
                  '3 Sành Trần Quốc Toản – Q.3',
                  'https://www.google.com/maps/place/Qu%C3%A1n+nh%E1%BA%ADu+3+S%C3%A0nh/@10.7885482,106.6887519',
                ),
                _LinkItem(
                  '3 Sành Đồng Nai – Q.10',
                  'https://www.google.com/maps/place/1a+%C4%90.%C4%90%E1%BB%93ng+Nai,+Qu%E1%BA%ADn+10',
                ),
              ],
            ),
          ),

          // TUYỂN DỤNG
          _Section(
            key: careersKey,
            title: 'Tuyển dụng',
            subtitle: 'Gia nhập đội ngũ: phục vụ, bếp, pha chế, marketing.',
            child: _ListSimple(
              items: const [
                'Phục vụ Full-time/Part-time',
                'Bếp Line/Prep',
                'Bartender/Pha chế',
                'Marketing Intern',
              ],
            ),
          ),

          const SliverToBoxAdapter(child: _Footer()),
        ],
      ),
    );
  }
}

// ===== HERO =====
class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 7,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/images/hero.jpg', fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black87, Colors.transparent, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SÀNH BIA - SÀNH GU - SÀNH VỊ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.amber.shade400,
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => context.go('/book'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.amber.shade600,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('ĐẶT BÀN',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ====== NAV LINK ======
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

// ====== SECTION WRAPPER ======
class _Section extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _Section({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    t.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(subtitle,
                style: t.bodyLarge?.copyWith(color: Colors.black54)),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

// ===== CAROUSEL MÓN GỢI Ý =====
class _DishCarousel extends StatefulWidget {
  const _DishCarousel({super.key});
  @override
  State<_DishCarousel> createState() => _DishCarouselState();
}

class _DishCarouselState extends State<_DishCarousel> {
  // NOTE: phiên bản package trong dự án của bạn dùng CarouselSliderController
  final _controller = CarouselSliderController();

  final _items = const [
    _DishItem('Khoai mạt nướng sốt 3 Sành', 79000,
        'assets/dishes/khoai_mat_nuong_sot_3_sanh_1.png'),
    _DishItem('Đậu hũ trứng 3 Sành', 99000,
        'assets/dishes/dau_hu_trung_1.png'),
    _DishItem('Tôm xông cay Tiền lửa', 169000,
        'assets/dishes/tom_xong_cay_tien_lua_mien_nam_1.png'),
    _DishItem('Cơm ghẹ phủ trứng', 149000,
        'assets/dishes/com_ghe_phu_trung_1.png'),
    _DishItem('Chân gà sốt Thái', 99000,
        'assets/dishes/chan_ga_sot_thai_1.png'),
    _DishItem('Khoai môn du kích', 119000,
        'assets/dishes/khoai_mon_du_kich_1.png'),
  ];

  int _slidesToShow(double w) {
    if (w >= 1200) return 4;
    if (w >= 900) return 3;
    if (w >= 600) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final show = _slidesToShow(w);
    final viewport = 1 / show;
    final money =
        NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0);

    return Stack(
      alignment: Alignment.center,
      children: [
        CarouselSlider.builder(
          carouselController: _controller,
          itemCount: _items.length,
          options: CarouselOptions(
            viewportFraction: viewport,
            enlargeCenterPage: false,
            enableInfiniteScroll: true,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 600),
            autoPlayCurve: Curves.easeOutCubic,
            pauseAutoPlayOnTouch: true,
            padEnds: true,
            height: 360,
          ),
          itemBuilder: (context, i, _) {
            final d = _items[i];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: _DishCard(
                title: d.name,
                priceText: '${money.format(d.price)} đ',
                image: d.image,
                onTap: () => context.go('/order'),
              ),
            );
          },
        ),
        Positioned(
          left: 0,
          child: _CircleArrow(
            icon: Icons.chevron_left,
            onTap: () => _controller.previousPage(),
          ),
        ),
        Positioned(
          right: 0,
          child: _CircleArrow(
            icon: Icons.chevron_right,
            onTap: () => _controller.nextPage(),
          ),
        ),
      ],
    );
  }
}

// ===== MŨI TÊN CAROUSEL =====
class _CircleArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleArrow({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.chevron_right, color: Colors.white),
        ),
      ),
    );
  }
}

class _DishItem {
  final String name;
  final int price;
  final String image;
  const _DishItem(this.name, this.price, this.image);
}

class _DishCard extends StatelessWidget {
  final String title;
  final String priceText;
  final String image;
  final VoidCallback onTap;
  const _DishCard({
    required this.title,
    required this.priceText,
    required this.image,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child:
                  Image.asset(image, fit: BoxFit.cover, width: double.infinity),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(priceText,
                      style: const TextStyle(
                          fontSize: 15, color: Colors.brown)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== MENU TEASER (MIỀN) =====
class _MenuTeaser extends StatelessWidget {
  const _MenuTeaser({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const [
      _RegionItem('Miền Bắc', 'assets/menu/mien_bac.jpg', 0),
      _RegionItem('Miền Trung', 'assets/menu/mien_trung.jpg', 1),
      _RegionItem('Miền Nam', 'assets/menu/mien_nam.jpg', 2),
    ];

    return LayoutBuilder(
      builder: (_, c) {
        final cross = c.maxWidth >= 1000 ? 3 : (c.maxWidth >= 640 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 16 / 9,
          ),
          itemBuilder: (_, i) => _RegionCard(item: items[i]),
        );
      },
    );
  }
}

class _RegionItem {
  final String title;
  final String image;
  final int tab;
  const _RegionItem(this.title, this.image, this.tab);
}

class _RegionCard extends StatelessWidget {
  final _RegionItem item;
  const _RegionCard({super.key, required this.item});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/menu?tab=${item.tab}'),
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(item.image, fit: BoxFit.cover),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black54],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: Text(
                item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== LIST SIMPLE =====
class _ListSimple extends StatelessWidget {
  final List<String> items;
  const _ListSimple({required this.items});

  @override
  Widget build(BuildContext context) => Column(
        children: items
            .map(
              (e) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(e,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right),
              ),
            )
            .toList(),
      );
}

// ===== LINKS =====
class _LinkItem {
  final String title;
  final String url;
  const _LinkItem(this.title, this.url);
}

class _ListLinks extends StatelessWidget {
  final List<_LinkItem> items;
  const _ListLinks({super.key, required this.items});

  Future<void> _open(String url) async => launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );

  @override
  Widget build(BuildContext context) => Column(
        children: items
            .map(
              (e) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(e.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(e.url),
              ),
            )
            .toList(),
      );
}

// ===== FOOTER =====
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
      child: const Center(
        child: Text(
          '© 2025 3 Sành • All rights reserved',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
