import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart'; // Tambahan wajib untuk membuka WhatsApp

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

  Future<void> _launchWhatsAppSupport() async {
    const String phoneNumber = "6285165863800"; // Nomor WhatsApp Admin JSG
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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E3A8A),
              Color(0xFF3B82F6),
            ], 
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15), 
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.wifi_rounded,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Jaya Sentosa Mobile',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Solusi Pembayaran WiFi Desa JSG',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'Selamat Datang',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        _buildTextField(
                          controller: _nikController,
                          label: 'NIK',
                          hint: 'Masukkan NIK Anda',
                          icon: Icons.badge,
                        ),
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Kata Sandi',
                          hint: 'Masukkan Kata Sandi', 
                          icon: Icons.lock_outline,
                          isPassword: true, 
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _launchWhatsAppSupport,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Lupa Kata Sandi?',
                              style: TextStyle(
                                color: Color(0xFF3B82F6),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Tombol Masuk
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _doLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white, 
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 4,
                              shadowColor: const Color(0xFF1E3A8A).withOpacity(0.5),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : const Text(
                                    'MASUK',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'Butuh bantuan? Hubungi kami',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _launchWhatsAppSupport,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.support_agent_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              Constants.supportPhone,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
            color: Colors.black54,
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
            prefixIcon: Icon(icon, color: const Color(0xFF1E3A8A), size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey.shade500,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF8FAFC), 
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}