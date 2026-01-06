import 'package:flutter/material.dart';

class SnackbarHelper {
  // ✅ Dùng BuildContext từ GoRouter
  static void showSuccess(BuildContext context, String message) {
    // Check mounted
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(milliseconds: 500),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            top: 60,
            right: 20,
            left: MediaQuery.of(context).size.width * 0.6,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
  }

  static void showError(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Color(0xFFD32F2F),
          duration: Duration(milliseconds: 5000),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            top: 20,
            right: 20,
            left: MediaQuery.of(context).size.width * 0.6,
            bottom: MediaQuery.of(context).size.height - 100,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 6,
          action: SnackBarAction(
            label: 'Đóng',
            textColor: Colors.white70,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
  }

  static void showInfo(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            top: 60,
            right: 20,
            left: MediaQuery.of(context).size.width * 0.6,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
  }
}
