import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../children/presentation/children_cubit.dart';
import '../domain/invoice.dart';
import 'invoices_cubit.dart';

class InvoicesPage extends StatelessWidget {
  const InvoicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final children = context.watch<ChildrenCubit>().state;
    final selectedId = (children is ChildrenLoaded) ? children.selected?.id : null;

    return Scaffold(
      appBar: AppBar(title: Text(l.invoicesTitle)),
      body: selectedId == null
          ? Center(child: Text(l.invoicesEmpty))
          : BlocBuilder<InvoicesCubit, InvoicesState>(
              builder: (context, state) {
                if (state is InvoicesLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is InvoicesError) {
                  return Center(child: Text(state.message));
                }
                if (state is InvoicesLoaded) {
                  if (state.invoices.isEmpty) {
                    return Center(child: Text(l.invoicesEmpty));
                  }
                  return RefreshIndicator(
                    onRefresh: () => context.read<InvoicesCubit>().loadFor(selectedId),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (_, i) => _InvoiceCard(state.invoices[i]),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: state.invoices.length,
                    ),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard(this.inv);
  final Invoice inv;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final fmt = NumberFormat.currency(
      symbol: inv.currency != null ? '${inv.currency!} ' : '',
      decimalDigits: 2,
    );
    final stateLabel = switch (inv.paymentState) {
      'paid' => l.invoiceStatePaid,
      _ => switch (inv.state) {
          'cancel' => l.invoiceStateCancelled,
          _ => l.invoiceStatePosted,
        }
    };
    final color = switch (inv.paymentState) {
      'paid' => Colors.green,
      _ => switch (inv.state) {
          'cancel' => cs.onSurface.withOpacity(.5),
          _ => cs.primary,
        }
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(inv.name, style: Theme.of(context).textTheme.titleMedium),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(stateLabel,
                      style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _row(context, l.invoiceAmountTotal, fmt.format(inv.amountTotal)),
            _row(context, l.invoiceAmountResidual, fmt.format(inv.amountResidual)),
            if (inv.invoiceDateDue != null)
              _row(context, '↘',
                  DateFormat.yMMMd(Localizations.localeOf(context).toString())
                      .format(inv.invoiceDateDue!)),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}
