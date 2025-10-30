import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  String _activeMenu = 'dashboard';
  String _search = '';
  bool _showOnlyNotArrived = false;
  final dateFmt = DateFormat('yyyy-MM-dd');
  final timeFmt = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F7);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        children: [
          _Sidebar(
            active: _activeMenu,
            onTap: (m) => setState(() => _activeMenu = m),
            isDark: isDark,
          ),
          Expanded(
            child: Column(
              children: [
                _Header(isDark: isDark, title: _activeMenu),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: switch (_activeMenu) {
                      'dashboard' => _DashboardSection(isDark: isDark, dateFmt: dateFmt),
                      'reservations' => _ReservationsSection(
                          isDark: isDark,
                          timeFmt: timeFmt,
                          search: _search,
                          showOnlyNotArrived: _showOnlyNotArrived,
                          onSearch: (v) => setState(() => _search = v),
                          onFilter: (v) => setState(() => _showOnlyNotArrived = v)),
                      _ => Center(
                          child: Text(
                            'Chức năng "${_activeMenu.toUpperCase()}" đang phát triển...',
                            style: TextStyle(
                                color: textColor.withOpacity(0.8),
                                fontSize: 18),
                          ),
                        ),
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* =================== SIDEBAR =================== */
class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.active, required this.onTap, required this.isDark});
  final String active;
  final Function(String) onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('dashboard', Icons.dashboard, 'Dashboard'),
      ('reservations', Icons.event_note, 'Reservations'),
      ('analytics', Icons.analytics_outlined, 'Analytics'),
      ('settings', Icons.settings_outlined, 'Settings'),
    ];

    return Container(
      width: 220,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.black,
      child: Column(
        children: [
          const SizedBox(height: 30),
          const Text('3 SÀNH',
              style: TextStyle(
                  color: Colors.amber,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5)),
          const SizedBox(height: 40),
          for (final item in items)
            _SidebarItem(
              icon: item.$2,
              label: item.$3,
              selected: active == item.$1,
              onTap: () => onTap(item.$1),
              isDark: isDark,
            ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text('© 2025 3 Sành',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
          )
        ],
      ),
    );
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
        color:
            selected ? Colors.amber.shade700.withOpacity(0.25) : Colors.transparent,
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(label,
                style:
                    TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/* =================== HEADER =================== */
class _Header extends StatelessWidget {
  const _Header({required this.isDark, required this.title});
  final bool isDark;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: isDark ? const Color(0xFF202020) : Colors.black,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        title == 'dashboard' ? 'Admin Dashboard' : title.capitalize(),
        style: const TextStyle(
            color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }
}

extension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

/* =================== DASHBOARD SECTION =================== */
class _DashboardSection extends StatelessWidget {
  const _DashboardSection({required this.isDark, required this.dateFmt});
  final bool isDark;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    final bgCard = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFF8E1);
    final daysRef = FirebaseFirestore.instance
        .collection('metrics')
        .doc('daily')
        .collection('days')
        .orderBy('date', descending: true)
        .limit(14);
    final globalRef =
        FirebaseFirestore.instance.collection('metrics').doc('global');

    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
            ],
          ),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: daysRef.snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data!.docs;
              int today = 0;
              int last7 = 0;
              final nowId = dateFmt.format(DateTime.now());
              for (final d in docs) {
                final v = (d.data()['views'] ?? 0) as int;
                final day = (d.data()['date'] ?? d.id) as String;
                if (day == nowId) today += v;
              }
              for (final d in docs.take(7)) {
                last7 += (d.data()['views'] ?? 0) as int;
              }

              return Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  _StatTile(title: 'Hôm nay', value: today.toString()),
                  _StatTile(title: '7 ngày gần nhất', value: last7.toString()),
                  _BigTotalStream(globalRef: globalRef),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        width: 200,
        height: 110,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white70)),
            const Spacer(),
            Text(value,
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ],
        ),
      );
}

class _BigTotalStream extends StatelessWidget {
  const _BigTotalStream({required this.globalRef});
  final DocumentReference<Map<String, dynamic>> globalRef;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: globalRef.snapshots(),
      builder: (context, s) {
        if (!s.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final total = (s.data!.data()?['totalViews'] ?? 0) as int;
        return _BigTotal(total: total);
      },
    );
  }
}

