import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../app/widgets/ems_widgets.dart';
import '../../announcements/presentation/announcements_cubit.dart';
import '../../announcements/presentation/announcements_page.dart';
import '../../attendance/domain/attendance_record.dart';
import '../../attendance/presentation/attendance_cubit.dart';
import '../../attendance/presentation/attendance_page.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../invoices/domain/invoice.dart';
import '../../invoices/presentation/invoice_detail_page.dart';
import '../../invoices/presentation/invoices_cubit.dart';
import '../../invoices/presentation/invoices_page.dart';
import '../../profile/presentation/profile_page.dart';
import '../../results/presentation/results_cubit.dart';
import '../../results/presentation/results_page.dart';
import 'children_cubit.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    context.read<ChildrenCubit>().load();
    context.read<AnnouncementsCubit>().load();
  }

  void _onChildSelected(int id) {
    context.read<InvoicesCubit>().loadFor(id);
    context.read<AttendanceCubit>().loadFor(id);
    context.read<ResultsCubit>().loadFor(id);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<ChildrenCubit, ChildrenState>(
          listener: (context, state) {
            if (state is ChildrenLoaded && state.selected != null) {
              _onChildSelected(state.selected!.id);
            }
          },
          builder: (context, childrenState) {
            return Column(
              children: [
                // Persistent child-switcher for multi-child accounts
                ChildSelectorBar(),
                Expanded(
                  child: IndexedStack(
                    index: _index,
                    children: [
                      _DashboardPage(
                        childrenState: childrenState,
                        onNavigate: (i) => setState(() => _index = i),
                      ),
                      const InvoicesPage(),
                      const AttendancePage(),
                      const ResultsPage(),
                      const AnnouncementsPage(),
                      const ProfilePage(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _BottomNav(
        index: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom navigation
// ---------------------------------------------------------------------------

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: onTap,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: l.homeWelcome,
        ),
        NavigationDestination(
          icon: const Icon(Icons.receipt_long_outlined),
          selectedIcon: const Icon(Icons.receipt_long),
          label: l.invoicesTitle,
        ),
        NavigationDestination(
          icon: const Icon(Icons.event_available_outlined),
          selectedIcon: const Icon(Icons.event_available),
          label: l.attendanceTitle,
        ),
        NavigationDestination(
          icon: const Icon(Icons.bar_chart_outlined),
          selectedIcon: const Icon(Icons.bar_chart),
          label: l.resultsTitle,
        ),
        NavigationDestination(
          icon: const Icon(Icons.campaign_outlined),
          selectedIcon: const Icon(Icons.campaign),
          label: l.announcementsTitle,
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person),
          label: l.profileTitle,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard page
// ---------------------------------------------------------------------------

class _DashboardPage extends StatelessWidget {
  const _DashboardPage({
    required this.childrenState,
    required this.onNavigate,
  });

  final ChildrenState childrenState;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final auth = context.watch<AuthCubit>().state;
    final greeting = _greeting();

    return CustomScrollView(
      slivers: [
        // Hero app bar
        SliverAppBar(
          expandedHeight: 120,
          collapsedHeight: 60,
          pinned: true,
          backgroundColor: cs.surface,
          scrolledUnderElevation: 1,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                  maxLines: 1,
                ),
                if (auth is AuthAuthenticated && auth.user.name != null)
                  Text(
                    auth.user.name!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: cs.onSurface,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none_outlined),
              tooltip: l.announcementsTitle,
              onPressed: () => onNavigate(4),
            ),
            IconButton(
              icon: const Icon(Icons.person_outline),
              tooltip: l.profileTitle,
              onPressed: () => onNavigate(5),
            ),
          ],
        ),

        // Content
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 8),

              // Metric cards row
              _MetricsSection(onNavigate: onNavigate),
              const SizedBox(height: 24),

              // Recent invoices
              _RecentInvoicesSection(onNavigate: onNavigate),
              const SizedBox(height: 24),

              // Recent attendance
              _RecentAttendanceSection(onNavigate: onNavigate),
            ]),
          ),
        ),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير • Good Morning';
    if (hour < 17) return 'مساء الخير • Good Afternoon';
    return 'مساء النور • Good Evening';
  }
}

// ---------------------------------------------------------------------------
// Metrics row
// ---------------------------------------------------------------------------

class _MetricsSection extends StatelessWidget {
  const _MetricsSection({required this.onNavigate});
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final invoicesState = context.watch<InvoicesCubit>().state;
    final attendanceState = context.watch<AttendanceCubit>().state;

    final unpaidCount = invoicesState is InvoicesLoaded
        ? invoicesState.invoices
            .where((i) => i.paymentState != 'paid' && i.state != 'cancel')
            .length
        : 0;

    final attendancePct = attendanceState is AttendanceLoaded &&
            attendanceState.summary.total > 0
        ? (attendanceState.summary.present * 100 /
                attendanceState.summary.total)
            .toStringAsFixed(0)
        : '—';

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 500 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: [
            MetricCard(
              label: l.invoicesTitle,
              value: unpaidCount == 0 ? '✓' : '$unpaidCount',
              icon: Icons.receipt_long_outlined,
              color: unpaidCount == 0
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFC62828),
              onTap: () => onNavigate(1),
              subtitle: l.invoiceAmountResidual,
            ),
            MetricCard(
              label: l.attendanceTitle,
              value: '$attendancePct%',
              icon: Icons.event_available_outlined,
              color: const Color(0xFF1B6B3A),
              onTap: () => onNavigate(2),
              subtitle: l.attendancePresent,
            ),
            MetricCard(
              label: l.resultsTitle,
              value: _latestGrade(context),
              icon: Icons.bar_chart_outlined,
              color: const Color(0xFF1565C0),
              onTap: () => onNavigate(3),
            ),
            MetricCard(
              label: l.announcementsTitle,
              value: _announcementsCount(context),
              icon: Icons.campaign_outlined,
              color: const Color(0xFFC9A84C),
              onTap: () => onNavigate(4),
            ),
          ],
        );
      },
    );
  }

  String _latestGrade(BuildContext context) {
    final state = context.watch<ResultsCubit>().state;
    if (state is ResultsLoaded && state.results.isNotEmpty) {
      return state.results.first.grade ?? '—';
    }
    return '—';
  }

  String _announcementsCount(BuildContext context) {
    final state = context.watch<AnnouncementsCubit>().state;
    if (state is AnnouncementsLoaded) {
      return '${state.announcements.length}';
    }
    return '—';
  }
}

