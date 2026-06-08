import 'package:flutter/material.dart';
import 'package:jaya_sentosa_mobile/services/api_service.dart'; // Sesuaikan path ini
import 'package:jaya_sentosa_mobile/models/invoice_model.dart'; // Sesuaikan path ini
// Import screen lain untuk navigasi bottom bar dan notifikasi
// import 'payment_history_screen.dart';
// import 'profile_menu_screen.dart';
// import 'notification_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class TagihanScreen extends StatefulWidget {
  const TagihanScreen({super.key});

  @override
  State<TagihanScreen> createState() => _TagihanScreenState();
}

class _TagihanScreenState extends State<TagihanScreen> {
  final int _currentIndex = 0;
  final ScrollController _scrollController = ScrollController();
  bool _isHelpExpanded = false;
  bool _isHelpHidden = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels > 10) {
        if (!_isHelpHidden) setState(() => _isHelpHidden = true);
        if (_isHelpExpanded) setState(() => _isHelpExpanded = false);
      } else {
        if (_isHelpHidden) setState(() => _isHelpHidden = false);
      }
    });
  }

  Future<void> _launchWhatsApp() async {
    final Uri url = Uri.parse(
        'whatsapp://send?phone=6285165863800&text=Halo%20Admin%20JSG,%20saya%20butuh%20bantuan%20terkait%20layanan%20WiFi.');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka WhatsApp. Pastikan aplikasi terinstal.')),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text('Tagihan WiFi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () {
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()));
                },
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            ],
          )
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            child: FutureBuilder<List<InvoiceModel>>(
              future: ApiService.fetchUnpaidInvoices('1'), // Ganti '1' dengan ID user dinamis nantinya
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 50.0),
                      child: CircularProgressIndicator(color: Colors.green),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 50.0),
                      child: Text('Gagal memuat data: ${snapshot.error}'),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 50.0),
                      child: Text('Hore! Semua tagihan bulan ini sudah lunas.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ),
                  );
                }

                final invoices = snapshot.data!;
                return Column(
                  children: invoices.map((invoice) {
                    return Card(
                      elevation: 4,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Periode ${invoice.periode}', // Mengambil data dari API
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            const Divider(height: 24, thickness: 1),
                            const Text('Total Tagihan', style: TextStyle(fontSize: 14, color: Colors.grey)),
                            const SizedBox(height: 8),
                            Text(
                              'Rp ${invoice.jumlah}', // Mengambil data dari API
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E3A8A),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  // Aksi bayar tagihan
                                },
                                child: const Text('BAYAR TAGIHAN SEKARANG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          // Floating Button Bantuan
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: 24,
            right: _isHelpHidden ? -100 : (_isHelpExpanded ? 16 : -80),
            child: GestureDetector(
              onTap: () {
                if (_isHelpExpanded) {
                  _launchWhatsApp();
                } else {
                  setState(() => _isHelpExpanded = true);
                  Future.delayed(const Duration(seconds: 4), () {
                    if (mounted && _isHelpExpanded) setState(() => _isHelpExpanded = false);
                  });
                }
              },
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.help_outline_rounded, color: Colors.white, size: 28),
                    if (_isHelpExpanded) ...[
                      const SizedBox(width: 8),
                      const Text('Bantuan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF1E3A8A),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          // Logika perpindahan halaman dengan pushReplacement
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Tagihan'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}