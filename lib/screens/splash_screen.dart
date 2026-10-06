import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');

    if (mounted) {
      if (userId != null && userId.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TagihanScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFF1E3A8A);

    // ⭐ UBAH ANGKA INI untuk mengatur seberapa banyak padding bawah dipotong
    const double logoVisibleHeight = 110;
    const double logoFullSize = 160;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ============================================================
            // LOGO — dipotong bagian bawahnya dengan ClipRect + OverflowBox
            // ============================================================
            SizedBox(
              width: logoFullSize,
              height: logoVisibleHeight,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  maxHeight: logoFullSize,
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      backgroundColor,
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

            // ⭐ PERUBAHAN: Jarak dari 4 → 12 (turunkan teks sedikit)
            const SizedBox(height: 12),

            // Nama Brand Utama
            const Text(
              'JAYA SENTOSA',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
              ),
            ),

            const SizedBox(height: 4),

            // Sub-brand
            const Text(
              'Wifian Solution Mobile',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 40),

            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}