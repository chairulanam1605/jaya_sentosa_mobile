import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import '../models/payment_model.dart';
import '../services/auth_service.dart';

class PaymentDetailScreen extends StatefulWidget {
  final InvoiceModel invoice;
  final String? method;
  final String? transactionId;

  const PaymentDetailScreen({
    super.key,
    required this.invoice,
    this.method,
    this.transactionId,
  });

  factory PaymentDetailScreen.fromInvoice({required InvoiceModel invoice}) {
    final payment = PaymentModel.getPaymentByInvoiceId(invoice.id);
    return PaymentDetailScreen(
      invoice: invoice,
      method: payment?.method,
      transactionId: payment?.transactionId,
    );
  }

  @override
  State<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends State<PaymentDetailScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser!;
    final isSuccess = widget.invoice.status == 'paid' || (widget.method != null && widget.transactionId != null);
    final displayMethod = widget.method ?? (isSuccess ? 'Transfer Bank' : 'Belum dibayar');
    final displayTransactionId = widget.transactionId ?? 'TRX-${widget.invoice.id}-${widget.invoice.paidDate?.millisecondsSinceEpoch}';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          isSuccess ? 'Bukti Pembayaran' : 'Detail Tagihan',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
          child: Column(
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSuccess ? Colors.green.shade50 : Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_circle_rounded : Icons.pending_rounded,
                    size: 100,
                    color: isSuccess ? Colors.green : Colors.orange,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              Text(
                isSuccess ? 'Pembayaran Berhasil' : 'Menunggu Pembayaran',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isSuccess ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSuccess 
                  ? 'Tagihan untuk periode ${widget.invoice.periode}\ntelah lunas dibayarkan.' 
                  : 'Silakan selesaikan pembayaran Anda.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 40),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.receipt_long_rounded, color: Color(0xFF1E3A8A), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Rincian Transaksi',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _detailRow('ID Transaksi', displayTransactionId),
                          _detailRow('Tanggal', widget.invoice.paidDate != null ? _formatDate(widget.invoice.paidDate!) : (isSuccess ? _formatDate(DateTime.now()) : '-')),
                          _detailRow('Nama Pelanggan', user.fullName),
                          _detailRow('Layanan', user.packageName),
                          _detailRow('Metode', displayMethod),
                        ],
                      ),
                    ),
                    
                    Row(
                      children: List.generate(30, (index) => Expanded(
                        child: Container(
                          color: index % 2 == 0 ? Colors.transparent : Colors.grey.withOpacity(0.3),
                          height: 2,
                        ),
                      )),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Bayar',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54),
                          ),
                          Text(
                            _formatCurrency(widget.invoice.jumlah),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 4,
                    shadowColor: const Color(0xFF1E3A8A).withOpacity(0.4),
                  ),
                  child: const Text(
                    'KEMBALI KE BERANDA',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: Radius.zero.x == 0 ? TextAlign.right : null,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    String result = amount.toStringAsFixed(0);
    result = result.replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    return 'Rp $result';
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return months[month - 1];
  }
}