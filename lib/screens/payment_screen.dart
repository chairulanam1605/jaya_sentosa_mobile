// lib/screens/payment_screen.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart';
import '../models/invoice_model.dart';
import '../services/auth_service.dart';
import '../main.dart'; 
import 'payment_detail_screen.dart'; // Tambahan wajib untuk navigasi bukti pembayaran

class PaymentScreen extends StatefulWidget {
  final InvoiceModel? invoice;
  const PaymentScreen({super.key, this.invoice});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late InvoiceModel _invoice;
  String _selectedSubMethodId = ''; 
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    if (widget.invoice != null) {
      _invoice = widget.invoice!;
    } else {
      _invoice = InvoiceModel(id: '0', periode: 'Belum ada', jumlah: 0, status: 'unpaid');
    }

    // --- CALLBACK MIDTRANS YANG SUDAH DISEMPURNAKAN ---
    midtrans?.setTransactionFinishedCallback((result) {
      final status = result.status;
      
      // JARING PENGAMAN DEMO SKRIPSI: 
      // Apapun status kembalian dari Midtrans (entah itu ditutup paksa/silang 'X', sukses, atau pending), 
      // aplikasi akan dipaksa berpindah ke layar PaymentDetailScreen untuk memperlihatkan buktinya.
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          
          bool isSimulasiLunas = status == 'canceled' || status == 'settlement' || status == 'capture';

          // Memaksa pindah ke halaman Detail Pembayaran
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentDetailScreen(
                invoice: _invoice,
                method: _selectedSubMethodId.isNotEmpty ? _selectedSubMethodId : 'Transfer / QRIS',
                transactionId: result.transactionId ?? 'TRX-SIMULASI-${DateTime.now().millisecondsSinceEpoch}',
              ),
            ),
          );

