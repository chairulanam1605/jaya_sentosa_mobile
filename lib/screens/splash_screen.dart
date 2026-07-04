import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// PASTIKAN IMPORT INI SESUAI DENGAN NAMA FILE-MU
import 'login_screen.dart'; 
import 'tagihan_screen.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // Panggil fungsi pengecekan saat layar berkedip
  }

  Future<void> _checkLoginStatus() async {
    // 1. Berikan jeda waktu 2 detik agar logo aplikasi (Splash Screen) terlihat
    await Future.delayed(const Duration(seconds: 2));

    // 2. Buka brankas memori HP (SharedPreferences)
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // 3. Cari apakah ada ID User yang tertinggal/tersimpan
    String? userId = prefs.getString('user_id');

    if (mounted) {
      if (userId != null && userId.isNotEmpty) {
        // JIKA SUDAH LOGIN: Langsung lompat ke Halaman Tagihan!
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TagihanScreen()),
        );
      } else {
        // JIKA BELUM LOGIN: Arahkan ke Halaman Login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E3A8A), // Warna Biru JSG
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            // Logo aplikasi (Bisa kamu ganti dengan gambar logomu nanti)
            Icon(Icons.wifi, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Jaya Sentosa Mobile',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(color: Colors.white), // Animasi loading
          ],
        ),
      ),
    );
  }
}