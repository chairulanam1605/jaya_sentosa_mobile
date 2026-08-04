import 'package:flutter/material.dart';
import 'package:jaya_sentosa_mobile/services/api_service.dart'; 
import 'package:jaya_sentosa_mobile/models/invoice_model.dart'; 
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:url_launcher/url_launcher.dart';

// 🚀 DITAMBAHKAN UNTUK MENEMBAK API PROFIL
import 'package:http/http.dart' as http; 
import 'dart:convert'; 

import 'profile_menu_screen.dart'; 
import 'payment_history_screen.dart';
import 'payment_screen.dart'; 
import 'notification_screen.dart';
import '../services/auth_service.dart'; 

class TagihanScreen extends StatefulWidget {
  const TagihanScreen({super.key});

  @override
  State<TagihanScreen> createState() => _TagihanScreenState();
}

class _TagihanScreenState extends State<TagihanScreen> {
  final int _currentIndex = 0;
  String currentUserId = ""; 
  bool _hasUnreadNotif = false; 

  // Variabel Cache Permanen
  String _userName = 'Pelanggan JSG';
  String _userPackage = 'Paket WiFi JSG';
  String _userCustomerNumber = '-';
  String _userPhone = '080000000000';
  DateTime _userMasaAktif = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadUserData(); 
  }

  // =========================================================
  // 1. FUNGSI CERDAS: Menyimpan & Membaca dari Cache
  // =========================================================
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Cek apakah data sudah ada di cache sebelumnya
    String? cachedName = prefs.getString('cache_fullName');
    
    // Jika masih kosong (baru pertama kali login), amankan datanya dari Auth
    if (cachedName == null) {
      final user = AuthService.currentUser;
      if (user != null) {
        await prefs.setString('cache_fullName', user.fullName);
        await prefs.setString('cache_packageName', user.packageName);
        await prefs.setString('cache_customerNumber', user.customerNumber ?? '-');
        await prefs.setString('cache_phone', user.phone);
        await prefs.setString('cache_masaAktif', user.masaAktif.toIso8601String());
      }
    }
    
    // Terapkan data ke tampilan UI agar anti-blank
    setState(() {
      currentUserId = prefs.getString('user_id') ?? ''; 
      _userName = prefs.getString('cache_fullName') ?? 'Pelanggan JSG';
      _userPackage = prefs.getString('cache_packageName') ?? 'Paket WiFi JSG';
      _userCustomerNumber = prefs.getString('cache_customerNumber') ?? '-';
      _userPhone = prefs.getString('cache_phone') ?? '080000000000';
      
      String? masaAktifStr = prefs.getString('cache_masaAktif');
      if (masaAktifStr != null && masaAktifStr.isNotEmpty) {
        _userMasaAktif = DateTime.parse(masaAktifStr);
      }
    });
    
    if (currentUserId.isNotEmpty) {
      _checkUnreadNotifications(); 
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) ApiService.updateFcmToken(currentUserId, token);
    }
  }

  // =========================================================
  // 2. FUNGSI BARU: Ambil Profil Terbaru (Masa Aktif & Paket)
  // =========================================================
  Future<void> _fetchFreshProfile() async {
    if (currentUserId.isEmpty) return;
    
    try {
      final url = Uri.parse('https://adminjsg.com/public/api/profil/$currentUserId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          final freshData = responseData['data'];
          
          SharedPreferences prefs = await SharedPreferences.getInstance();
          
          // ⚠️ PENTING: Menangkap nama kolom dari database.
          // Fallback ini (misal: 'package_name' ?? 'nama_paket' ?? 'paket') digunakan
          // agar menyesuaikan dengan apapun nama kolom database milik temanmu.
          String freshName = freshData['name'] ?? freshData['nama'] ?? _userName;
          String freshPackage = freshData['package_name'] ?? freshData['nama_paket'] ?? freshData['paket'] ?? _userPackage;
          String freshMasaAktif = freshData['masa_aktif'] ?? freshData['active_date'] ?? _userMasaAktif.toIso8601String();
          
          // Timpa memori hp secara permanen dengan data yang sudah di-acc admin
          await prefs.setString('cache_fullName', freshName);
          await prefs.setString('cache_packageName', freshPackage); 
          await prefs.setString('cache_masaAktif', freshMasaAktif);
        }
      }
    } catch (e) {
      print("Gagal mengambil profil terbaru: $e");
    }
  }

  // =========================================================
  // 3. FUNGSI REFRESH YANG SUDAH DIPERBARUI
  // =========================================================
  Future<void> _refreshData() async {
    // Jalankan tembakan API profil terlebih dahulu
    await _fetchFreshProfile(); 
    // Setelah data terbaru tersimpan, panggil ulang layar
    await _loadUserData();      
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _checkUnreadNotifications() async {
    try {
      final notifs = await ApiService.fetchNotifikasi(currentUserId);
      bool unreadExists = notifs.any((notif) => notif['is_read'] == 0 || notif['is_read'] == false);
      
      if (mounted) {
        setState(() {
          _hasUnreadNotif = unreadExists;
        });
      }
    } catch (e) {
      print("Gagal mengecek notifikasi: $e");
    }
  }

  String _formatRupiah(double amount) {
    return 'Rp ${amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  Future<void> _launchWhatsApp() async {
    final Uri url = Uri.parse(
        'whatsapp://send?phone=6285165863800&text=Halo%20Admin%20JSG,%20saya%20butuh%20bantuan%20terkait%20layanan%20WiFi.');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka WhatsApp. Pastikan aplikasi terinstal.')),
        );
      }
    }
  }

  String _formatDateIndonesia(DateTime date) {
    const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Menghitung sisa hari menggunakan variabel cache yang otomatis ter-update
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activeDate = DateTime(_userMasaAktif.year, _userMasaAktif.month, _userMasaAktif.day);
    int sisaHari = activeDate.difference(today).inDays;

    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text('Jaya Sentosa Mobile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationScreen()),
                  );
                  _checkUnreadNotifications(); 
                },
              ),
              if (_hasUnreadNotif)
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1E3A8A), width: 1.5),
                    ),
                  ),
                )
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFF1E3A8A),
        backgroundColor: Colors.white,
        child: currentUserId.isEmpty 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)))
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(), 
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Selamat datang,', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  
                  // Menggunakan Cache Nama Pelanggan
                  Text(
                    _userName, 
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.black87)
                  ),
                  const SizedBox(height: 24),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.08), spreadRadius: 2, blurRadius: 15, offset: const Offset(0, 5)),
                      ],
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Paket Internet Aktif', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                        const SizedBox(height: 8),
                        
                        // Menggunakan Cache Nama Paket
                        Text(
                          _userPackage, 
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            
                            // Menggunakan Cache Masa Aktif
                            Text(
                              'Berlaku hingga: ${_formatDateIndonesia(_userMasaAktif)}', 
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.timer_outlined, size: 16, color: sisaHari < 0 ? Colors.red : Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              sisaHari < 0 
                                ? 'Telah lewat masa aktif: ${sisaHari.abs()} hari' 
                                : 'Sisa masa aktif: $sisaHari hari lagi', 
                              style: TextStyle(
                                fontSize: 13, 
                                fontWeight: FontWeight.bold, 
                                color: sisaHari < 0 ? Colors.red : Colors.green, 
                              )
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text('Tagihan Bulan Ini', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
                  const SizedBox(height: 16),

                  FutureBuilder<List<InvoiceModel>>(
                    future: ApiService.fetchUnpaidInvoices(currentUserId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(padding: EdgeInsets.only(top: 30.0), child: CircularProgressIndicator(color: Color(0xFF1E3A8A))));
                      } else if (snapshot.hasError) {
                        return Center(child: Padding(padding: const EdgeInsets.only(top: 30.0), child: Text('Gagal memuat data: ${snapshot.error}')));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 40.0),
                            child: Column(
                              children: [
                                Icon(Icons.check_circle_outline, size: 60, color: Colors.green.shade300),
                                const SizedBox(height: 12),
                                const Text('Hore! Semua tagihan Anda sudah lunas.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                              ],
                            ),
                          ),
                        );
                      }

                      final invoices = snapshot.data!;
                      return Column(
                        children: invoices.map((invoice) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: Colors.grey.withOpacity(0.08), spreadRadius: 2, blurRadius: 15, offset: const Offset(0, 5)),
                              ],
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(invoice.periode, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(20)),
                                      child: const Text('Belum Dibayar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16.0),
                                  child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                                ),
                                
                                Text('Total Tagihan', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                                const SizedBox(height: 4),
                                Text(
                                  _formatRupiah(invoice.jumlah), 
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A))
                                ),
                                const SizedBox(height: 24),

                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E3A8A),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                      elevation: 2,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PaymentScreen(invoice: invoice),
                                        ),
                                      );
                                    },
                                    child: const Text('BAYAR TAGIHAN SEKARANG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 80), 
                ],
              ),
            ),
      ),
          
      floatingActionButton: FloatingActionButton(
        onPressed: _launchWhatsApp,
        backgroundColor: const Color(0xFF25D366), 
        elevation: 4,
        shape: const CircleBorder(), 
        child: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 32),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF1E3A8A),
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          elevation: 0,
          onTap: (index) {
            if (index == 1) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PaymentHistoryScreen()));
            } else if (index == 2) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileMenuScreen()));
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Tagihan'),
            BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Riwayat'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}