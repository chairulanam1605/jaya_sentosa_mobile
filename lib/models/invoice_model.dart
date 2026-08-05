class InvoiceModel {
  final String id;
  final String periode;
  final double jumlah;
  final String status;
  final DateTime? paidDate;

  InvoiceModel({
    required this.id,
    required this.periode,
    required this.jumlah,
    required this.status,
    this.paidDate,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id']?.toString() ?? '0',
      periode: json['periode'] ?? '-',

      jumlah: json['jumlah'] != null
          ? double.parse(json['jumlah'].toString())
          : 0.0,
      status: json['status_pembayaran'] ?? 'unpaid',

      paidDate: json['paid_date'] != null
          ? DateTime.tryParse(json['paid_date'].toString())
          : null,
    );
  }
}
