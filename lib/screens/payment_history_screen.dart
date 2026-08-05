import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jaya_sentosa_mobile/services/api_service.dart';
import 'package:jaya_sentosa_mobile/models/invoice_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'tagihan_screen.dart'; 
import 'profile_menu_screen.dart'; 
import 'payment_detail_screen.dart'; 

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final int _currentIndex = 1; 
  String currentUserId = ""; 

  @override
  void initState() {
    super.initState();
    _loadUserId(); 
  }

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

  Future<void> _launchWhatsApp() async {
    final Uri url = Uri.parse(
        'whatsapp://send?phone=6285165863800&text=Halo%20Admin%20JSG,%20saya%20butuh%20bantuan%20terkait%20layanan%20WiFi.');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka WhatsApp. Pastikan aplikasi terinstal.')),
        );
      }
    }
  }

  String _formatCurrency(double amount) {
    String result = amount.toStringAsFixed(0);
    result = result.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    return 'Rp $result';
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
      
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFF1E3A8A),
        backgroundColor: Colors.white,
        child: currentUserId.isEmpty 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)))
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<List<InvoiceModel>>(
              future: ApiService.fetchPaidInvoices(currentUserId), 
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 100.0),
                      child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
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
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentDetailScreen(invoice: invoice),
                              ),
                            );
                          },
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
                                        'Berhasil', 
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _formatCurrency(invoice.jumlah), 
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
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _launchWhatsApp,
        backgroundColor: const Color(0xFF25D366), 
        elevation: 4,
        shape: const CircleBorder(), 
        child: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 32),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF1E3A8A),
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          elevation: 0,
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const TagihanScreen()),
              );
            } else if (index == 2) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfileMenuScreen()), 
              );
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Tagihan'),
            BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Riwayat'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}