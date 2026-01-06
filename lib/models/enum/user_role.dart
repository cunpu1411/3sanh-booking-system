enum UserRole {
  admin('admin', 'Quản lý'),
  staff('staff', 'Nhân viên');

  final String value;
  final String displayName;
  const UserRole(this.value, this.displayName);
  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.staff,
    );
  }
}
