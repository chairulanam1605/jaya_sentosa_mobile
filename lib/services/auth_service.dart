import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  // Tempat menyimpan data user yang sedang login secara global di aplikasi
  static UserModel? currentUser; 

  // Fungsi untuk membersihkan seluruh sesi saat pengguna keluar
  static Future<void> logout() async {
    currentUser = null; 
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id'); // Hapus ID dari penyimpanan HP
  }
}