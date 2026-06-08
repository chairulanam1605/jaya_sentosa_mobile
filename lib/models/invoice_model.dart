class InvoiceModel {
  final String id;
  final String periode; // Diseragamkan menjadi bahasa Indonesia
  final double jumlah;  // Diseragamkan menjadi bahasa Indonesia
  final String status;
  final DateTime? paidDate;

  InvoiceModel({
    required this.id,
    required this.periode,
    required this.jumlah,
    required this.status,
    this.paidDate,
  });

  // Fungsi untuk menerima data dari API Laravel
  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id']?.toString() ?? '0',
      periode: json['periode'] ?? '-',
      // Memastikan konversi nominal uang aman
      jumlah: json['jumlah'] != null ? double.parse(json['jumlah'].toString()) : 0.0,
      status: json['status_pembayaran'] ?? 'unpaid',
      // Mengambil tanggal bayar jika sudah lunas
      paidDate: json['paid_date'] != null ? DateTime.tryParse(json['paid_date'].toString()) : null,
    );
  }
}