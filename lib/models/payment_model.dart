class PaymentModel {
  final String transactionId;
  final String invoiceId;
  final double amount;
  final DateTime paymentDate;
  final String method; // "Transfer Bank", "QRIS", "Minimarket"
  final String status;

  PaymentModel({
    required this.transactionId,
    required this.invoiceId,
    required this.amount,
    required this.paymentDate,
    required this.method,
    required this.status,
  });

  // Dummy payment untuk invoice yang sudah lunas
  static PaymentModel? getPaymentByInvoiceId(String invoiceId) {
    if (invoiceId == 'INV002') {
      return PaymentModel(
        transactionId: 'TRX-20251128-0042',
        invoiceId: invoiceId,
        amount: 350000,
        paymentDate: DateTime(2025, 11, 28),
        method: 'Transfer Bank (BCA)',
        status: 'success',
      );
    } else if (invoiceId == 'INV003') {
      return PaymentModel(
        transactionId: 'TRX-20251025-0012',
        invoiceId: invoiceId,
        amount: 350000,
        paymentDate: DateTime(2025, 10, 25),
        method: 'QRIS',
        status: 'success',
      );
    }
    return null;
  }
}