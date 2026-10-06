import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'tagihan_screen.dart';
import '../utils/constants.dart';
import '../services/api_service.dart'; 
import '../services/auth_service.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  static const Color _brandBlue = Color(0xFF1E3A8A);

  Future<void> _launchWhatsAppSupport() async {
    const String phoneNumber = "6285165863800";
    const String message = "Halo Admin Jaya Sentosa Group, saya butuh bantuan untuk login ke aplikasi Jaya Sentosa Mobile.";

    final Uri whatsappUrl = Uri.parse("whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}");
    final Uri webUrl = Uri.parse("https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");

    try {
      bool launched = await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      if (!launched) {
        launched = await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka WhatsApp. Pastikan aplikasi terinstal.'), backgroundColor: Colors.red)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terjadi kesalahan saat membuka WhatsApp.'), backgroundColor: Colors.red)
        );
      }
    }
  }

  void _doLogin() async {
    String nik = _nikController.text.trim();
    String password = _passwordController.text.trim();

    if (nik.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('NIK dan Kata Sandi tidak boleh kosong!'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      bool isSuccess = await ApiService.login(nik, password);

      if (isSuccess) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        
        String namaUser = AuthService.currentUser?.fullName ?? 'Pelanggan';

        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Selamat datang, $namaUser!'), backgroundColor: Colors.green),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const TagihanScreen()),
          );
        }
      } else {
        throw Exception('Login gagal, periksa NIK dan Kata Sandi Anda.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ⭐ ATUR DI SINI: Semakin besar nilainya, semakin BESAR logo tampil di layar
    // - logoFullSize  : ukuran render gambar (makin besar makin jelas tapi potong padding lebih banyak)
    // - logoVisible   : tinggi area yang "terlihat" saja
    const double logoFullSize = 220;
    const double logoVisible = 160;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _brandBlue,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ============================================================
                // LOGO BESAR + dipotong padding bawahnya
                // ============================================================
                SizedBox(
                  width: logoFullSize,
                  height: logoVisible,
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.topCenter,
                      maxHeight: logoFullSize,
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          _brandBlue,
                          BlendMode.lighten,
                        ),
                        child: Image.asset(
                          'assets/icon.png',
                          width: logoFullSize,
                          height: logoFullSize,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.wifi_rounded,
                              size: 80,
                              color: Colors.white,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // ⭐ PERUBAHAN: Jarak langsung 0 supaya teks menempel ke logo
                const SizedBox(height: 0),

                // Nama brand
                const Text(
                  'JAYA SENTOSA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3.0,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Wifian Solution Mobile',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 28),

                // ============================================================
                // CARD FORM LOGIN
                // ============================================================
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Selamat Datang',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _brandBlue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          'Silakan masuk untuk melanjutkan',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildTextField(
                        controller: _nikController,
                        label: 'NIK',
                        hint: 'Masukkan NIK Anda',
                        icon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _passwordController,
                        label: 'Kata Sandi',
                        hint: 'Masukkan Kata Sandi',
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                      ),

                      const SizedBox(height: 4),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _launchWhatsAppSupport,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Lupa Kata Sandi?',
                            style: TextStyle(
                              color: _brandBlue,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _doLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _brandBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20, width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  'MASUK',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ============================================================
                // FOOTER BANTUAN
                // ============================================================
                Text(
                  'Butuh bantuan? Hubungi kami',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: _launchWhatsAppSupport,
                  icon: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 16),
                  label: Text(
                    Constants.supportPhone,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.white.withOpacity(0.4), width: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword ? _obscurePassword : false,
          style: const TextStyle(fontSize: 15, color: Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(icon, color: _brandBlue, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey.shade500,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _brandBlue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}