class _BigTotal extends StatelessWidget {
  const _BigTotal({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) => Container(
        width: 240,
        height: 110,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1F2B), Color(0xFF2B3650)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Tổng lượt vào',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const Spacer(),
          Text(total.toString(),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 34)),
        ]),
      );
}

/* =================== RESERVATIONS SECTION =================== */
class _ReservationsSection extends StatelessWidget {
  const _ReservationsSection({
    required this.isDark,
    required this.timeFmt,
    required this.search,
    required this.showOnlyNotArrived,
    required this.onSearch,
    required this.onFilter,
  });

  final bool isDark;
  final DateFormat timeFmt;
  final String search;
  final bool showOnlyNotArrived;
  final Function(String) onSearch;
  final Function(bool) onFilter;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Text('Reservations',
                style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const Spacer(),
            SizedBox(
              width: 280,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Tìm tên / SĐT / ghi chú...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  isDense: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.amber.shade600),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: onSearch,
              ),
            ),
            const SizedBox(width: 12),
            FilterChip(
              label: const Text('Chưa đến'),
              selected: showOnlyNotArrived,
              selectedColor: Colors.amber.shade600,
              checkmarkColor: Colors.white,
              onSelected: onFilter,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
            child: _ReservationsTable(
          search: search,
          onlyNotArrived: showOnlyNotArrived,
          timeFmt: timeFmt,
        )),
      ],
    );
  }
}

/* =================== TABLE =================== */
class _ReservationsTable extends StatelessWidget {
  const _ReservationsTable({
    required this.search,
    required this.onlyNotArrived,
    required this.timeFmt,
  });

  final String search;
  final bool onlyNotArrived;
  final DateFormat timeFmt;

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance.collection('reservations');
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const LinearProgressIndicator();
        final docs = snap.data!.docs;
        final filtered = docs.where((d) {
          final data = d.data();
          final name = (data['name'] ?? '').toString().toLowerCase();
          final phone = (data['phone'] ?? '').toString();
          final note = (data['note'] ?? '').toString();
          final arrived = (data['arrived'] ?? false) as bool;
          final s = search.toLowerCase();
          if (onlyNotArrived && arrived) return false;
          return s.isEmpty ||
              name.contains(s) ||
              phone.contains(s) ||
              note.contains(s);
        }).toList();

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor:
                  WidgetStateProperty.all(Colors.amber.shade100),
              headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black87),
              columns: const [
                DataColumn(label: Text('Thời gian')),
                DataColumn(label: Text('Tên')),
                DataColumn(label: Text('Điện thoại')),
                DataColumn(label: Text('Số khách')),
                DataColumn(label: Text('Ghi chú')),
                DataColumn(label: Text('Trạng thái')),
                DataColumn(label: Text('Hành động')),
              ],
              rows: [for (final d in filtered) _buildRow(context, d)],
            ),
          ),
        );
      },
    );
  }

  DataRow _buildRow(BuildContext context,
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final name = data['name'] ?? '';
    final phone = data['phone'] ?? '';
    final people = data['people'] ?? '';
    final note = data['note'] ?? '';
    final arrived = data['arrived'] ?? false;
    final created = (data['createdAt'] as Timestamp?)?.toDate();

    return DataRow(cells: [
      DataCell(Text(created != null
          ? DateFormat('dd/MM HH:mm').format(created)
          : '—')),
      DataCell(Text(name.toString())),
      DataCell(Text(phone.toString())),
      DataCell(Text(people.toString())),
      DataCell(Text(note.toString().isEmpty ? '—' : note.toString())),
      DataCell(Text(arrived ? 'ĐÃ ĐẾN' : 'CHƯA ĐẾN',
          style: TextStyle(
              color: arrived ? Colors.green : Colors.orange,
              fontWeight: FontWeight.bold))),
      DataCell(Row(
        children: [
          IconButton(
            icon: Icon(Icons.check,
                color: arrived ? Colors.grey : Colors.amber.shade700),
            onPressed: arrived
                ? null
                : () async => await doc.reference.update({'arrived': true}),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async => await doc.reference.delete(),
          ),
        ],
      )),
    ]);
  }
}