// ---------------------------------------------------------------------------
// Recent invoices preview
// ---------------------------------------------------------------------------

class _RecentInvoicesSection extends StatelessWidget {
  const _RecentInvoicesSection({required this.onNavigate});
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = context.watch<InvoicesCubit>().state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l.invoicesTitle,
          onSeeAll: () => onNavigate(1),
          seeAllLabel: l.seeAll,
        ),
        const SizedBox(height: 10),
        if (state is InvoicesLoading) ...[
          const SkeletonCard(),
          const SizedBox(height: 8),
          const SkeletonCard(),
        ] else if (state is InvoicesLoaded && state.invoices.isNotEmpty) ...[
          ...state.invoices.take(3).map((inv) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _InvoiceRow(
                  invoice: inv,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => InvoiceDetailPage(invoice: inv),
                    ),
                  ),
                ),
              )),
        ] else ...[
          EmptyState(
            icon: Icons.receipt_long_outlined,
            title: l.invoicesEmpty,
          ),
        ],
      ],
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({required this.invoice, required this.onTap});
  final Invoice invoice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final fmt = NumberFormat.currency(
      symbol: invoice.currency != null ? '${invoice.currency!} ' : '',
      decimalDigits: 2,
    );
    final (label, color, icon) = switch (invoice.paymentState) {
      'paid' => (l.invoiceStatePaid, const Color(0xFF2E7D32), Icons.check_circle_outline),
      _ => switch (invoice.state) {
          'cancel' => (l.invoiceStateCancelled, const Color(0xFF9E9E9E), Icons.cancel_outlined),
          _ => (l.invoiceStatePosted, cs.primary, Icons.schedule_outlined),
        }
    };

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(invoice.name,
                        style: Theme.of(context).textTheme.titleSmall),
                    if (invoice.invoiceDateDue != null)
                      Text(
                        DateFormat.yMMMd(
                                Localizations.localeOf(context).toString())
                            .format(invoice.invoiceDateDue!),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmt.format(invoice.amountTotal),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: cs.onSurface),
                  ),
                  const SizedBox(height: 4),
                  StatusBadge(label: label, color: color, small: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent attendance preview
// ---------------------------------------------------------------------------

class _RecentAttendanceSection extends StatelessWidget {
  const _RecentAttendanceSection({required this.onNavigate});
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = context.watch<AttendanceCubit>().state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l.attendanceTitle,
          onSeeAll: () => onNavigate(2),
          seeAllLabel: l.seeAll,
        ),
        const SizedBox(height: 10),
        if (state is AttendanceLoading) ...[
          const SkeletonCard(),
        ] else if (state is AttendanceLoaded &&
            state.summary.records.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _AttendanceStat(
                        value: state.summary.present,
                        label: l.attendancePresent,
                        color: const Color(0xFF2E7D32),
                      ),
                      _AttendanceStat(
                        value: state.summary.absent,
                        label: l.attendanceAbsent,
                        color: const Color(0xFFC62828),
                      ),
                      _AttendanceStat(
                        value: state.summary.late,
                        label: l.attendanceLate,
                        color: const Color(0xFFF57F17),
                      ),
                      _AttendanceStat(
                        value: state.summary.excused,
                        label: l.attendanceExcused,
                        color: const Color(0xFF1565C0),
                      ),
                    ],
                  ),
                  if (state.summary.total > 0) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        height: 8,
                        child: Row(
                          children: [
                            _Bar(
                              flex: state.summary.present,
                              color: const Color(0xFF2E7D32),
                            ),
                            _Bar(
                              flex: state.summary.absent,
                              color: const Color(0xFFC62828),
                            ),
                            _Bar(
                              flex: state.summary.late,
                              color: const Color(0xFFF57F17),
                            ),
                            _Bar(
                              flex: state.summary.excused,
                              color: const Color(0xFF1565C0),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${state.summary.total} ${l.attendanceTitle}',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ] else ...[
          EmptyState(
            icon: Icons.event_available_outlined,
            title: l.attendanceEmpty,
          ),
        ],
      ],
    );
  }
}

class _AttendanceStat extends StatelessWidget {
  const _AttendanceStat({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.flex, required this.color});
  final int flex;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (flex == 0) return const SizedBox.shrink();
    return Expanded(
      flex: flex,
      child: Container(color: color),
    );
  }
}