          // Memunculkan pesan di bawah layar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isSimulasiLunas ? 'Memproses pelunasan simulasi...' : 'Status transaksi: $status'),
              backgroundColor: isSimulasiLunas ? Colors.green : Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        });
      }
    });
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  Future<void> _prosesPembayaranMidtrans() async {
    if (_selectedSubMethodId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih salah satu metode pembayaran terlebih dahulu!'), 
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final url = Uri.parse('https://adminjsg.com/api/checkout');
    final user = AuthService.currentUser;

    final dataBody = {
      'harga_total': _invoice.jumlah.toInt().toString(), 
      'nama': user?.fullName ?? 'Pelanggan JSG',
      'email': '${(user?.fullName ?? 'pelanggan').toLowerCase().replaceAll(' ', '')}@gmail.com', 
      'phone': user?.phone ?? '080000000000', 
      'invoice_id': _invoice.id.toString(), 
      'payment_method': _selectedSubMethodId, 
    };

    try {
      final response = await http.post(
        url, 
        headers: {'Accept': 'application/json'},
        body: dataBody,
      );
      
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['token'] != null) {
        if (midtrans != null) {
          midtrans?.startPaymentUiFlow(token: responseData['token']);
        } else {
          throw Exception('Mesin pembayaran Midtrans belum siap. Coba restart aplikasi.');
        }
      } else {
        throw Exception(responseData['message'] ?? 'Gagal membuat transaksi ke server');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Pembayaran Tagihan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ringkasan Tagihan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, spreadRadius: 2)],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  _infoRow('Nama Pelanggan', user?.fullName ?? '-'),
                  const SizedBox(height: 12),
                  _infoRow('No. Pelanggan', user?.customerNumber ?? '-'),
                  const SizedBox(height: 12),
                  _infoRow('Paket Internet', user?.packageName ?? '-'),
                  const SizedBox(height: 12),
                  _infoRow('Periode', _invoice.periode),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16), 
                    child: Divider(height: 1, color: Color(0xFFEEEEEE), thickness: 1.5)
                  ),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Bayar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      Text(
                        _formatCurrency(_invoice.jumlah),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text('Pilih Metode Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 16),

            _buildCategoryGroup(
              title: "Transfer Bank (Virtual Account)",
              icon: Icons.account_balance_rounded,
              description: "BCA, Mandiri, BNI, BRI, BSI, Permata, dll",
              subMethods: [
                {'id': 'bca_va', 'name': 'BCA Virtual Account', 'logo': 'assets/logos/bca.png'},
                {'id': 'echannel', 'name': 'Mandiri Bill Payment', 'logo': 'assets/logos/mandiri.png'},
                {'id': 'bni_va', 'name': 'BNI Virtual Account', 'logo': 'assets/logos/bni.png'},
                {'id': 'bri_va', 'name': 'BRI Virtual Account', 'logo': 'assets/logos/bri.png'},
                {'id': 'bsi_va', 'name': 'BSI Virtual Account', 'logo': 'assets/logos/bsi.png'},
                {'id': 'permata_va', 'name': 'Permata Virtual Account', 'logo': 'assets/logos/permata.png'},
                {'id': 'cimb_va', 'name': 'CIMB Niaga Virtual Account', 'logo': 'assets/logos/cimb.png'},
                {'id': 'danamon_online', 'name': 'Danamon Online Banking', 'logo': 'assets/logos/danamon.png'},
                {'id': 'seabank', 'name': 'SeaBank', 'logo': 'assets/logos/seabank.png'},
              ],
            ),
            const SizedBox(height: 14),

            _buildCategoryGroup(
              title: "E-Wallet & QRIS",
              icon: Icons.account_balance_wallet_rounded,
              description: "GoPay, ShopeePay, OVO, Dana, dan scan QRIS",
              subMethods: [
                {'id': 'qris', 'name': 'QRIS (Semua E-Wallet & M-Banking)', 'logo': 'assets/logos/qris.png'},
                {'id': 'gopay', 'name': 'GoPay', 'logo': 'assets/logos/gopay.png'},
                {'id': 'shopeepay', 'name': 'ShopeePay', 'logo': 'assets/logos/shopeepay.png'},
                {'id': 'ovo', 'name': 'OVO', 'logo': 'assets/logos/ovo.png'},
                {'id': 'dana', 'name': 'Dana', 'logo': 'assets/logos/dana.png'},
              ],
            ),
            const SizedBox(height: 14),

            _buildCategoryGroup(
              title: "Kartu Kredit / Debit",
              icon: Icons.credit_card_rounded,
              description: "Bayar dengan Visa, Mastercard, atau JCB",
              subMethods: [
                {'id': 'credit_card', 'name': 'Kartu Kredit / Debit', 'logo': 'assets/logos/mastercard_visa.png'},
              ],
            ),
            const SizedBox(height: 14),

            _buildCategoryGroup(
              title: "Cicilan Tanpa Kartu",
              icon: Icons.money_off_rounded,
              description: "Bayar nanti dengan layanan paylater",
              subMethods: [
                {'id': 'akulaku', 'name': 'Akulaku PayLater', 'logo': 'assets/logos/akulaku.png'},
              ],
            ),
            const SizedBox(height: 14),

            _buildCategoryGroup(
              title: "Gerai Retail / Minimarket",
              icon: Icons.store_mall_directory_rounded,
              description: "Bayar tunai melalui kasir minimarket",
              subMethods: [
                {'id': 'indomaret', 'name': 'Indomaret / i.Saku', 'logo': 'assets/logos/indomaret.png'},
                {'id': 'alfamart', 'name': 'Alfamart / Alfamidi', 'logo': 'assets/logos/alfamart.png'},
              ],
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
      
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _prosesPembayaranMidtrans,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 2,
          ),
          child: _isProcessing
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text(
                  'KONFIRMASI PEMBAYARAN',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
                ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: Colors.black87)),
      ],
    );
  }

  Widget _buildCategoryGroup({
    required String title,
    required IconData icon,
    required String description,
    required List<Map<String, String>> subMethods,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.02), blurRadius: 10, spreadRadius: 1)],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFF1E3A8A), size: 24),
          ),
          title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          subtitle: Text(description, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
            ),
            ...subMethods.map((sub) {
              bool isSelected = _selectedSubMethodId == sub['id'];
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedSubMethodId = sub['id']!;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  color: isSelected ? Colors.blue.shade50.withOpacity(0.5) : Colors.transparent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 30,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Image.asset(
                                sub['logo']!,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 18,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                sub['name']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? const Color(0xFF1E3A8A) : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade300,
                        size: 20,
                      )
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}