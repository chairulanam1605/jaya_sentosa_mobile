import 'package:flutter/material.dart';
import 'package:jaya_sentosa_mobile/services/api_service.dart';
import 'package:jaya_sentosa_mobile/models/invoice_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'profile_menu_screen.dart';
import 'payment_history_screen.dart';
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

  // =========================================================
  // PERBAIKAN 1: Variabel penampung status titik merah
  // =========================================================
  bool _hasUnreadNotif = false;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getString('user_id') ?? '';
    });

    if (currentUserId.isNotEmpty) {
      _checkUnreadNotifications(); // Cek status titik merah saat layar dimuat

      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        ApiService.updateFcmToken(currentUserId, token);
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadUserId();
    setState(() {});
    await Future.delayed(const Duration(seconds: 1));
  }

  // =========================================================
  // PERBAIKAN 2: Fungsi mengecek apakah ada notif yang belum dibaca
  // =========================================================
  Future<void> _checkUnreadNotifications() async {
    try {
      final notifs = await ApiService.fetchNotifikasi(currentUserId);
      // Mengecek apakah ada satupun notifikasi yang is_read nya 0 atau false
      bool unreadExists = notifs.any(
        (notif) => notif['is_read'] == 0 || notif['is_read'] == false,
      );

      if (mounted) {
        setState(() {
          _hasUnreadNotif = unreadExists; // Update status titik merah
        });
      }
    } catch (e) {
      print("Gagal mengecek notifikasi: $e");
    }
  }

  // =========================================================
  // PERBAIKAN 3: Fungsi ajaib pembuat titik pada nominal Rupiah
  // =========================================================
  String _formatRupiah(double amount) {
    return 'Rp ${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  Future<void> _launchWhatsApp() async {
    final Uri url = Uri.parse(
      'whatsapp://send?phone=6285165863800&text=Halo%20Admin%20JSG,%20saya%20butuh%20bantuan%20terkait%20layanan%20WiFi.',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gagal membuka WhatsApp. Pastikan aplikasi terinstal.',
            ),
          ),
        );
      }
    }
  }

  String _formatDateIndonesia(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _prosesPembayaranKeMidtrans(InvoiceModel invoice) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    final url = Uri.parse('https://adminjsg.com/public/api/checkout');
    final user = AuthService.currentUser;

    final dataBody = {
      'harga_total': invoice.jumlah.toInt().toString(),
      'nama': user?.fullName ?? 'Pelanggan JSG',
      'email':
          '${(user?.fullName ?? 'pelanggan').toLowerCase().replaceAll(' ', '')}@gmail.com',
      'phone': user?.phone ?? '080000000000',
      'invoice_id': invoice.id.toString(),
    };

    try {
      final response = await http.post(
        url,
        headers: {'Accept': 'application/json'},
        body: dataBody,
      );

      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final String snapToken = responseData['token'];

        MidtransSDK? midtransLokal = await MidtransSDK.init(
          config: MidtransConfig(
            clientKey: 'SB-Mid-client-Z1tHofBtAPP6XoDO',
            merchantBaseUrl: 'https://adminjsg.com/public/',
            colorTheme: ColorTheme(
              colorPrimary: const Color(0xFF1E3A8A),
              colorPrimaryDark: const Color(0xFF1E3A8A),
              colorSecondary: const Color(0xFF1E3A8A),
            ),
          ),
        );
        midtransLokal.startPaymentUiFlow(token: snapToken);
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Ditolak Server (${response.statusCode})"),
              content: Text(response.body),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Error Jaringan/Sistem"),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    int sisaHari = 0;
    if (user != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final activeDate = DateTime(
        user.masaAktif.year,
        user.masaAktif.month,
        user.masaAktif.day,
      );
      sisaHari = activeDate.difference(today).inDays;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text(
          'Jaya Sentosa Mobile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () async {
                  // Await agar sistem menunggu sampai pengguna menutup layar notifikasi
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationScreen(),
                    ),
                  );
                  // Refresh ulang titik merahnya saat pengguna kembali ke beranda!
                  _checkUnreadNotifications();
                },
              ),
              // Titik merah HANYA muncul jika ada notif yang belum dibaca
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
                      border: Border.all(
                        color: const Color(0xFF1E3A8A),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
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
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
              )
            : SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(), // WAJIB DITAMBAHKAN
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat datang,',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.fullName ?? 'Pelanggan JSG',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            spreadRadius: 2,
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Paket Internet Aktif',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user?.packageName ?? 'Paket WiFi JSG',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Berlaku hingga: ${user != null ? _formatDateIndonesia(user.masaAktif) : "-"}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 16,
                                color: sisaHari < 0 ? Colors.red : Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                sisaHari < 0
                                    ? 'Telah lewat masa aktif: ${sisaHari.abs()} hari'
                                    : 'Sisa masa aktif: $sisaHari hari lagi',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: sisaHari < 0
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    const Text(
                      'Tagihan Bulan Ini',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    FutureBuilder<List<InvoiceModel>>(
                      future: ApiService.fetchUnpaidInvoices(currentUserId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 30.0),
                              child: CircularProgressIndicator(
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 30.0),
                              child: Text(
                                'Gagal memuat data: ${snapshot.error}',
                              ),
                            ),
                          );
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 40.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 60,
                                    color: Colors.green.shade300,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Hore! Semua tagihan Anda sudah lunas.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
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
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.08),
                                    spreadRadius: 2,
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                                border: Border.all(color: Colors.grey.shade100),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        invoice.periode,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: const Text(
                                          'Belum Dibayar',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 16.0,
                                    ),
                                    child: Divider(
                                      height: 1,
                                      color: Color(0xFFEEEEEE),
                                    ),
                                  ),

                                  Text(
                                    'Total Tagihan',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // =========================================================
                                  // MENGGUNAKAN FUNGSI FORMAT RUPIAH DI SINI
                                  // =========================================================
                                  Text(
                                    _formatRupiah(invoice.jumlah),
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1E3A8A),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF1E3A8A,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                        elevation: 2,
                                      ),
                                      onPressed: () {
                                        _prosesPembayaranKeMidtrans(invoice);
                                      },
                                      child: const Text(
                                        'BAYAR TAGIHAN SEKARANG',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
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
        child: const Icon(
          Icons.help_outline_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF1E3A8A),
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          elevation: 0,
          onTap: (index) {
            if (index == 1) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const PaymentHistoryScreen(),
                ),
              );
            } else if (index == 2) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileMenuScreen(),
                ),
              );
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Tagihan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              label: 'Riwayat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
