import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_detail_screen.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'tagihan_screen.dart';
import 'payment_history_screen.dart';
import '../utils/constants.dart';
import 'privacy_policy_screen.dart'; 

class ProfileMenuScreen extends StatefulWidget {
  const ProfileMenuScreen({super.key});

  @override
  State<ProfileMenuScreen> createState() => _ProfileMenuScreenState();
}

class _ProfileMenuScreenState extends State<ProfileMenuScreen> {
  File? _imageFile;

  // =========================================================
  // VARIABEL CACHE PERMANEN
  // =========================================================
  String _userName = 'Memuat...';
  String _userPackage = 'Memuat...';
  String _fotoUrl = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // =========================================================
  // FUNGSI MENGAMBIL DATA CACHE AGAR NAMA SESUAI AKUN
  // =========================================================
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final user = AuthService.currentUser;

    // Jika data segar masih ada di RAM, amankan ke memori permanen
    if (user != null) {
      await prefs.setString('cache_fullName', user.fullName);
      await prefs.setString('cache_packageName', user.packageName);
      await prefs.setString('cache_fotoProfile', user.fotoProfile ?? '');
    }

    // Terapkan ke layar dari memori permanen
    setState(() {
      _userName = prefs.getString('cache_fullName') ?? 'Pelanggan JSG';
      _userPackage = prefs.getString('cache_packageName') ?? 'Paket WiFi JSG';
      _fotoUrl = prefs.getString('cache_fotoProfile') ?? '';
    });

    _loadSavedImage();
  }

  Future<void> _loadSavedImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedPath = prefs.getString('profile_image_path');

    if (savedPath != null && savedPath.isNotEmpty) {
      File img = File(savedPath);
      if (await img.exists()) {
        setState(() {
          _imageFile = img;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadUserData();
    setState(() {});
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> _launchWhatsApp(BuildContext context) async {
    const String phoneNumber = "6285165863800";
    const String message =
        "Halo Admin Jaya Sentosa Group, saya pelanggan WiFi JSG. Saya butuh bantuan terkait layanan (kendala jaringan / ingin ubah paket).";

    final Uri whatsappUrl = Uri.parse("whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}");
    final Uri webUrl = Uri.parse("https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");

    try {
      bool launched = await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      if (!launched) {
        launched = await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membuka WhatsApp.'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terjadi kesalahan.'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String fullImageUrl = _fotoUrl.isNotEmpty ? 'https://adminjsg.com/public/storage/profil/$_fotoUrl' : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profil Saya', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await AuthService.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFF1E3A8A),
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                ),
                padding: const EdgeInsets.only(bottom: 40, top: 10),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (fullImageUrl.isNotEmpty ? NetworkImage(fullImageUrl) as ImageProvider : null),
                        child: _imageFile == null && fullImageUrl.isEmpty
                            ? const Icon(Icons.person, size: 65, color: Color(0xFF1E3A8A))
                            : null,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      _userName, // 🚀 MENGGUNAKAN NAMA DARI CACHE (Contoh: "Testing")
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      _userPackage, // 🚀 MENGGUNAKAN PAKET DARI CACHE
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Akun & Layanan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                    const SizedBox(height: 15),
                    _buildMenuTile(
                      icon: Icons.assignment_ind_rounded,
                      title: "Detail Profil",
                      subtitle: "Lihat informasi lengkap akun Anda",
                      iconColor: const Color(0xFF1E3A8A),
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileDetailScreen()));
                        _loadUserData(); // 🚀 Refresh data sepulang dari halaman detail
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildMenuTile(
                      icon: Icons.help_outline_rounded,
                      title: "Bantuan & Support",
                      subtitle: "Hubungi admin Jaya Sentosa Group",
                      iconColor: const Color(0xFF25D366),
                      onTap: () => _launchWhatsApp(context),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuTile(
                      icon: Icons.security_rounded,
                      title: "Kebijakan Privasi",
                      subtitle: "Pelajari perlindungan data Anda",
                      iconColor: Colors.blueGrey,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
                      },
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: Column(
                        children: [
                          Text('Jaya Sentosa Mobile', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black.withOpacity(0.3))),
                          Text('Versi ${Constants.version}', style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.3))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1E3A8A),
        unselectedItemColor: Colors.grey,
        currentIndex: 2,
        onTap: (int index) {
          if (index == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TagihanScreen()));
          } else if (index == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PaymentHistoryScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Tagihan'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildMenuTile({required IconData icon, required String title, required String subtitle, required Color iconColor, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 3))]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 28)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}