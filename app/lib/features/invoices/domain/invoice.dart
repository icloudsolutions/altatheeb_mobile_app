import 'package:equatable/equatable.dart';

class Invoice extends Equatable {
  const Invoice({
    required this.id,
    required this.name,
    required this.state,
    this.paymentState,
    this.amountTotal = 0,
    this.amountResidual = 0,
    this.currency,
    this.invoiceDate,
    this.invoiceDateDue,
    this.studentOdooId,
  });

  final int id;
  final String name;
  final String state;
  final String? paymentState;
  final double amountTotal;
  final double amountResidual;
  final String? currency;
  final DateTime? invoiceDate;
  final DateTime? invoiceDateDue;
  final int? studentOdooId;

  factory Invoice.fromJson(Map<String, dynamic> j) => Invoice(
        id: j['id'] as int,
        name: (j['name'] ?? '') as String,
        state: (j['state'] ?? 'draft') as String,
        paymentState: j['payment_state'] as String?,
        amountTotal: ((j['amount_total'] as num?) ?? 0).toDouble(),
        amountResidual: ((j['amount_residual'] as num?) ?? 0).toDouble(),
        currency: j['currency'] as String?,
        invoiceDate: _date(j['invoice_date']),
        invoiceDateDue: _date(j['invoice_date_due']),
        studentOdooId: j['student_odoo_id'] as int?,
      );

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v as String);
  }

  @override
  List<Object?> get props => [
        id, name, state, paymentState, amountTotal, amountResidual,
        currency, invoiceDate, invoiceDateDue, studentOdooId,
      ];
}
