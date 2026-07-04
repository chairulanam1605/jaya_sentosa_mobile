import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String currentUserId = "";

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  // Mengambil ID User yang sedang login
  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getString('user_id') ?? '';
    });
  }

  Future<void> _refreshData() async {
    await _loadUserId();
    setState(() {});
    await Future.delayed(const Duration(seconds: 1));
  }

  // Fungsi pembantu untuk memformat waktu dari server MySQL
  String _formatDateTime(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      String day = date.day.toString().padLeft(2, '0');
      String month = months[date.month - 1];
      String year = date.year.toString();
      String hour = date.hour.toString().padLeft(2, '0');
      String minute = date.minute.toString().padLeft(2, '0');

      return '$day $month $year, $hour:$minute';
    } catch (e) {
      return dateString;
    }
  }

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
      // FutureBuilder untuk mengambil data asli dari Laravel
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFF1E3A8A),
        backgroundColor: Colors.white,
        child: currentUserId.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
              )
            : FutureBuilder<List<dynamic>>(
                future: ApiService.fetchNotifikasi(currentUserId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1E3A8A),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Terjadi kesalahan: ${snapshot.error}'),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Data berhasil diambil
                  final notifs = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: notifs.length,
                    itemBuilder: (context, index) {
                      final notif = notifs[index];
                      return _buildNotificationCard(notif);
                    },
                  );
                },
              ),
      ),
    );
  }

  // Widget untuk membuat baris notifikasi yang bisa di-expand (Menerima data dinamis)
  Widget _buildNotificationCard(dynamic notif) {
    // Membaca data dari API Laravel
    String title = notif['judul'] ?? 'Pemberitahuan';
    String message = notif['pesan'] ?? '';
    String date = _formatDateTime(notif['created_at']);
    // Mengecek status baca (Laravel boolean biasanya return 1/0 atau true/false)
    bool isRead = notif['is_read'] == 1 || notif['is_read'] == true;

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
          // =========================================================
          // PERBAIKAN: Sensor untuk menghilangkan titik merah saat ditekan
          // =========================================================
          onExpansionChanged: (bool expanded) {
            if (expanded && !isRead) {
              setState(() {
                notif['is_read'] = 1; // Ubah data lokal, titik merah hilang
              });

              if (notif['id'] != null) {
                // Lapor ke server Laravel
                ApiService.markNotifikasiAsRead(notif['id'].toString());
              }
            }
          },
          // =========================================================
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isRead ? Colors.grey.shade100 : const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isRead
                  ? Icons.notifications_none_rounded
                  : Icons.notifications_active_rounded,
              color: isRead ? Colors.grey.shade500 : const Color(0xFF1E3A8A),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                    color: isRead ? Colors.black87 : const Color(0xFF1E3A8A),
                  ),
                ),
              ),
              // Indikator titik merah kecil jika notifikasi belum dibaca
              if (!isRead)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              date,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ),
          // Bagian ini adalah isi detail notifikasi yang akan muncul saat di-klik
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Text(
                message,
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
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(), // Wajib agar bisa ditarik
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_off_outlined,
                size: 80,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum ada notifikasi',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
