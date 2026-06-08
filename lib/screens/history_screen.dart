import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Data dummy riwayat pembayaran (sudah lunas)
    final List<Map<String, dynamic>> paidInvoices = [
      {
        'period': 'Desember 2025',
        'amount': 150000,
        'paidDate': DateTime(2025, 12, 5),
        'status': 'paid',
      },
      {
        'period': 'November 2025',
        'amount': 150000,
        'paidDate': DateTime(2025, 11, 2),
        'status': 'paid',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Riwayat Pembayaran', style: TextStyle(fontSize: 24)),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: paidInvoices.length,
        itemBuilder: (context, index) {
          final inv = paidInvoices[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.payment, size: 40, color: Colors.green),
              title: Text('Periode: ${inv['period']}', style: const TextStyle(fontSize: 20)),
              subtitle: Text('Lunas pada: ${_formatDate(inv['paidDate'])}', style: const TextStyle(fontSize: 16)),
              trailing: Text('Rp ${inv['amount']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}