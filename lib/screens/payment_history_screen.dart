import 'package:flutter/material.dart';
import 'package:jaya_sentosa_mobile/services/api_service.dart'; // Sesuaikan path ini
import 'package:jaya_sentosa_mobile/models/invoice_model.dart'; // Sesuaikan path ini
import 'package:url_launcher/url_launcher.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final int _currentIndex = 1; // Index 1 untuk Riwayat
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
        title: const Text('Riwayat Pembayaran', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            child: FutureBuilder<List<InvoiceModel>>(
              future: ApiService.fetchPaidInvoices('1'), // Ganti '1' dengan ID user dinamis
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 100.0),
                      child: CircularProgressIndicator(color: Colors.green),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 100.0),
                      child: Text('Terjadi kesalahan koneksi database: ${snapshot.error}'),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 100.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text('Belum ada riwayat pembayaran', style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    ),
                  );
                }

                final paidInvoices = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: paidInvoices.length,
                  itemBuilder: (context, index) {
                    final invoice = paidInvoices[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Periode ${invoice.periode}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Berhasil', // Bisa ditambah tanggal pembayaran dari API jika ada
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Rp ${invoice.jumlah}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A)),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'LUNAS',
                                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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