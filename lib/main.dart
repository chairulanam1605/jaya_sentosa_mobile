import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart'; 
import 'screens/splash_screen.dart'; 

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Notifikasi Masuk (Background): ${message.notification?.title}");
}

// Variabel global Midtrans diaktifkan kembali
MidtransSDK? midtrans;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // BLOK FIREBASE
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
    print("============= FIREBASE SUKSES =============");
  } catch (e) {
    print("============= ERROR FIREBASE =============");
    print(e.toString());
  }

  // BLOK MIDTRANS
  try {
    midtrans = await MidtransSDK.init(
      config: MidtransConfig(
        clientKey: 'Mid-client-Z1tHofBtAPP6XoDO',
        merchantBaseUrl: 'https://adminjsg.com/', 
        colorTheme: ColorTheme(
          colorPrimary: const Color(0xFF1E3A8A),
          colorPrimaryDark: const Color(0xFF1E3A8A),
          colorSecondary: const Color(0xFF1E3A8A),
        ),
      ),
    );
    print("============= MIDTRANS SUKSES =============");
  } catch (e) {
    print("============= ERROR MIDTRANS =============");
    print(e.toString());
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jaya Sentosa Wifian Solution Mobile',
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