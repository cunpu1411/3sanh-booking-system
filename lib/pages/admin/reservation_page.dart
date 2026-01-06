import 'package:client_web/bindings/reservations_binding.dart';
import 'package:client_web/views/reservations_section.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReservationPage extends StatefulWidget {
  const ReservationPage({super.key});

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeFmt = DateFormat('HH:mm');

    return ReservationsSection(isDark: isDark, timeFmt: timeFmt);
  }
}
