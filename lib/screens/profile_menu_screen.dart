import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'profile_detail_screen.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'tagihan_screen.dart';
import 'payment_history_screen.dart';
import '../utils/constants.dart';

class ProfileMenuScreen extends StatefulWidget {
  const ProfileMenuScreen({super.key});

  @override
  State<ProfileMenuScreen> createState() => _ProfileMenuScreenState();
}

class _ProfileMenuScreenState extends State<ProfileMenuScreen> {
  final user = AuthService.currentUser!;

  Future<void> _launchWhatsApp(BuildContext context) async {
    const String phoneNumber = "6285165863800";
    const String message =
        "Halo Admin Jaya Sentosa Group, saya pelanggan WiFi JSG. Saya butuh bantuan terkait layanan (kendala jaringan / ingin ubah paket).";

    // Menggunakan skema url khusus aplikasi WhatsApp
    final Uri whatsappUrl = Uri.parse(
      "whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}",
    );
    final Uri webUrl = Uri.parse(
      "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}",
    );

    try {
      // 1. Coba buka langsung via aplikasi WhatsApp
      bool launched = await launchUrl(
        whatsappUrl,
        mode: LaunchMode.externalApplication,
      );

      // 2. Jika gagal (misal HP tidak pakai WA resmi), coba via link web wa.me
      if (!launched) {
        launched = await launchUrl(
          webUrl,
          mode: LaunchMode.externalApplication,
        );
      }

      // 3. Jika keduanya gagal, baru tampilkan pesan error
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gagal membuka WhatsApp. Pastikan WhatsApp sudah terinstal di HP ini.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Terjadi kesalahan. Pastikan WhatsApp sudah terinstal.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF8F9FA,
      ), // Latar belakang abu-abu sangat muda
      appBar: AppBar(
        automaticallyImplyLeading:
            false, // Menghilangkan ikon panah back di navbar utama
        title: const Text(
          'Profil Saya',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              AuthService.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER SECTION ---
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF1E3A8A),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.only(bottom: 40, top: 10),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 65,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    user.packageName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            // --- MENU SECTION ---
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Akun & Layanan",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Menu Detail Profile
                  _buildMenuTile(
                    icon: Icons.assignment_ind_rounded,
                    title: "Detail Profil",
                    subtitle: "Lihat informasi lengkap akun Anda",
                    iconColor: const Color(0xFF1E3A8A),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileDetailScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Menu Bantuan (WhatsApp)
                  _buildMenuTile(
                    icon: Icons.help_outline_rounded,
                    title: "Bantuan & Support",
                    subtitle: "Hubungi admin Jaya Sentosa Group",
                    iconColor: const Color(0xFF25D366),
                    onTap: () => _launchWhatsApp(context),
                  ),

                  const SizedBox(height: 40),

                  // Footer Version
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Jaya Sentosa Mobile',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ),
                        Text(
                          'Versi ${Constants.version}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1E3A8A),
        unselectedItemColor: Colors.grey,
        currentIndex: 2, // Menandakan Tab Profil aktif
        onTap: (int index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const TagihanScreen()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const PaymentHistoryScreen(),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Tagihan'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  // Helper Widget untuk membuat list menu yang rapi
  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
