import 'package:flutter/material.dart';

// --- Model Data Dummy Notifikasi ---
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String date;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    this.isRead = false,
  });
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Data contoh notifikasi untuk simulasi UI
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: 'Tagihan Baru Tersedia',
      message: 'Tagihan internet Anda untuk periode Desember 2025 sebesar Rp 350.000 telah terbit. Harap lakukan pembayaran sebelum tanggal 20 Desember 2025 agar layanan tidak terisolir.',
      date: '01 Des 2025, 08:00',
      isRead: false, // Status belum dibaca (akan ada titik merah)
    ),
    NotificationItem(
      id: '2',
      title: 'Pembayaran Berhasil',
      message: 'Terima kasih! Pembayaran tagihan bulan November 2025 sebesar Rp 350.000 telah berhasil kami terima. Selamat menikmati layanan WiFi Jaya Sentosa.',
      date: '28 Nov 2025, 14:30',
      isRead: true,
    ),
    NotificationItem(
      id: '3',
      title: 'Promo Akhir Tahun!',
      message: 'Dapatkan diskon 10% untuk upgrade ke Paket Keluarga 100 Mbps. Promo berlaku hingga 31 Desember 2025. Hubungi admin melalui menu Bantuan untuk info lebih lanjut.',
      date: '25 Nov 2025, 10:00',
      isRead: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Latar abu-abu terang
      appBar: AppBar(
        title: const Text(
          'Notifikasi', 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notif = _notifications[index];
                return _buildNotificationCard(notif);
              },
            ),
    );
  }

  // Widget untuk membuat baris notifikasi yang bisa di-expand (dibuka)
  Widget _buildNotificationCard(NotificationItem notif) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // Theme digunakan untuk menghilangkan garis batas bawaan ExpansionTile
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: notif.isRead ? Colors.grey.shade100 : const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              notif.isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
              color: notif.isRead ? Colors.grey.shade500 : const Color(0xFF1E3A8A),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  notif.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                    color: notif.isRead ? Colors.black87 : const Color(0xFF1E3A8A),
                  ),
                ),
              ),
              // Indikator titik merah kecil jika notifikasi belum dibaca
              if (!notif.isRead)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                )
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              notif.date,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ),
          // Bagian ini adalah isi detail notifikasi yang akan muncul saat di-klik
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Text(
                notif.message,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tampilan jika daftar notifikasi kosong
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Belum ada notifikasi',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}