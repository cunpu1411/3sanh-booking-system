enum ReservationSource {
  phone('Điện thoại', 'phone'),
  website('Website', 'website'),
  walkin('Walk-in', 'walkin'), // Vãng lai
  other('Khác', 'other');

  final String displayName;
  final String value;
  const ReservationSource(this.displayName, this.value);
  String get icon {
    switch (this) {
      case ReservationSource.phone:
        return 'phone';
      case ReservationSource.website:
        return 'web';
      case ReservationSource.walkin:
        return 'directions_walk_outline';
      case ReservationSource.other:
        return 'difference_outlined';
    }
  }
}
