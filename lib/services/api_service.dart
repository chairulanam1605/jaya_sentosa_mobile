import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/invoice_model.dart';

class ApiService {
  // PENTING: Jika testing pakai WiFi lokal (HP & Laptop nyambung WiFi yg sama), 
  // ganti IP di bawah dengan IPv4 Address laptop teman Anda.
  // Contoh: 'http://192.168.1.15:8000/api'
  static const String baseUrl = "http://172.10.10.40:8000/api"; 

  // Ambil Tagihan Belum Dibayar
  static Future<List<InvoiceModel>> fetchUnpaidInvoices(String pelangganId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/tagihan/unpaid/$pelangganId'));

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
      final response = await http.get(Uri.parse('$baseUrl/tagihan/paid/$pelangganId'));

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
}