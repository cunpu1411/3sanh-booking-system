import 'package:cloud_firestore/cloud_firestore.dart';

class PaginatedResult<T> {
  final List<T> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
  final int totalCount;
  PaginatedResult({
    required this.items,
    this.lastDocument,
    required this.hasMore,
    this.totalCount = 0,
  });
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
}
