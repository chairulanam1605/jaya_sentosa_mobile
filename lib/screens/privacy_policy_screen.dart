import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Kebijakan Privasi',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy Jaya Sentosa Mobile',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Terakhir Diperbarui: 27 Juni 2026',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),
            _buildBodyText(
              'Terima kasih telah menggunakan aplikasi Jaya Sentosa Mobile. Kebijakan Privasi ini menjelaskan bagaimana kami mengumpulkan, menggunakan, dan melindungi informasi Anda saat menggunakan aplikasi layanan WiFi dari Jaya Sentosa Group (JSG).',
            ),
            
            _buildSectionTitle('1. Informasi yang Kami Kumpulkan'),
            _buildBodyText('Untuk memberikan layanan yang maksimal, kami mengumpulkan beberapa data berikut:'),
            _buildBulletPoint('Informasi Pribadi', 'Nama lengkap, alamat email, nomor pelanggan, dan nomor telepon.'),
            _buildBulletPoint('Informasi Perangkat', 'Token Firebase Cloud Messaging (FCM) untuk mengirimkan pemberitahuan (notifikasi) ke perangkat Anda.'),
            _buildBulletPoint('Izin Kamera & Galeri', 'Akses ke kamera atau galeri foto perangkat hanya digunakan ketika Anda secara sadar ingin memperbarui foto profil akun Anda.'),

            _buildSectionTitle('2. Bagaimana Kami Menggunakan Informasi Anda'),
            _buildBodyText('Informasi yang dikumpulkan akan digunakan untuk:'),
            _buildSimpleBullet('Mengidentifikasi Anda sebagai pelanggan sah WiFi Jaya Sentosa Group.'),
            _buildSimpleBullet('Menghitung dan membuat tagihan layanan internet bulanan.'),
            _buildSimpleBullet('Mengirimkan notifikasi pengingat pembayaran tagihan atau pemutusan layanan.'),
            _buildSimpleBullet('Menyediakan layanan bantuan (Customer Service) melalui WhatsApp.'),

            _buildSectionTitle('3. Layanan Pihak Ketiga'),
            _buildBodyText('Aplikasi kami terhubung dengan layanan pihak ketiga yang memiliki kebijakan privasi mereka masing-masing:'),
            _buildBulletPoint('Midtrans', 'Digunakan sebagai gerbang pembayaran (Payment Gateway) resmi untuk memproses transaksi Anda secara aman. Kami tidak menyimpan detail kartu kredit atau PIN bank Anda.'),
            _buildBulletPoint('Google Firebase', 'Digunakan untuk mengirimkan pesan push notification ke perangkat Anda.'),

            _buildSectionTitle('4. Keamanan Data'),
            _buildBodyText('Kami sangat menghargai kepercayaan Anda dalam memberikan informasi pribadi. Semua data disimpan secara aman di dalam server pangkalan data (database) kami dan hanya digunakan untuk keperluan administrasi layanan WiFi JSG.'),

            _buildSectionTitle('5. Permintaan Penghapusan Data'),
            _buildBodyText('Anda memiliki hak untuk meminta penghapusan akun dan data pribadi Anda dari sistem kami. Jika Anda memutuskan untuk berhenti berlangganan layanan WiFi JSG, Anda dapat menghubungi admin melalui layanan WhatsApp yang tersedia di dalam aplikasi.'),

            _buildSectionTitle('6. Perubahan pada Kebijakan Privasi Ini'),
            _buildBodyText('Kami dapat memperbarui Kebijakan Privasi ini dari waktu ke waktu. Setiap perubahan akan diberitahukan melalui pembaruan di halaman ini.'),

            _buildSectionTitle('7. Hubungi Kami'),
            _buildBodyText('Jika Anda memiliki pertanyaan atau saran tentang Kebijakan Privasi kami, jangan ragu untuk menghubungi kami melalui:'),
            _buildBulletPoint('Email', 'showroomjayasentosa@gmail.com'),
            _buildBulletPoint('WhatsApp Admin', '0851 6586 3800'),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildBodyText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
        textAlign: TextAlign.justify,
      ),
    );
  }

  Widget _buildBulletPoint(String title, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontSize: 16, height: 1.5)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                children: [
                  TextSpan(
                    text: "$title: ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontSize: 16, height: 1.5)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}