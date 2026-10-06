import 'dart:io'; 
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invoice_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = "https://adminjsg.com/api"; 

  static Future<List<InvoiceModel>> fetchUnpaidInvoices(String pelangganId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tagihan/unpaid/$pelangganId'),
        headers: {'Accept': 'application/json'},
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

  static Future<List<InvoiceModel>> fetchPaidInvoices(String pelangganId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tagihan/paid/$pelangganId'),
        headers: {'Accept': 'application/json'},
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

  // ============================================================
  // LOGIN — Sekarang simpan SEMUA data ke cache
  // ============================================================
  static Future<bool> login(String nik, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'), 
        headers: {'Accept': 'application/json'},
        body: {'nik': nik, 'password': password},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final userData = jsonResponse['data'];
        
        final String userId = userData['pelanggan_id'].toString();

        // Buat UserModel dari response
        final userModel = UserModel.fromJson(userData);

        // Bersihkan cache lama
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.clear(); 

        // ============================================================
        // ⭐ SIMPAN SEMUA DATA KE CACHE (langsung dari response login)
        // Ini memastikan TagihanScreen langsung menampilkan data yang benar
        // tanpa perlu menunggu _fetchFreshProfile() selesai
        // ============================================================
        await prefs.setString('user_id', userId);
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('cache_fullName', userModel.fullName);
        await prefs.setString('cache_packageName', userModel.packageName);
        await prefs.setString('cache_customerNumber', userModel.customerNumber);
        await prefs.setString('cache_phone', userModel.phone);
        await prefs.setString('cache_email', userModel.email);
        await prefs.setString('cache_masaAktif', userModel.masaAktif.toIso8601String());
        await prefs.setString('cache_statusLayanan', userModel.statusLayanan);
        if (userModel.fotoProfile != null) {
          await prefs.setString('cache_fotoProfile', userModel.fotoProfile!);
        }

        AuthService.currentUser = userModel;

        return true;
      } else {
        return false;
      }
    } catch (e) {
      throw Exception('Error koneksi: $e');
    }
  }

  static Future<bool> updateProfile(String nik, String nama, String email, String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update-profile'),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode({'nik': nik, 'nama': nama, 'email': email, 'no_telepon': phone}),
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

  static Future<void> updateFcmToken(String userId, String token) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/update-fcm-token'),
        headers: {'Accept': 'application/json'},
        body: {'pelanggan_id': userId, 'fcm_token': token},
      );
    } catch (e) {
      print("Gagal mengirim FCM Token: $e");
    }
  }

  static Future<List<dynamic>> fetchNotifikasi(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/notifikasi/$userId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      }
      return [];
    } catch (e) {
      print("Error fetch notifikasi: $e");
      return [];
    }
  }

  static Future<void> markNotifikasiAsRead(String notifId) async {
    try {
      final url = Uri.parse('$baseUrl/notifikasi/read/$notifId');
      await http.get(url, headers: {'Accept': 'application/json'});
    } catch (e) {
      print("Gagal mengupdate status baca: $e");
    }
  }

  static Future<bool> uploadProfilePicture(String userId, File imageFile) async {
    try {
      final url = Uri.parse('$baseUrl/update-foto-profil');
      var request = http.MultipartRequest('POST', url);
      request.fields['pelanggan_id'] = userId;
      request.files.add(await http.MultipartFile.fromPath('foto', imageFile.path));

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

  static Future<bool> deleteProfilePicture(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/delete-foto-profil'),
        headers: {'Accept': 'application/json'},
        body: {'pelanggan_id': userId},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['status'] == 'success';
      } else {
        return false;
      }
    } catch (e) {
      print("Error delete foto profil: $e");
      return false;
    }
  }
}