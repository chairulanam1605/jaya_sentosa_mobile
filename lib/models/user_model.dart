class UserModel {
  final String id;
  final String fullName;
  final String customerNumber;
  final String email;
  final String phone;
  final String packageName;
  final int packageSpeed; // Mbps
  final DateTime activeUntil;
  final DateTime since; // pelanggan sejak

  UserModel({
    required this.id,
    required this.fullName,
    required this.customerNumber,
    required this.email,
    required this.phone,
    required this.packageName,
    required this.packageSpeed,
    required this.activeUntil,
    required this.since,
  });

  // Data dummy untuk 1 pelanggan (Bapak Suharto)
  static final UserModel dummyUser = UserModel(
    id: '1',
    fullName: 'Suharto Wijoyo',
    customerNumber: 'JSG-12345678',
    email: 'suharto.w@email.com',
    phone: '0812-3456-7890',
    packageName: 'Paket Keluarga 50 Mbps',
    packageSpeed: 50,
    activeUntil: DateTime(2025, 12, 31),
    since: DateTime(2022, 1, 1),
  );

  // Untuk autentikasi (dummy, hanya satu akun)
  static UserModel? authenticate(String customerNumber, String password) {
    // Demo: nomor pelanggan JSG-12345678, password 123456
    if (customerNumber == 'JSG-12345678' && password == '123456') {
      return dummyUser;
    }
    return null;
  }
}