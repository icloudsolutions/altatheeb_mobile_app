import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../app/widgets/ems_widgets.dart';
import '../../children/presentation/children_cubit.dart';
import '../domain/invoice.dart';
import 'invoice_detail_page.dart';
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
          ? EmptyState(
              icon: Icons.receipt_long_outlined,
              title: l.invoicesEmpty,
            )
          : BlocBuilder<InvoicesCubit, InvoicesState>(
              builder: (context, state) {
                if (state is InvoicesLoading) {
                  return const SkeletonList(count: 4);
                }
                if (state is InvoicesError) {
                  return ErrorState(
                    message: state.message,
                    onRetry: () =>
                        context.read<InvoicesCubit>().loadFor(selectedId),
                    retryLabel: l.retry,
                  );
                }
                if (state is InvoicesLoaded) {
                  if (state.invoices.isEmpty) {
                    return EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: l.invoicesEmpty,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () =>
                        context.read<InvoicesCubit>().loadFor(selectedId),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemBuilder: (_, i) => _InvoiceCard(
                        state.invoices[i],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                InvoiceDetailPage(invoice: state.invoices[i]),
                          ),
                        ),
                      ),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: state.invoices.length,
                    ),
                  );
                }
                return const SkeletonList();
              },
            ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard(this.inv, {this.onTap});
  final Invoice inv;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final fmt = NumberFormat.currency(
      symbol: inv.currency != null ? '${inv.currency!} ' : '',
      decimalDigits: 2,
    );
    final (stateLabel, color, icon) = switch (inv.paymentState) {
      'paid' => (
          l.invoiceStatePaid,
          const Color(0xFF2E7D32),
          Icons.check_circle_outline
        ),
      _ => switch (inv.state) {
          'cancel' => (
              l.invoiceStateCancelled,
              const Color(0xFF9E9E9E),
              Icons.cancel_outlined
            ),
          _ => (l.invoiceStatePosted, cs.primary, Icons.schedule_outlined),
        }
    };

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(inv.name,
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      fmt.format(inv.amountTotal),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                    if (inv.invoiceDateDue != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.event_outlined,
                              size: 12,
                              color: cs.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Text(
                            DateFormat.yMMMd(
                                    Localizations.localeOf(context).toString())
                                .format(inv.invoiceDateDue!),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StatusBadge(label: stateLabel, color: color, small: true),
                  if (inv.amountResidual > 0 && inv.paymentState != 'paid') ...[
                    const SizedBox(height: 6),
                    Text(
                      fmt.format(inv.amountResidual),
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: cs.error),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right,
                  size: 18, color: cs.onSurface.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}
