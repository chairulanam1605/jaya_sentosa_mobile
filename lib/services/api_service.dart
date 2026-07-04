import 'dart:io'; 
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invoice_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = "https://adminjsg.com/api"; 

  // Ambil Tagihan Belum Dibayar
  static Future<List<InvoiceModel>> fetchUnpaidInvoices(String pelangganId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tagihan/unpaid/$pelangganId'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> dataList = jsonResponse['data'];

        return dataList.map((data) => InvoiceModel.fromJson(data)).toList();
      } else {
        throw Exception('Gagal memuat tagihan');
      }
    } catch (e) {
      throw Exception('Error koneksi: $e');
    }
  }

  // Ambil Riwayat Pembayaran (Lunas)
  static Future<List<InvoiceModel>> fetchPaidInvoices(String pelangganId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tagihan/paid/$pelangganId'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> dataList = jsonResponse['data'];

        return dataList.map((data) => InvoiceModel.fromJson(data)).toList();
      } else {
        throw Exception('Gagal memuat riwayat');
      }
    } catch (e) {
      throw Exception('Error koneksi: $e');
    }
  }

  // Proses Login dan Sinkronisasi Data
  static Future<bool> login(String nik, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'), 
        headers: {
          'Accept': 'application/json',
        },
        body: {
          'nik': nik,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final userData = jsonResponse['data'];
        
        // KUNCI PERBAIKAN: Tangkap pelanggan_id dari server, BUKAN id dari tabel users
        final String userId = userData['pelanggan_id'].toString();

        // Simpan ID yang benar ke penyimpanan lokal HP (SharedPreferences)
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', userId);

        // Masukkan data ke AuthService agar halaman profil bisa langsung menampilkan data
        AuthService.currentUser = UserModel.fromJson(userData);

        return true;
      } else {
        return false;
      }
    } catch (e) {
      throw Exception('Error koneksi: $e');
    }
  }

  // FUNGSI UNTUK UPDATE PROFIL KE DATABASE
  static Future<bool> updateProfile(String nik, String nama, String email, String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update-profile'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nik': nik,
          'nama': nama,
          'email': email,
          'no_telepon': phone,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['status'] == 'success';
      } else {
        throw Exception('Gagal menyimpan perubahan. Silakan coba lagi.');
      }
    } catch (e) {
      throw Exception('Error koneksi: $e');
    }
  }

  // 1. Fungsi Mengirim Token Firebase ke Database Laravel
  static Future<void> updateFcmToken(String userId, String token) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/update-fcm-token'),
        headers: {'Accept': 'application/json'},
        body: {
          'pelanggan_id': userId,
          'fcm_token': token,
        },
      );
      print("FCM Token berhasil dikirim ke server");
    } catch (e) {
      print("Gagal mengirim FCM Token: $e");
    }
  }

  // 2. Fungsi Mengambil Daftar Notifikasi dari Laravel
  static Future<List<dynamic>> fetchNotifikasi(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/notifikasi/$userId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']; // Mengambil array data notifikasi
      }
      return [];
    } catch (e) {
      print("Error fetch notifikasi: $e");
      return [];
    }
  }

  // =========================================================
  // PERBAIKAN: Fungsi Pelapor Status Baca Notifikasi
  // =========================================================
  static Future<void> markNotifikasiAsRead(String notifId) async {
    try {
      final url = Uri.parse('$baseUrl/notifikasi/read/$notifId');
      await http.get(url, headers: {'Accept': 'application/json'});
    } catch (e) {
      print("Gagal mengupdate status baca: $e");
    }
  }

  // Fungsi Mengupload Foto Profil ke Laravel (Multipart Request)
  static Future<bool> uploadProfilePicture(String userId, File imageFile) async {
    try {
      final url = Uri.parse('$baseUrl/update-foto-profil');
      
      // Menggunakan MultipartRequest khusus untuk mengirim file fisik
      var request = http.MultipartRequest('POST', url);
      
      // Mengirim ID pelanggan
      request.fields['pelanggan_id'] = userId;
      
      // Membungkus file gambar
      request.files.add(await http.MultipartFile.fromPath(
        'foto', 
        imageFile.path,
      ));

      // Kirim ke server
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['status'] == 'success';
      } else {
        return false;
      }
    } catch (e) {
      print("Error upload foto: $e");
      return false;
    }
  }
}