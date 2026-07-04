import 'package:flutter/material.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/splash_screen.dart'; 

// Fungsi penangkap notifikasi saat aplikasi berjalan di background/ditutup
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Notifikasi Masuk (Background): ${message.notification?.title}");
}

MidtransSDK? midtrans;

void main() async {
  // Memastikan fondasi Flutter siap
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. BLOK FIREBASE (Dibungkus Try-Catch agar aman)
  try {
    // Menjalankan inisialisasi Firebase
    await Firebase.initializeApp();
    
    // Mendaftarkan fungsi background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Meminta izin kepada pengguna untuk menampilkan notifikasi (Wajib untuk Android 13+)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    print("============= FIREBASE SUKSES =============");
  } catch (e) {
    print("============= ERROR FIREBASE =============");
    print(e.toString());
  }

  // 2. BLOK MIDTRANS (Dibersihkan dan Diperbaiki)
  try {
    midtrans = await MidtransSDK.init(
      config: MidtransConfig(
        // PERBAIKAN 1: Ditambahkan 'SB-' untuk menandakan jalur Sandbox
        clientKey: 'SB-Mid-client-Z1tHofBtAPP6XoDO', 
        
        // PERBAIKAN 2: Ditambahkan '/public/' agar tidak terkena error 301 Redirect
        merchantBaseUrl: 'https://adminjsg.com/public/', 
        
        colorTheme: ColorTheme(
          colorPrimary: const Color(0xFF1E3A8A), // Warna biru tema Jaya Sentosa
          colorPrimaryDark: const Color(0xFF1E3A8A),
          colorSecondary: const Color(0xFF1E3A8A),
        ),
      ),
    );

    // Pengaturan tambahan agar pelanggan langsung masuk ke pilihan pembayaran 
    // tanpa perlu mengetik ulang nama dan email di layar Midtrans

    print("============= MIDTRANS SUKSES =============");
  } catch (e) {
    print("============= ERROR MIDTRANS =============");
    print(e.toString());
  }

  // 3. JALANKAN APLIKASI
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jaya Sentosa Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A8A)),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}