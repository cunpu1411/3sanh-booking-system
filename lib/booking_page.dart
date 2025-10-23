// lib/booking_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class BookingPage extends StatelessWidget {
  const BookingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đặt bàn')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: ReservationForm(),
          ),
        ),
      ),
    );
  }
}

class ReservationForm extends StatefulWidget {
  const ReservationForm({super.key});
  @override
  State<ReservationForm> createState() => _ReservationFormState();
}

class _ReservationFormState extends State<ReservationForm> {
  final _formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final phone = TextEditingController();
  final note = TextEditingController();
  bool _submitting = false;
  DateTime? _date;
  TimeOfDay? _time;
  int _party = 2;

  @override
  void dispose() { name.dispose(); phone.dispose(); note.dispose(); super.dispose(); }
  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
      initialDate: _date ?? DateTime(now.year, now.month, now.day),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _time = picked);
  }

  DateTime _combine(DateTime d, TimeOfDay t) => DateTime(d.year, d.month, d.day, t.hour, t.minute);
  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null) return _toast('Vui lòng chọn ngày.');
    if (_time == null) return _toast('Vui lòng chọn giờ.');

    setState(() => _submitting = true);
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
      final dt = _combine(_date!, _time!);
      await FirebaseFirestore.instance.collection('reservations').add({
        'name': name.text.trim(),
        'phone': phone.text.trim(),
        'date': DateFormat('yyyy-MM-dd').format(_date!),
        'time': DateFormat('HH:mm').format(dt),
        'partySize': _party,
        'note': note.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'web',
        'status': 'pending',
        'tableId': null,
      });

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Thank you!'),
          content: const Text('Your reservation has been sent. We will contact you soon.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
      _formKey.currentState!.reset();
      name.clear(); phone.clear(); note.clear();
      setState(() { _date = null; _time = null; _party = 2; });
    } catch (_) {
      _toast('Gửi thất bại, thử lại nhé.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 16, runSpacing: 16, children: [
          SizedBox(width: 360, child: TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Full name'), validator: _req)),
          SizedBox(width: 240, child: TextFormField(controller: phone, decoration: const InputDecoration(labelText: 'Phone'), validator: _req, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]'))])),
          FilledButton.tonal(onPressed: _pickDate, child: Text(_date == null ? 'Pick date' : DateFormat('dd/MM/yyyy').format(_date!))),
          FilledButton.tonal(onPressed: _pickTime, child: Text(_time == null ? 'Pick time' : _time!.format(context))),
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('Party size: '),
            DropdownButton<int>(
              value: _party,
              items: [for (final n in List.generate(12, (i) => i + 1)) DropdownMenuItem(value: n, child: Text('$n'))],
              onChanged: (v) => setState(() => _party = v ?? 2),
            ),
          ]),
        ]),
        const SizedBox(height: 12),
        SizedBox(width: 620, child: TextFormField(controller: note, decoration: const InputDecoration(labelText: 'Note (optional)'), maxLines: 2)),
        const SizedBox(height: 16),
        ElevatedButton.icon(onPressed: _submitting ? null : _submit, icon: const Icon(Icons.check), label: Text(_submitting ? 'Sending...' : 'Submit Reservation')),
      ]),
    );
  }
}
