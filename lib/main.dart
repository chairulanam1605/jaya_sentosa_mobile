import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/splash_screen.dart'; // Import bawaan Mas Anam tetap aman

// 1. FUNGSI PENANGKAP NOTIFIKASI BACKGROUND
// PENTING: Fungsi ini HARUS berada di luar class mana pun (paling luar / sejajar dengan import)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Inisialisasi Firebase agar bisa berjalan walau aplikasi ditutup
  await Firebase.initializeApp();
  print("Notifikasi Masuk (Background): ${message.notification?.title}");
}

// 2. FUNGSI MAIN DIUBAH MENJADI ASYNC
void main() async {
  // Memastikan fondasi Flutter sudah siap sebelum memuat Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // Menyalakan mesin Firebase
  await Firebase.initializeApp();

  // Meminta izin memunculkan notifikasi (Wajib untuk HP Android versi baru)
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Mendaftarkan fungsi penangkap notifikasi background yang dibuat di atas
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Mengambil KTP/Token HP
  // Token ini ibarat "Nomor HP" agar sistem admin tahu harus kirim notif ke HP yang mana
  String? token = await messaging.getToken();
  print("============= TOKEN FIREBASE HP INI =============");
  print(token);
  print("=================================================");

  runApp(const MyApp());
}

// 3. CLASS MYAPP BAWAAN MAS ANAM (TIDAK ADA YANG DIUBAH)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jaya Sentosa Mobile',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}