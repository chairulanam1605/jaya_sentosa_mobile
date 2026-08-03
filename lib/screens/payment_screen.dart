// lib/screens/payment_screen.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart'; 
import '../models/invoice_model.dart';
import '../services/auth_service.dart';

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

    final url = Uri.parse('https://adminjsg.com/public/api/checkout');
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
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final String snapToken = responseData['token']; 
        
        MidtransSDK? midtrans = await MidtransSDK.init(
          config: MidtransConfig(
            clientKey: 'SB-Mid-client-Z1tHofBtAPP6XoDO', 
            merchantBaseUrl: 'https://adminjsg.com/public/', 
            colorTheme: ColorTheme(
              colorPrimary: const Color(0xFF1E3A8A), 
              colorPrimaryDark: const Color(0xFF1E3A8A),
              colorSecondary: const Color(0xFF1E3A8A),
            ),
          ),
        );

        midtrans.startPaymentUiFlow(token: snapToken);

      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal terhubung ke server: ${response.statusCode}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan jaringan: $e'), backgroundColor: Colors.red),
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
    // 🚀 MENGAMBIL DATA USER UNTUK DITAMPILKAN DI KARTU RINGKASAN
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
            // --- RINGKASAN TAGIHAN (SESUAI DESAIN UI-MU) ---
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

            // --- HEADER METODE PEMBAYARAN ---
            const Text('Pilih Metode Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 16),

            // ========================================================
            // KATEGORI 1: E-WALLET / DIGITAL PAYMENT
            // ========================================================
            _buildCategoryGroup(
              title: "E-Wallet & QRIS",
              icon: Icons.account_balance_wallet_rounded,
              description: "GoPay, ShopeePay, dan scan QRIS",
              subMethods: [
                {'id': 'gopay', 'name': 'GoPay'},
                {'id': 'shopeepay', 'name': 'ShopeePay'},
                {'id': 'other_qris', 'name': 'QRIS (OVO, Dana, LinkAja, dll)'},
              ],
            ),
            const SizedBox(height: 14),

            // ========================================================
            // KATEGORI 2: TRANSFER BANK (VIRTUAL ACCOUNT)
            // ========================================================
            _buildCategoryGroup(
              title: "Transfer Bank",
              icon: Icons.account_balance_rounded,
              description: "Transfer Virtual Account otomatis 24 jam",
              subMethods: [
                {'id': 'bca_va', 'name': 'BCA Virtual Account'},
                {'id': 'echannel', 'name': 'Mandiri Bill Payment'},
                {'id': 'bni_va', 'name': 'BNI Virtual Account'},
                {'id': 'bri_va', 'name': 'BRI Virtual Account'},
                {'id': 'permata_va', 'name': 'Permata Virtual Account'},
                {'id': 'cimb_va', 'name': 'CIMB Niaga Virtual Account'},
                {'id': 'other_va', 'name': 'Bank Lainnya (ATM Bersama/Prima)'},
              ],
            ),
            const SizedBox(height: 14),

            // ========================================================
            // KATEGORI 3: RETAIIL / MINIMARKET
            // ========================================================
            _buildCategoryGroup(
              title: "Gerai Retail / Minimarket",
              icon: Icons.store_mall_directory_rounded,
              description: "Bayar tunai melalui kasir minimarket",
              subMethods: [
                {'id': 'indomaret', 'name': 'Indomaret / i.Saku'},
                {'id': 'alfamart', 'name': 'Alfamart / Alfamidi'},
              ],
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
      
      // --- TOMBOL ACTION ---
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

  // Widget Pembantu Baris Info
  Widget _infoRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: Colors.black87)),
      ],
    );
  }

  // ====================================================================
  // WIDGET KATEGORI UTAMA (EXPANSION TILE CUSTOM)
  // ====================================================================
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
                      Row(
                        children: [
                          Icon(
                            Icons.circle_rounded, 
                            size: 8, 
                            color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade300,
                          ),
                          const SizedBox(width: 14),
                          Text(
                            sub['name']!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? const Color(0xFF1E3A8A) : Colors.black87,
                            ),
                          ),
                        ],
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