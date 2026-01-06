enum ReservationStatus {
  pending('Chưa đến', 'pending'), //Chưa đến
  confirmed('Sẽ đến', 'confirmed'), // Sẽ đến
  arrived('Đã đến', 'arrived'), // Đã đến
  noShow('Không đến', 'no_show'); // Không đến

  final String displayName;
  final String value;
  const ReservationStatus(this.displayName, this.value);

  /// Color for UI display
  String get colorHex {
    switch (this) {
      case ReservationStatus.pending:
        return '#FFA500'; // Orange
      case ReservationStatus.confirmed:
        return '#2196F3'; // Blue
      case ReservationStatus.arrived:
        return '#4CAF50'; // Green
      case ReservationStatus.noShow:
        return '#F44336'; // Red
    }
  }
}
