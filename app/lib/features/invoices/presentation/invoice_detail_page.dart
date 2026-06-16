import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../domain/invoice.dart';

class InvoiceDetailPage extends StatelessWidget {
  const InvoiceDetailPage({super.key, required this.invoice});
  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final fmt = NumberFormat.currency(
      symbol: invoice.currency != null ? '${invoice.currency!} ' : '',
      decimalDigits: 2,
    );
    final (stateLabel, stateColor) = switch (invoice.paymentState) {
      'paid' => (l.invoiceStatePaid, Colors.green),
      _ => switch (invoice.state) {
          'cancel' => (l.invoiceStateCancelled, cs.onSurface.withValues(alpha: .5)),
          _ => (l.invoiceStatePosted, cs.primary),
        }
    };
    final localeName = Localizations.localeOf(context).toString();

    return Scaffold(
      appBar: AppBar(title: Text(invoice.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: stateColor.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(stateLabel,
                  style: TextStyle(
                      color: stateColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
          ),
          const SizedBox(height: 24),

          // Amount summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _BigAmount(
                    label: l.invoiceAmountTotal,
                    value: fmt.format(invoice.amountTotal),
                    color: cs.onSurface,
                  ),
                  const Divider(height: 24),
                  _BigAmount(
                    label: l.invoiceAmountResidual,
                    value: fmt.format(invoice.amountResidual),
                    color: invoice.amountResidual > 0 ? cs.error : Colors.green,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Dates
          Card(
            child: Column(
              children: [
                if (invoice.invoiceDate != null)
                  ListTile(
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: Text(l.invoiceDateLabel),
                    trailing: Text(DateFormat.yMMMd(localeName)
                        .format(invoice.invoiceDate!)),
                  ),
                if (invoice.invoiceDateDue != null) ...[
                  const Divider(indent: 16, endIndent: 16, height: 0),
                  ListTile(
                    leading: Icon(
                      Icons.event_outlined,
                      color: invoice.amountResidual > 0 &&
                              invoice.invoiceDateDue!.isBefore(DateTime.now())
                          ? cs.error
                          : null,
                    ),
                    title: Text(l.invoiceDueDateLabel),
                    trailing: Text(
                      DateFormat.yMMMd(localeName).format(invoice.invoiceDateDue!),
                      style: TextStyle(
                        color: invoice.amountResidual > 0 &&
                                invoice.invoiceDateDue!.isBefore(DateTime.now())
                            ? cs.error
                            : null,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BigAmount extends StatelessWidget {
  const _BigAmount(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
