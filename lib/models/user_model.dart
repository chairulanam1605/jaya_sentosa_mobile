class UserModel {
  final int id;
  final String fullName;
  final String packageName;
  final String phone;
  final String email;
  final String customerNumber;
  final DateTime since;
  final DateTime masaAktif;
  final String? fotoProfile;

  UserModel({
    required this.id,
    required this.fullName,
    required this.packageName,
    required this.phone,
    required this.email,
    required this.customerNumber,
    required this.since,
    required this.masaAktif,
    required this.fotoProfile,
  });

  // Fungsi untuk mengubah data JSON dari Laravel menjadi objek model Flutter
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // MEMBUKA "KARDUS" BUNGKUSAN DARI LARAVEL
    // Karena temanmu menggunakan with('pelanggan.paket')
    final pelangganData = json['pelanggan'] ?? {};
    final paketData = pelangganData['paket'] ?? {};

    return UserModel(
      id: json['pelanggan_id'] ?? json['id'] ?? 0, 
      fullName: json['name'] ?? 'Pelanggan JSG', 
      
      // Ambil nama paket dari tabel relasi
      // (Kita gunakan beberapa kemungkinan nama kolom: nama_paket atau nama)
      packageName: paketData['nama'] ?? paketData['nama_paket'] ?? '20 Mbps', 
      
      // Ambil nomor telepon dari dalam tabel pelanggan
      phone: pelangganData['no_telepon'] ?? '-', 
      email: json['email'] ?? 'Belum ada email', 
      customerNumber: json['nik'] ?? '-', 
      since: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
          
      // KUNCI UTAMA: Ambil masa_aktif dari dalam tabel pelanggan!
      masaAktif: pelangganData['masa_aktif'] != null 
          ? DateTime.parse(pelangganData['masa_aktif'].toString()) 
          : DateTime.now().add(const Duration(days: 30)),
          
      fotoProfile: json['foto_profile'],
    );
  }
}